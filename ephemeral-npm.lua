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

function _M.prefetchRelatedPackages(premature, selfHost, pkg)
    local httpc = http.new()
    local meta = ngx.shared.npmMeta
    httpc:connect('127.0.0.1', 4873)
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
    -- extract all the tarball URLs and fetch them to force them to be cached
    for v,p in pairs(versions) do
        local scheme, host, port, path, query = unpack(httpc:parse_uri(p.dist.tarball))
        table.insert(reqs, {
            path = path,
            method = 'GET',
        })
    end
    local responses, err = httpc:request_pipeline(reqs)
    for i,r in ipairs(responses) do
        if r.status then
            r:read_body() -- to oblivion!
        end
    end
    httpc:close()
end

function _M.getPackage()
    local uri = ngx.var.uri
    local meta = ngx.shared.npmMeta
    local body = meta:get(uri)
    local base = ngx.var.scheme .. '://' .. ngx.var.http_host
    -- yep, our own shared memory cache implementation :-/
    if body == nil then
        ngx.var.ephemeralCacheStatus = 'MISS'
        local res = ngx.location.capture('/-@-' .. uri,
                                        { copy_all_vars = true })
        body = res.body
        local pkgJSON = cjson.decode(body)
        if pkgJSON == nil then
            -- somehow the metadata isn't valid JSON.. let's tell
            -- the client to try again and hope it works out better
            -- next time
            ngx.sleep(2)
            return ngx.redirect(uri, ngx.HTTP_MOVED_TEMPORARILY)
        end
        meta:set(uri, body, _M.MAXAGE)
        -- We rewrite the URLs AFTER caching so that we can be accessed by
        -- any hostname that is pointed at us.
        body = string.gsub(body, _M.hostPattern, base)
        ngx.timer.at(0.1, _M.prefetchRelatedPackages, ngx.var.http_host, pkgJSON)
    else
        body = string.gsub(body, _M.hostPattern, base)
        ngx.var.ephemeralCacheStatus = 'HIT'
    end
    ngx.header["Content-Length"] = #body
    ngx.print(body)
    ngx.eof()
end

return _M
