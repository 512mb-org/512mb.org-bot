local pluginc = import("classes.plugin")
local command = import("classes.command")
local sql = import("sqlite3")
local plugin = pluginc("help")

local db = sql.open(server.config_path.."sec.sqlite")

local safe_regex = function(str,pattern)
    local status,ret = pcall(string.match,str,pattern)
    if status then return ret end
end

if not db:rowexec("SELECT name FROM sqlite_master WHERE type='table' AND name='infractions'") then
    db:exec [[
CREATE TABLE infractions(id INTEGER PRIMARY KEY AUTOINCREMENT, user TEXT, desc TEXT, action TEXT, timestamp INTEGER);
]]
end

local grantrole = command("grant-role",{
    category = "Security",
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
    category = "Security",
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

local ban = command("ban",{
    category = "Security",
    perms = {
        "banMembers"
    },
    args = {
        "member"
    },
    exec = function(msg,args,opts)
        return args[1]:ban(opts["reason"])
    end
})
plugin:add_command(ban)

local kick = command("kick", {
    category = "Security",
    perms = {
        "kickMembers",
    },
    args = {
        "member"
    },
    exec = function(msg,args,opts)
        return args[1]:ban(opts["reason"])
    end
})
plugin:add_command(kick)

local warn = command("warn",{
    category = "Security",
    perms = {
        "kickMembers"
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

local pardon = command("pardon",{
    category = "Security",
    perms = {
        "kickMembers"
    },
    args = {
        "member",
        "number"
    },
    exec = function(msg,args,opts)
        local countst = db:prepare("SELECT id FROM infractions WHERE user = ? AND id = ?")
        local inf = countst:reset():bind(tostring(args[1].id),args[2]):step()
        local found = (inf ~= nil)
        if not found then
            msg:reply("No infraction "..tostring(args[2]).." found on user "..tostring(args[1].name))
            return false
        end
        local reasonst = db:prepare("SELECT desc, timestamp FROM infractions WHERE id = ?")
        local infra = reasonst:reset():bind(args[2]):step()
        if not infra then
            msg:reply("Unknown id: "..tostring(args[2]))
            return false
        end
        local reason = infra[1]
        local timestamp = infra[2]
        local rmst = db:prepare("DELETE FROM infractions WHERE id = ?")
        rmst:reset():bind(args[2]):step()
        msg:reply({embed = {
            title = "User has been pardoned",
            description = args[1].name.." has been pardoned for warning "..tostring(args[2]),
            fields = {
                { name = "Warning count: ", value = tostring(#inf-1)},
                { name = "Reason: ", value = reason },
                { name = "Timestamp: ", value = tostring(timestamp) }
            },
        }})
    end
})
plugin:add_command(pardon)

local infractions = command("infractions", {
    category = "Security",
    perms = {
        "kickMembers"
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

local purge = command("purge",{
    category = "Security",
    perms = {
        "manageMessages"
    },
    args = {
        "number"
    },
    exec = function(msg,args,opts)
        local messages = {}
        local messageCount = args[1]
        local deletedMessageCount = 0
        local last_id = nil
        local matchfunc = function(v)
            last_id = v.id
            local matches = true
            if opts["regex"] and (not (
                (type(v.content) == "string") and
                (safe_regex(v.content,opts["regex"])))) then
                    matches = false
            end
            if opts["user"] and (not (
                (v.author.id and (tostring(v.author.id) == opts["user"])) or
                (v.author.name == opts["user"]))) then
                    matches = false
            end
            if opts["w"] and (not v.webhookId) then
                    matches = false
            end
            if matches then
                table.insert(messages,v.id)
                deletedMessageCount = deletedMessageCount + 1
            end
        end
        local messages_fetched = msg.channel:getMessages(args[1]%100)
        if messages_fetched then
            messages_fetched:forEach(matchfunc)
        end
        msg.channel:bulkDelete(messages)
        messageCount = messageCount-(args[1]%100)
        while messageCount > 0 do
            messages = {}
            messages_fetched = msg.channel:getMessagesAfter(last_id,100)
            if messages_fetched then
                messages_fetched:forEach(matchfunc)
            end
            msg.channel:bulkDelete(messages)
            messageCount = messageCount - 100
        end
        msg:reply("Deleted "..tostring(deletedMessageCount).." messages.")
    end
})
plugin:add_command(purge)
plugin:load_helpdb(plugin_path.."help.lua")
return plugin
