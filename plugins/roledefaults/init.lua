local plugin_class = import("classes.plugin")
local command = import("classes.command")
local plugin = plugin_class("roledefaults")
config.default_roles = {}
client:on("memeberJoin",function(member)
    for k,v in pairs(config.default_roles) do 
        member:addRole(v)
    end
end)

local droleadd = command("droleadd",{
		help = "Add a default role to assign for new users",
        usage = "droleadd <role>",
        args = {
            "role"
        },
		exec = function(msg,args,opts)
	        table.insert(config.default_roles,args[1].id)
        end,
})
local droledel = command("droledel",{
        help = "Remove a role from the list of default roles",
        usage = "droledel <role>",
        args = {
            "role"
        },
        exec = function(msg,args,opts)
            for k,v in pairs(config.default_roles) do
                if v == args[1].id then
                    table.remove(config.default_roles,k)
                end
            end
        end
})
plugin:add_command(droleadd)
plugin:add_command(droledel)
return plugin

