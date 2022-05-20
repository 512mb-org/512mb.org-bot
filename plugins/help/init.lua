local pluginc = import("classes.plugin")
local command = import("classes.command")
local plugin = pluginc("help")
local color = discordia.Color.fromHex

local help_command = command("help",{
    exec = function(msg,args,opts)
        local embed = {
            color = color("32b3bc").value
        }
        if args[1] then
            if not opts["plugin"] then
                if command_handler:get_command(args[1]) then
                    local command = command_handler:get_command(args[1])
                    embed = command:get_help().embed
                else
                    embed.description = "No such command: "..args[1]
                    embed.color = color("990000").value
                end
            else
                local meta = command_handler:get_metadata()
                local comms = meta.plugins[args[1]]
                if not comms then
                    embed.description = "Unable to find plugin: "..args[1]
                    embed.color = color("990000").value
                else
                    embed.title = "Plugin ``"..args[1].."``"
                    embed.description = "``"..table.concat(comms,"``,``").."``"
                end
            end
        else
            local meta = command_handler:get_metadata()
            embed.title = "512mb.org commands:"
            embed.description = "use ``help <command>`` to view help messages. (type ``help help`` for more info)"
            embed.fields = {}
            for name,category in pairs(meta.categories) do
                table.insert(embed.fields,{
                    name = name,
                    value = "``"..table.concat(category,"``,``").."``"
                })
            end
        end
        msg:reply({embed = embed})
    end,
})
plugin:add_command(help_command)
plugin:load_helpdb(plugin_path.."help.lua")
return plugin
