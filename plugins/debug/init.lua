local plugin = import("classes.plugin")("debug")
local command = import("classes.command")
local save = command("save",{
    help = "Force-save config data",
    exec = function()
        server:save_config()
    end
})
plugin:add_command(save)
return plugin
