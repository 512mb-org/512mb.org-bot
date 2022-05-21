local plugin_c = import("classes.plugin")
local command = import("classes.command")
local plugin = plugin_c("pluginmanager")
local utilities = require("table-utils")

local generic_admin_template = {
    args = {"string"},
    perms = {
        "administrator"
    },
}

local enable = command("enable",utilities.overwrite(generic_admin_template,{
    category = "Utilities",
    exec = function(msg,args,opts)
        local status,message = plugin_handler:load(args[1])
        local plugin_data = command_handler:get_metadata().plugins
        local embed = {
            description = message,
            color = discordia.Color.fromHex("ff5100").value,
        }
        if status then
            embed.fields = {
                {name = "New commands:",value =
                    table.concat(plugin_data[args[1]] or {},", ").." "
                }
            }
        end
        msg:reply({embed = embed})
    end
}))
plugin:add_command(enable)
local disable = command("disable",utilities.overwrite(generic_admin_template,{
    category = "Utilities",
    exec = function(msg,args,opts)
        local plugin_data = command_handler:get_metadata().plugins
        if not (args[1] == "plugins") then
            local status,message = plugin_handler:unload(args[1])
            local embed = {
                description = message,
                color = discordia.Color.fromHex("ff5100").value,
            }
            if status then
                embed.fields = {
                    {name = "Removed commands:",value =
                        table.concat(plugin_data[args[1]] or {},", ").." "
                    }
                }
            end
            msg:reply({embed = embed})
        else
            msg:reply("TIME PARADOX")
        end
    end
}))
plugin:add_command(disable)
local plugins = command("plugins",utilities.overwrite(generic_admin_template,{
        category = "Utilities",
        args = {},
        exec = function(msg,args,opts)
            local all_plugins = plugin_handler:list_loadable()
            local unloaded_plugins = {}
            local loaded_plugins = {}
            for k,v in pairs(all_plugins) do
                if not v.loaded then
                    table.insert(unloaded_plugins,k)
                else 
                    table.insert(loaded_plugins,k)
                end
            end
            if #unloaded_plugins == 0 then
                table.insert(unloaded_plugins," ")
            end
            msg:reply({embed={
                color = discordia.Color.fromHex("ff5100").value,
                fields = {
                    {name = "Loaded plugins",value = "``"..table.concat(loaded_plugins,"``,\n``").."``"},
                    {name = "Unloaded plugins",value = "``"..table.concat(unloaded_plugins,"``,\n``").."``"}
                }
            }})
        end
}))
plugin:add_command(plugins)
plugin:load_helpdb(plugin_path.."help.lua")
return plugin

