package = "kong-plugin-ankama"
version = "0.1-1"
supported_platforms = {"linux", "macosx"}
source = {
  url = "git://github.com/magicfredo/kong-plugin-test",
  tag = "v0.1-1"
}
description = {
  summary = "Ankama - Kong plugin",
  license = "Apache 2.0",
  homepage = "https://github.com/magicfredo/kong-plugin-test",
  detailed = [[
      Ankama - Kong plugin
  ]],
}
dependencies = {
  "lua ~> 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.ankama.access"] = "src/access.lua",
    ["kong.plugins.ankama.handler"] = "src/handler.lua",
    ["kong.plugins.ankama.schema"] = "src/schema.lua",
    ["kong.plugins.ankama.tools"] = "src/tools.lua"
  }
}