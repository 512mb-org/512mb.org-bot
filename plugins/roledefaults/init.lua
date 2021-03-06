local plugin_class = import("classes.plugin")
local command = import("classes.command")
local plugin = plugin_class("roledefaults")
config.default_roles = config.default_roles or {}
client:on("memberJoin",function(member)
    for k,v in pairs(config.default_roles) do 
        member:addRole(v)
    end
end)

local droleadd = command("droleadd",{
    category = "Automation",
    usage = "droleadd <role>",
    perms = {"administrator"},
    args = {
        "role"
    },
	exec = function(msg,args,opts)
        table.insert(config.default_roles,args[1].id)
        msg:reply("Added role "..args[1].name.." to default roles list")
    end,
})
local droledel = command("droledel",{
        category = "Automation",
        usage = "droledel <role>",
        perms = {"administrator"},
        args = {
            "role"
        },
        exec = function(msg,args,opts)
            for k,v in pairs(config.default_roles) do
                if v == args[1].id then
                    table.remove(config.default_roles,k)
                end
            end
            msg:reply("Removed role "..args[1].name.." from default roles list")
        end
})
local drolelist = command("drolelist", {
        category = "Automation",
        usage = "drolelist",
        perms = {"administrator"},
        exec = function(msg,args,opts)
            local reply = { embed = {
                title = "Default roles:",
                fields = {}
            }}
            for k,v in pairs(config.default_roles) do 
                table.insert(reply.embed.fields,{
                    name = tostring(k), value = tostring(v)
                })
            end
            msg:reply(reply)
        end
})
plugin:add_command(droleadd)
plugin:add_command(droledel)
plugin:add_command(drolelist)
plugin:load_helpdb(plugin_path.."help.lua")
return plugin

