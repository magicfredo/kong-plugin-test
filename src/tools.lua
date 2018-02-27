local Object = require "kong.vendor.classic"
local Tools = Object:extend()

function Tools:new(api_name)
    self._api_name = api_name
end

function Tools:get_api_name()
    return self._api_name
end

return Tools
