local cjson = require "cjson.safe"
local http = require "resty.http"
local utils = require "ephemeral-utils"

local _M = {}

function _M.init()
    local npmConfig = ngx.shared.npmConfig
    _M.registry = os.getenv("npm_config_registry"):gsub("/+$", "")
    _M.hostPattern = _M.registry:gsub("%.", "%%."):gsub("%-", "%%-")
    _M.MAXAGE = utils.parseDuration(os.getenv("MAXAGE") or "5m")
    -- escape . and - which have special meaning in Lua patterns
    npmConfig:set('npm_config_registry', _M.registry)
    npmConfig:set('npm_upstream_pattern', _M.hostPattern)
    npmConfig:set('MAXAGE', _M.MAXAGE)
end

function _M.prefetchTaggedTarballs(premature, selfHost, pkg)
    if premature then
        return
    end
    local distTags = pkg['dist-tags'] or {}
    local versions = pkg.versions or {}
    local reqs = {}

    for k, v in pairs(distTags) do
        local tv = versions[v] or {}
        if tv.dist then
            local __scheme, __host, __port, path, query = unpack(http.parse_uri({}, tv.dist.tarball))
            table.insert(reqs, {
                path = path,
                method = 'GET',
                headers = {
                    ["Host"] = selfHost,
                },
            })
        end
    end
    if #reqs > 0 then
        local httpc = http.new()
        httpc:connect('127.0.0.1', 4873)
        local responses, err = httpc:request_pipeline(reqs)
        for i,r in ipairs(responses) do
            if r.status then
                r:read_body() -- to oblivion!
            end
        end
        httpc:close()
    end
end

function _M.prefetchRelatedPackages(premature, selfHost, pkg)
    if premature then
        return
    end
    local meta = ngx.shared.npmMeta
    local distTags = pkg['dist-tags'] or {}
    local versions = pkg.versions or {}
    local latestVersion = distTags.latest
    local latest = versions[latestVersion] or {}
    local deps = latest.dependencies or {}
    local reqs = {}
    -- find any deps that we haven't already seen and queue them for fetching
    for k, v in pairs(deps) do
        if meta:get('/' .. k) == nil then
            table.insert(reqs, {
                path = '/' .. k,
                method = 'GET',
                headers = {
                    ["Host"] = selfHost,
                },
            })
        end
    end
    -- If we
    if #reqs > 0 then
        local httpc = http.new()
        httpc:connect('127.0.0.1', 4873)
        local responses, err = httpc:request_pipeline(reqs)
        for i,r in ipairs(responses) do
            if r.status then
                r:read_body() -- to oblivion!
            end
        end
        httpc:close()
    end
end

function _M.getPackage()
    local uri = ngx.var.uri
    local meta = ngx.shared.npmMeta
    local cbody = meta:get(uri)
    local base = ngx.var.scheme .. '://' .. ngx.var.http_host
    -- yep, our own shared memory cache implementation :-/
    if cbody == nil then
        ngx.var.ephemeralCacheStatus = 'pkg-MISS'
        local res = ngx.location.capture('/-@-' .. uri,
                                        { copy_all_vars = true })
        cbody = {body = res.body, etag = res.header['ETag']}
        local pkgJSON = cjson.decode(cbody.body)
        if pkgJSON == nil then
            -- somehow the metadata isn't valid JSON.. let's tell
            -- the client to try again and hope it works out better
            -- next time
            ngx.sleep(2)
            return ngx.redirect(uri, ngx.HTTP_MOVED_TEMPORARILY)
        end
        meta:set(uri, cbody, _M.MAXAGE)
        -- Pre-emptively cache some tarballs associated with the package.
        -- We don't know what version they're actually going to be installing,
        -- so we'll just take some educated guesses.
        -- These files never change over time so they'll end up cached for a while.
        ngx.timer.at(0, _M.prefetchTaggedTarballs, ngx.var.http_host, pkgJSON)
        -- Pre-emptively fetch the package metadata for every dependency. These will
        -- only stay cached for a little while but they'll potentially greatly reduce
        -- latency for the client because there's a 99% chance they'll be asking for them
        -- as soon as they recieve the current response and parse it.
        ngx.timer.at(0, _M.prefetchRelatedPackages, ngx.var.http_host, pkgJSON)
    else
        ngx.var.ephemeralCacheStatus = 'pkg-HIT'
    end
    -- We rewrite the URLs AFTER caching so that we can be accessed by
    -- any hostname that is pointed at us.
    local body = string.gsub(cbody.body, _M.hostPattern, base)
    if cbody.etag ~= nil then
        ngx.header["ETag"] = cbody.etag
    end
    ngx.header["Content-Length"] = #body
    ngx.print(body)
    ngx.eof()
end

return _M
