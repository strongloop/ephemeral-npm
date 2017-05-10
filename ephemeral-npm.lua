local cjson = require "cjson.safe"

local _M = {}

function _M.init()
    local npmConfig = ngx.shared.npmConfig
    local registry = os.getenv("npm_config_registry"):gsub("/+$", "")
    local pattern = registry:gsub("%.", "%%."):gsub("%-", "%%-")
    -- escape . and - which have special meaning in Lua patterns
    npmConfig:set('npm_config_registry', registry)
    npmConfig:set('npm_upstream_pattern', pattern)
end

function _M.getPackage()
    local uri = ngx.var.uri
    local meta = ngx.shared.npmMeta
    local body = meta:get(uri)
    -- yep, our own shared memory cache implementation :-/
    if body == nil then
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
        meta:set(uri, body)
    end
    ngx.header["Content-Length"] = #body
    ngx.print(body)
end

function _M.filterPackageBody()
    local npmConfig = ngx.shared.npmConfig
    local upstream = npmConfig:get('npm_upstream_pattern')
    -- need to construct URL because we may be proxying http<->https
    local base = ngx.var.scheme .. '://' .. ngx.var.http_host
    -- ngx.log(ngx.ERR, "Modifying JSON of " .. ngx.var.uri .. " to replace '" .. upstream .. "' with '" .. base .. "'")
    ngx.arg[1] = string.gsub(ngx.arg[1], upstream, base)
end

return _M
