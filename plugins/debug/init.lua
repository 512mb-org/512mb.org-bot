local plugin = import("classes.plugin")("debug")
local command = import("classes.command")
local save = command("save",{
    help = "Force-save config data",
    exec = function()
        server:save_config()
    end
})
plugin:add_command(save)
local err = command("error",{
    help = "Force error",
    exec = function()
        error("Errored successfully!")
    end
})
plugin:add_command(err)
local perm_error = command("permerror",{
    help = "Force permission error",
    users = {
        ["245973168257368076"] = -1
    },
    exec = function(msg)
        msg:reply([[o no he's hot]])
    end
})
plugin:add_command(perm_error)
local return_error = command("return_error",{
    help = "Force a return value error",
    exec = function(msg)
        msg:reply("nono :)")
        return false
    end
})
plugin:add_command(return_error)
return plugin
