local pluginc = import("classes.plugin")
local command = import("classes.command")
local sql = import("sqlite3")
local plugin = pluginc("help")

local db = sql.open(server.config_path.."sec.sqlite")

if not db:rowexec("SELECT name FROM sqlite_master WHERE type='table' AND name='infractions'") then
    db:exec [[
CREATE TABLE infractions(id INTEGER PRIMARY KEY AUTOINCREMENT, user TEXT, desc TEXT, action TEXT, timestamp INTEGER);
]]
end

local grantrole = command("grant-role",{
    help = {embed={
      title = "Grant a role to the user",
      description = "If <user> is not provided, the caller is assumed as the <user> argument.",
      fields = {
        {name = "Usage:",value = "grant-role <role id> [<user>]"},
        {name = "Perms:",value = "administrator"},
        {name = "Options:",value = "-q - quiet (don't print the result)"}
      }
    }},
    perms = {
        "administrator"
    },
    args = {
        "role"
    },
    exec = function(msg,args,opts)
        return ((args[2] and 
                    msg.guild:getMember(args[2]:match("%d+"))
                ) or msg.member):addRole(args[1])
    end
})
plugin:add_command(grantrole)

local revokerole = command("revoke-role",{
    help = {embed={
      title = "Revoke a role from the user",
      description = "If <user> is not provided, the caller is assumed as the <user> argument.",
      fields = {
        {name = "Usage:",value = "revoke-role <role id> [<user>]"},
        {name = "Perms:",value = "administrator"},
        {name = "Options:",value = "-q - quiet (don't print the result)"}
      }
    }},
    perms = {
        "administrator"
    },
    args = {
        "role"
    },
    exec = function(msg,args,opts)
        return ((args[2] and 
                    msg.guild:getMember(args[2]:match("%d+"))) 
                or msg.member):removeRole(args[1])
    end
})
plugin:add_command(revokerole)

local warn = command("warn",{
    help = {embed={
      title = "Warn a user",
      description = "nuff said.",
      fields = {
        {name = "Usage:",value = "warn <user> <reason>"},
        {name = "Perms:",value = "kick_members"},
      }
    }},
    perms = {
        "kick_members"
    },
    args = {
        "member",
        "string"
    },
    exec = function(msg,args,opts)
        local warnst = db:prepare("INSERT INTO infractions VALUES(NULL, ?,?,?, date())")
        warnst:reset():bind(tostring(args[1].id),args[2],"warn"):step()
        local countst = db:prepare("SELECT COUNT(*) FROM infractions WHERE user=?")
        local v = countst:reset():bind(tostring(args[1].id)):step()
        msg:reply({embed = {
            title = "User has been warned successfully",
            description = args[1].name.." has been given out a warning.",
            fields = {
                { name = "Warning count: ", value = tostring(tonumber(v[1])) },
                { name = "Reason: ", value = args[2] },
                { name = "Timestamp: ", value = os.date("%a %b %e %H:%M:%S %Y",os.time(os.date("!*t"))) }
            },
        }})
    end
})
plugin:add_command(warn)

local infractions = command("infractions", {
    help = { embed = {
        title = "List user infractions",
        description = "Infractions include kicks, bans, mutes and warnings.",
        fields = {
            {name = "Usage: ", value = "infractions <user> [<startfrom>]"},
            {name = "Perms: ", value = "kick_members"},
            {name = "Options: ", value = "--type=(warn default,ban,kick)"}
        }
    }},
    perms = {
        "kick_members"
    },
    args = {
        "member",
    },
    exec = function(msg,args,opts)
        -- Parse args and set defaults
        local dtype = "warn"
        if opts["type"] and type(opts["type"]) ~= "boolean" then
            dtype = opts["type"]
        end
        local page = tonumber(args[2]) or 0
        -- Get a total count
        local countst = db:prepare("SELECT COUNT(*) FROM infractions WHERE user=? AND action = ?")
        local v = countst:reset():bind(tostring(args[1].id),dtype):step()
        local message = {embed = {
            title = "Infractions list for "..args[1].name,
            fields = {},
            footer = {
                text = "Total: "..tostring(tonumber(v[1])).." | Starting from: "..tostring(page)

            }
        }}
        -- Prepare a statement to match infractions
        local pagedb = db:prepare("SELECT * FROM infractions WHERE action = ? AND user = ? AND id > ? ORDER BY id LIMIT 5")
        local pagecomm = pagedb:reset():bind(dtype,tostring(args[1].id),page)
        -- Keep matching infractions as long as something is returned
        local pagedata = pagecomm:step()
        while pagedata ~= nil do
            table.insert(message.embed.fields,{
                name = tostring(tonumber(pagedata[1])),
                value = pagedata[3]
            })
            pagedata = pagecomm:step()
        end
        msg:reply(message)
    end
})
plugin:add_command(infractions)

return plugin
