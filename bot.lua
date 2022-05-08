package.path = "./libraries/?.lua;./libraries/?/init.lua;"..package.path
package.cpath = "./libraries/?.so;"..package.cpath

--load discordia
discordia = require("discordia")
client = discordia.Client()

--activate the import system
local import = require("import")(require)

local server_ids = {
    "640251445949759499"
}
local servers = {}

--create server
local server = import("classes.server-handler")
client:on("ready",function()
  print("starting test")
  for _,id in pairs(server_ids) do
    if not servers[id] then
        servers[id] = server(client,client:getGuild(id),{
            path = os.getenv("HOME").."/bot-savedata/"..id.."/",
            autosave_frequency = 20,
            default_plugins = {
                "meta",
                "help",
                "plugins",
                "esolang",
                "tools",
                "reactions",
                "roledefaults",
                "security",
                "cron"
            }
        })
    end
  end
end)


--load token
local tempfile = io.open("./token","r")
if not tempfile then
  error("./token file does not exist")
end
local nstr = tempfile:read("*l")
tempfile:close()
client:run('Bot '..nstr)
