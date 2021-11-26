package.path = "./libraries/?.lua;./libraries/?/init.lua;"..package.path

--load discordia
discordia = require("discordia")
client = discordia.Client()

--activate the import system
local import = require("import")(require)

--create server
local server = import("classes.server-handler")
client:on("ready",function()
  print("starting test")
  local new_server = server(client,client:getGuild("640251445949759499"),{
    autosave_frequency = 5,
    default_plugins = {
        "meta",
        "help",
        "plugins",
        "esolang",
        "tools",
        "reactions"
    }
  })
end)

--load token
local tempfile = io.open("./token","r")
if not tempfile then
  error("./token file does not exist")
end
local nstr = tempfile:read("*l")
tempfile:close()
client:run('Bot '..nstr)
