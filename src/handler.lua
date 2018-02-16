local access = require "kong.plugins.ankama.access"
local BasePlugin = require "kong.plugins.base_plugin"

local AnkamaHandler = BasePlugin:extend()
AnkamaHandler.PRIORITY = 619

function AnkamaHandler:new()
    AnkamaHandler.super.new(self, "ankama")
end

function AnkamaHandler:access(conf)
    AnkamaHandler.super.access(self)
    access.execute(conf)
end

return AnkamaHandler
