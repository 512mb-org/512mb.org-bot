local pluginc = import("classes.plugin")
local command = import("classes.command")
local plugin = pluginc("cron")
local cron = import("cron")
local fake_message = import("fake_message")
local md5 = import("md5")
local events = {
    timer = {},
    event = {}
}

local exec = function(v,command)
    local channel = client:getChannel(v.channel)
    if not channel then
        log("ERROR","Unable to retrieve timer channel: "..tostring(v.channel))
        return
    end
    local msg = channel:getMessage(v.id)
    if not msg then
        log("ERROR","Unable to retrieve timer message: "..tostring(v.id))
        return
    end
    command_handler:handle(fake_message(msg,{
        delete = function() end,
        content = command
    }))
end

if not config.events then
    config.events = {
        timer = {},
        event = {message = {}}
    }
end

local event = command("event",{
    help = {embed={
      title = "Add a cron event",
      description = "Description coming soon",
      fields = {
        {name = "Usage:",value = "event ..."},
        {name = "Perms:",value = "administrator"},
      }
    }},
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
        local arg = table.concat(args," ")
        local func,functype = cron.parse_line(arg)
        if not func then
            msg:reply(functype)
            return false
        end
        local hash = md5.sumhexa(arg):sub(1,16)
        if functype == "directive" then
            local event_name = arg:match("^@(%w+)")
            if not events.event[event_name] then events.event[event_name] = {} end
            events.event[event_name][hash] = {
                func,
                channel = tostring(msg.channel.id),
                id = tostring(msg.id),
                user = tostring(msg.author.id),
                type = functype
            }
            if not config.events.event[event_name] then config.events.event[event_name] = {} end
            config.events.event[event_name][hash] = {
                arg,
                channel = tostring(msg.channel.id),
                id = tostring(msg.id),
                user = tostring(msg.author.id),
                type = functype
            }
        else
            events.timer[hash] = {
                func,
                channel = tostring(msg.channel.id),
                id = tostring(msg.id),
                user = tostring(msg.author.id),
                type = functype
            }
            config.events.timer[hash] = {
                arg,
                channel = tostring(msg.channel.id),
                id = tostring(msg.id),
                user = tostring(msg.author.id),
                type = functype
            }
        end
        return true
    end
})
plugin:add_command(event)

local delay = command("delay",{
    help = {embed={
      title = "Delay a command",
      description = "Delay fromat is <number><unit>, where unit is one of the follwing:\n\"h\" - hour,\n\"m\" - minute,\n\"d\" - day,\n\"w\" - week,\n\"y\" - year",
      fields = {
        {name = "Usage:",value = "delay <delayformat> <command>"},
        {name = "Perms:",value = "administrator"},
      }
    }},
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
        local format = args[1]
        table.remove(args,1)
        local arg = os.date("%d.%m.%y %H:%M ",cron.convert_delay(format))..table.concat(args," ")
        local func,functype = cron.parse_line(arg)
        if not func then
            msg:reply(functype)
            return false
        end
        local hash = md5.sumhexa(arg):sub(1,16)
        events.timer[hash] = {
            func,
            channel = tostring(msg.channel.id),
            id = tostring(msg.id),
            user = tostring(msg.author.id),
            type = functype
        }
        config.events.timer[hash] = {
            arg,
            channel = tostring(msg.channel.id),
            id = tostring(msg.id),
            user = tostring(msg.author.id),
            type = functype
        }
        return true 
    end
})
plugin:add_command(delay)

local delay = command("events",{
    help = {embed={
      title = "View your running events",
      description = "nuff said.",
      fields = {
        {name = "Usage:",value = "events <page>"},
        {name = "Perms:",value = "administrator"},
      }
    }},
    perms = {
        "administrator"
    },
    args = {
        "number"
    },
    exec = function(msg,args,opts)
        local uevents = {}
        local uhashes = {}
        local upto = 5*args[1]
        for k,v in pairs(config.events.timer) do
            if v.user == tostring(msg.author.id) then
                table.insert(uevents,v)
                table.insert(uhashes,k)
            end
            if #events == upto then
                break
            end
        end
        local stop = false
        for k,v in pairs(config.events.event) do
            for _,events in pairs(v) do
                if v.user == tostring(msg.author.id) then
                    table.insert(uevents,v)
                    table.insert(uhashes,k)
                end
                if #events == upto then
                    stop = true
                    break
                end
            end
            if stop then
                break
            end
        end
        local message = {embed = {
            title = "Your events: ",
            description = "",
            footer = {
                text = "Events "..tostring(upto-4).." - "..tostring(upto)
            }
        }}
        for I = upto-4,upto do
            if not uhashes[I] then
                break
            end
            message.embed.description = message.embed.description.."["..uhashes[I].."] `"..uevents[I][1].."`\n"
        end
        msg:reply(message)
    end
})
plugin:add_command(delay)

local timer = discordia.Clock()
timer:on("min",function()
    for k,v in pairs(events.timer) do
        local status,command = v[1](os.date("*t"))
        if status then
            exec(v,command)
            if v.type == "onetime" then
                events.timer[k] = nil
                config.events.timer[k] = nil
            end
        end
    end
end)

client:on("messageCreate",function(msg)
    local content = msg.content
    local user = msg.author.name
    for k,v in pairs(events.event.message or {}) do
        local status,command = v[1]({content,user})
        if status then
            exec(v,command)
        end
    end
    for k,v in pairs(events.event.messageOnce or {}) do
        local status,command = v[1]({content,user})
        events.event.messageOnce[k] = nil
        config.events.event.messageOnce[k] = nil
    end
end)

timer:start(true)
return plugin
