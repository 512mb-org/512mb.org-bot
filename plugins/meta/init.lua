local aliases = {}
local fake_message = import("fake_message")
local last_message_arrived = discordia.Stopwatch()
local unixToString = import("unixToString")
local command = import("classes.command")
local plugin = import("classes.plugin")("meta")
local purify = import("purify")
if not config.aliases then 
    config.aliases = {}
end

client:on("messageCreate",function(msg)
    last_message_arrived:reset()
    last_message_arrived:start()
end)

local prefix
for k,v in pairs(command_handler:get_prefixes()) do
    if (not prefix) or prefix:len() > v:len() then
        prefix = v
    end
end

local function add_alias(name,comm,prefix,description)
    local helpmsg = "Alias for ``"..comm.."``"
    if description then
        helpmsg = helpmsg.."\n"..description
    end
    if (not aliases[name]) then
        log("ALIAS","Adding alias \""..name.."\" for \""..comm.."\"")
        config.aliases[name] = {comm = comm,prefix = prefix,description = description}
        aliases[name] = command(name,{
            help = helpmsg,
            usage = name,
            category = "Aliases",
            exec = function(msg,args2,opts)
                local str = msg.content:gsub("^%S+ ?","") 
                aftersub = comm:gsub("%.%.%.",str or "")
                local status,args = require("air").parse(str)
                for k,v in pairs(args) do
                    aftersub = aftersub:gsub("([^\\])%$"..k,"%1"..v)
                end
                log("ALIAS", "Triggering alias "..name.." with args \""..aftersub.."\"")
                command_handler:handle(fake_message(msg,{
                        content = aftersub
                }))
            end,
            options = {
                prefix = config.aliases[name].prefix,
                custom = true
            }
        })
        plugin:add_command(aliases[name])
        return true
    else
        return false
    end
end

local function remove_alias(name)
    if config.aliases[name] then
        config.aliases[name] = nil
        plugin:remove_command(aliases[name])
        aliases[name] = nil
        return true
    else
        return false
    end
end

for k,v in pairs(config.aliases) do
    commdata = v
    if type(v) == "string" then --legacy format conversion
        commdata = {comm = v, prefix = false}
    end
    add_alias(k,commdata.comm,commdata.prefix,commdata.description)
end

local prefix = command("prefix",{
    perms = {
        "administrator"
    },
    category = "Utilities",
    exec = function(msg,args,opts)
        local function list_prefixes(msg)
            local prefixes = ""
            for k,v in pairs(command_handler:get_prefixes()) do
                prefixes = prefixes.."``"..v:gsub("`","\\`").."``".."\n"
            end
            msg:reply({embed = {
                title = "Prefixes for this server",
                description = prefixes
            }})
        end
        if args[1] then
            if args[1] == "add" and args[2] then
                command_handler:add_prefix(args[2])
                msg:reply("Added ``"..args[2]:gsub("`","\\`").."`` as a prefix")
            elseif args[1] == "remove" and args[2] then
                local status,err = command_handler:remove_prefix(args[2])
                if status then
                    msg:reply("Removed the ``"..args[2]:gsub("`","\\`").."`` prefix")
                else
                    msg:reply(err)
                end
            elseif args[1] == "list" then
                list_prefixes(msg)
            else
                msg:reply("Syntax error")
            end
        else
            list_prefixes(msg)
        end
    end
})
plugin:add_command(prefix)

local c_alias = command("alias", {
    args = {
        "string","string"
    },
    perms = {
        "administrator"
    },
    category = "Automation",
    exec = function(msg,args,opts)
        if add_alias(args[1],args[2],not (opts["prefix"] or opts["p"]),opts["description"]) then
            msg:reply("Bound ``"..args[1].."`` as an alias to ``"..args[2].."``")
        else
            msg:reply("``"..args[1].."`` is already bound")
        end
    end
})
plugin:add_command(c_alias)

local c_unalias = command("unalias", {
    args = {
        "string"
    },
    perms = {
        "administrator"
    },
    category = "Automation",
    exec = function(msg,args,opts)
        if remove_alias(args[1]) then
            msg:reply("Removed the ``"..args[1].."`` alias")
        else
            msg:reply("No such alias")
        end
    end
})
plugin:add_command(c_unalias)

