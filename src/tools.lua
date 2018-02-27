object_classic = require "classic"

local tools = object_classic:extend()

function tools:new(api_name)
    self._api_name = api_name
end

function tools:get_api_name()
    return self._api_name
end

return tools
