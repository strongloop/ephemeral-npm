local _Utils = {}

local SECONDS = {
  s = 1,
  m = 60,
  h = 60 * 60,
  d = 24 * 60 * 60,
  w = 7 * 24 * 60 * 60,
  M = 30 * 24 * 60 * 60,
  y = 365 * 24 * 60 * 60,
}

function _Utils.parseDuration(str)
    local total = 0
    for n,scale in string.gmatch(str, "(%d+)([smhdwMy])") do
        total = total + n * SECONDS[scale]
    end
    return total
end

assert(_Utils.parseDuration('5m') == 300)
assert(_Utils.parseDuration('10m') == 600)
assert(_Utils.parseDuration('1h') == 60 * 60)
assert(_Utils.parseDuration('1h1m') == 61 * 60)

return _Utils
