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
        log("ERROR","Unable to retrieve event channel: "..tostring(v.channel))
        log("ERROR","Failed event: "..command)
        return
    end
    local msg = channel:getMessage(v.id)
    if not msg then
        log("ERROR","Unable to retrieve event message: "..tostring(v.id))
        log("ERROR","Failed event: "..command)
        return
    end
    if not msg.member then
        log("ERROR","Unable to retrieve event creator: "..tostring(v.user.id))
        log("ERROR","Failed event: "..command)
        return
    end
    command_handler:handle(fake_message(msg,{
        delete = function() end,
        content = command
    }),1)
end

if not config.events then
    config.events = {
        timer = {},
        event = {message = {}}
    }
end

local create_event = function(msg,cronjob,create_entry)
    local arg = cronjob
    local func,functype = cron.parse_line(arg)
    if not func then
        msg:reply(functype)
        return false
    end
    local hash = md5.sumhexa(msg.author.id..arg)
    if functype == "directive" then
        local event_name = arg:match("^@(%w+)")
        if not events.event[event_name] then events.event[event_name] = {} end
        events.event[event_name][hash] = {
            comm = func,
            channel = tostring(msg.channel.id),
            id = tostring(msg.id),
            user = tostring(msg.author.id),
            type = functype
        }
        if create_entry then return true,hash end
        if not config.events.event[event_name] then config.events.event[event_name] = {} end
        config.events.event[event_name][hash] = {
            comm = arg,
            channel = tostring(msg.channel.id),
            id = tostring(msg.id),
            user = tostring(msg.author.id),
            type = functype
        }
    else
        events.timer[hash] = {
            comm = func,
            channel = tostring(msg.channel.id),
            id = tostring(msg.id),
            user = tostring(msg.author.id),
            type = functype
        }
        if create_entry then return true,hash end
        config.events.timer[hash] = {
            comm = arg,
            channel = tostring(msg.channel.id),
            id = tostring(msg.id),
            user = tostring(msg.author.id),
            type = functype
        }
    end
    return true,hash
end

local get_user_events = function(author_id,page)
    local uevents = {}
    local uhashes = {}
    local upto = 5*page
    for k,v in pairs(config.events.timer) do
        if v.user == tostring(author_id) then
            table.insert(uevents,v)
            table.insert(uhashes,k)
        end
        if #events == upto then
            break
        end
    end
    local stop = false
    for _,evtype in pairs(config.events.event) do
        for k,v in pairs(evtype) do
            if v.user == tostring(author_id) then
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
    return uevents,uhashes
end

local function compids(id1,id2)
    id1 = tostring(id1)
    id2 = tostring(id2)
    if id2:match("^%w+%*") then
        local partid = id2:match("%w+")
        return (id1:match("^"..partid.."%w*$") ~= nil)
    else
        return id1 == id2
    end
end

local remove_user_event = function(user_id,id)
    for k,v in pairs(config.events.timer) do
        if compids(k,id) and (v.user == tostring(user_id)) then
            config.events.timer[k] = nil
            events.timer[k] = nil
            return true
        end
    end
    for evname,evtype in pairs(config.events.event) do
        for k,v in pairs(evtype) do
            if compids(k,id) and (v.user == tostring(user_id)) then
                config.events.event[evname][k] = nil
                events.event[evname][k] = nil
                return true
            end
        end
    end
    return false
end

-- load timer events
for k,v in pairs(config.events.timer) do
    local channel = client:getChannel(v.channel)
    if channel then
        local message = channel:getMessage(v.id)
        if message then
            local status,hash = create_event(message,v.comm,true)
            --orphan events with mismatching hashes
            if status and (hash ~= k) then 
                log("WARNING", "Hash mismatch, orphaning event.")
                events.timer[k] = nil
                config.events.timer[k] = nil
                create_event(message,v.comm)
            end
        else
            log("ERROR","No message with id "..v.id)
            log("ERROR","Event id: "..k..".\nEvent description: ")
            print(v.comm)
        end
    else
        log("ERROR","No channel with id "..v.channel)
        log("ERROR","Event id: "..k..".\nEvent description: ")
        print(v.comm)
    end
end

