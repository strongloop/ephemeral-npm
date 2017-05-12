local cjson = require "cjson.safe"
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
            return ngx.redirect(uri, ngx.HTTP_MOVED_TEMPORARILY)
        end
        meta:set(uri, body, _M.MAXAGE)
    else
        ngx.var.ephemeralCacheStatus = 'HIT'
    end
    body = string.gsub(body, _M.hostPattern, base)
    ngx.header["Content-Length"] = #body
    ngx.print(body)
    ngx.eof()
end

return _M