local c_aliases = command("aliases", {
    category = "Automation",
    exec = function(msg,args,opts)
        local page = (tonumber(args[1]) or 1)*5
        local events = (function()
            local fields = {}
            for k,v in pairs(config.aliases) do
                table.insert(fields,{k,v})
            end
            return fields
        end)()
        msg:reply({embed = {
            title = "Aliases for this server",
            fields = (function() 
                local fields = {}
                for i = page-4,page do
                    if not events[i] then break end
                    table.insert(fields,{
                        name = events[i][1],
                        value = events[i][2].comm
                    })
                end
                return fields
            end)(),
            footer = {
                text = "Aliases "..tostring(page-4).." - "..tostring(page).." | Total: "..tostring(#events)
            }
        }})
    end
})
plugin:add_command(c_aliases)

local c_ping = command("ping", {
    category = "Utilities",
    exec = function(msg,args,opts)
        local before = msg:getDate()
        local reply = msg:reply("Pong!")
        if not reply then
            log("ERROR","Couldn't send the ping reply for some reason")
            return
        end
        local after = reply:getDate()
        local latency = (after:toMilliseconds() - before:toMilliseconds())
        last_message_arrived:stop()
        local uptime = discordia.Date():toSeconds() - server.uptime:toSeconds()
        local processing = (last_message_arrived:getTime():toMilliseconds())
        msg:reply({embed = {
            title = "Stats:",
            fields = {
                {name = "Latency",value = tostring(math.floor(latency)).."ms"},
                {name = "Processing time",value = tostring(math.floor(processing)).."ms"},
                {name = "Uptime",value = tostring(unixToString(uptime))}
            }   
        }})
    end
})
plugin:add_command(c_ping)

local c_about = command("about", {
    category = "Miscellaneous",
    exec = function(msg,args,opts)
    local rand = math.random
    local author = client:getUser("245973168257368076")
    msg:reply({embed = {
        title = "About 512mb.org bot",
        thumbnail = {
            url = client.user:getAvatarURL()
        },
        color = discordia.Color.fromRGB(rand(50,200),rand(50,200),rand(50,200)).value,
        description = "512mb.org is an open-source bot written in Lua. It is based on a beta rewrite version of the Suppa-Bot.",
        fields = {
            {name = "Source Code: ",value = "https://github.com/512mb-xyz/512mb.org-bot"},
            {name = "Author: ",value = author.tag},
            {name = "Invite: ",value = "Not available yet"}
        },
        footer = {
            text = "For any information regarding the bot, contact yessiest on 512mb.org discord."
        }
    }})
    end
})
plugin:add_command(c_about)

local c_server = command("server", {
    category = "Utilities",
    exec = function(msg,args,opts)
    msg:reply({embed = {
        thumbnail = {
            url = msg.guild.iconURL
        },
        title = msg.guild.name,
        description = msg.guild.description,
        fields = {
            {name = "Members",value = msg.guild.totalMemberCount},
            {name = "Owner",value = (msg.guild.owner and msg.guild.owner.user.tag..":"..msg.guild.owner.user.id) or msg.guild.ownerId},
            {name = "Created At",value = os.date("!%c",msg.guild.createdAt).." (UTC+0)"},
            {name = "Text Channels",value = msg.guild.textChannels:count()},
            {name = "Voice Channels",value = msg.guild.voiceChannels:count()}
        }
    }})
    end,
})
plugin:add_command(c_server)

local c_user = command("user", {
    category = "Utilities",
    exec = function(msg,args,opts)
    local member = msg.guild:getMember((args[1] or ""):match("%d+")) or msg.guild:getMember(msg.author.id)
    local roles = ""
    for k,v in pairs(member.roles) do
        roles = roles..v.mentionString.."\n"
    end
    msg:reply({embed = {
        title = member.user.tag..":"..member.user.id,
        thumbnail = {
            url = member.user:getAvatarURL()
        },
        fields = {
            {name = "Profile Created At",value = os.date("!%c",member.user.createdAt).." (UTC+0)"},
            {name = "Joined At",value = os.date("!%c",discordia.Date.fromISO(member.joinedAt):toSeconds()).." (UTC+0)",inline = true},
            {name = "Boosting",value = ((member.premiumSince and "Since "..member.premiumSince) or "No"),inline = true},
            {name = "Highest Role",value = member.highestRole.mentionString,inline = true},
            {name = "Roles",value = roles,inline = true}
        }
    }})
    end,
})
plugin:add_command(c_user)

local c_speak = command("speak", {
    args = {
        "string"
    },
    category = "Utilities",
    exec = function(msg,args,opts)
        local text = purify.purify_pings(msg, table.concat(args," "))
        msg:reply(text)
        msg:delete()
    end,
})
plugin:add_command(c_speak)

local c_adminSpeak = command("adminSpeak", {
    category = "Utilities",
    args = {
        "string"
    },
    exec = function(msg,args,opts)
        local text = table.concat(args," ")
        msg:reply(text)
        msg:delete()
    end,
    perms = {
        "mentionEveryone"
    }
})
plugin:add_command(c_adminSpeak)

local c_adminSendToChannel = command("adminSendToChannel", {
    category = "Utilities",
    args = {
        "textChannel",
        "string"
    },
    exec = function(msg,args,opts)
        local channel = args[1]
        table.remove(args,1)
        local text = table.concat(args," ")
        channel:send(text)
    end,
    perms = {
        "mentionEveryone"
    }
})
plugin:add_command(c_adminSendToChannel)

local c_echo = command("echo",{
    category = "Utilities",
    args = {
        "string"
    },
    exec = function(msg,args,opts)
        local text = purify.purify_pings(msg, table.concat(args," "))
        msg:reply(text)
    end,
})
plugin:add_command(c_echo)

local c_sendToChannel = command("sendToChannel",{
    category = "Utilities",
    args = {
        "textChannel",
        "string"
    },
    exec = function(msg,args,opts)
        local channel = args[1]
        table.remove(args,1)
        local text = purify.purify_pings(msg, table.concat(args," "))
        channel:send(text)
    end,
})
plugin:add_command(c_sendToChannel)

local c_pingself = command("pingself",{
    category = "Utilities",
    args = {
         "string"
    },
    exec = function(msg,args,opts)
        local text = purify.purify_pings(msg, table.concat(args," "))
        msg:reply("<@"..tostring(msg.member.id).."> "..text)
    end,
})
plugin:add_command(c_pingself)

plugin.removal_callback = function()
    for k,v in pairs(config.aliases) do
        remove_alias(k)
    end
end

plugin:load_helpdb(plugin_path.."help.lua")
return plugin