-- load named events
for _,evtype in pairs(config.events.event) do
    events.event[_] = {}
    for k,v in pairs(evtype) do
        local channel = client:getChannel(v.channel)
        if channel then
            local message = channel:getMessage(v.id)
            if message then
                local status,hash = create_event(message,v.comm,true)
                --orphan events with mismatching hashes
                if status and (hash ~= k) then 
                    log("WARNING", "Hash mismatch, orphaning event.")
                    events.event[_][k] = nil
                    config.events.event[_][k] = nil
                    create_event(message,v.comm)
                end
            else
                log("ERROR","No message with id "..v.id)
                log("ERROR","Event "..k..".\nEvent description: ")
                config.events.event[_][k] = nil
            end
        else
            log("ERROR","No channel with id "..v.channel)
            log("ERROR","Event "..k..".\nEvent description: ")
            config.events.event[_][k] = nil
        end
    end
end

local event = command("event",{
    category = "Automation",
    perms = {"administrator"},
    args = {"string"},
    exec = function(msg,args,opts)
        return create_event(msg,table.concat(args," "))
    end
})
plugin:add_command(event)

local delay = command("delay",{
    category = "Automation",
    args = {
        "string",
        "string"
    },
    exec = function(msg,args,opts)
        local format = args[1]
        table.remove(args,1)
        local arg = os.date("%d.%m.%y %H:%M ",cron.convert_delay(format))..table.concat(args," ")
        return create_event(msg,arg)
    end
})
plugin:add_command(delay)

local events_comm = command("events",{
    category = "Automation",
    exec = function(msg,args,opts)
        args[1] = tonumber(args[1]) or 1
        local upto = args[1]*5
        local uevents,uhashes = get_user_events(msg.author.id,args[1])
        local message = {embed = {
            title = "Your events: ",
            description = "",
            footer = {
                text = "Events "..tostring(upto-4).." - "..tostring(upto).." | Total: "..tostring(#uevents)
            }
        }}
        for I = upto-4,upto do
            if not uhashes[I] then
                break
            end
            message.embed.description = message.embed.description.."["..uhashes[I].."]:\n`"..uevents[I].comm.."`\n"
        end
        msg:reply(message)
    end
})
plugin:add_command(events_comm)

local user_events_comm = command("user-events",{
    category = "Automation",
    args = {"member"},
    perms = {"administrator"},
    exec = function(msg,args,opts)
        args[2] = tonumber(args[2]) or 1
        local upto = args[2]*5
        local uevents,uhashes = get_user_events(args[1].id,args[2])
        local message = {embed = {
            title = "Events (for user "..args[1].name.."): ",
            description = "",
            footer = {
                text = "Events "..tostring(upto-4).." - "..tostring(upto)
            }
        }}
        for I = upto-4,upto do
            if not uhashes[I] then
                break
            end
            message.embed.description = message.embed.description.."["..uhashes[I].."]:\n`"..uevents[I].comm.."`\n"
        end
        msg:reply(message)
    end
})
plugin:add_command(user_events_comm)

local remove_event= command("remove-event",{
    category = "Automation",
    args = {"string"},
    exec = function(msg,args,opts)
        return remove_user_event(msg.author.id,args[1])
    end
})
plugin:add_command(remove_event)

local remove_user_event_c = command("remove-user-event",{
    args = {
        "member",
        "string"
    },
    perms = {
        "administrator"
    },
    category = "Automation",
    exec = function(msg,args,opts)
        return remove_user_event(args[1].id,args[2])
    end
})
plugin:add_command(remove_user_event_c)

local date_c = command("date",{
    category = "Utilities",
    exec = function(msg,args,opts)
        msg:reply(os.date("%d.%m.%Y %H:%M"))
    end
})
plugin:add_command(date_c)

local timer = discordia.Clock()
timer:on("min",function()
    for k,v in pairs(events.timer) do
        local status,command = v.comm(os.date("*t"))
        if status then
            exec(v,command)
            if v.type == "onetime" then
                events.timer[k] = nil
                config.events.timer[k] = nil
            end
        end
    end
end)

--load events file
local fhandler = io.open(plugin_path.."/events.lua","r")
local data = fhandler:read("*a")
fhandler:close()
local eventfunc = load(data,"event loader: "..plugin_path.."/events.lua",nil,setmetatable({
    id = id,
    client = client,
    exec = exec,
    events = events,
    config = config
},{__index = _G}))
eventfunc()
timer:start(true)

plugin:load_helpdb(plugin_path.."help.lua")
return plugin
