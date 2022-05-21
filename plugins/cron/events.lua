local replace = function(text,args)
    local text = text
    for k,v in pairs(args) do
        text = text:gsub(k,v)
    end
    return text
end

local trigger = function(evtbl,args,vars)
    for k,v in pairs(events.event[evtbl] or {}) do
        local status,command = v.comm(args)
        if status then
            exec(v,replace(command,vars))
        end
    end
end

local triggerOnce = function(evname,args,vars)
    for k,v in pairs(events.event[evname] or {}) do
        local status,command = v.comm(args)
        if status then
            exec(v,replace(command,vars))
            events.event[evname][k] = nil
            config.events.event[evname][k] = nil
        end
    end
end

event_emitter:on("messageCreate",function(msg)
    local content = msg.content
    local user = msg.author.id
    local channelid = msg.channel.id
    local args = {
        ["%$USER"] = user,
        ["%$USERNAME"] = msg.author.name,
        ["%$CHANNEL"] = channelid,
        ["%$CONTENT"] = msg.content
    }
    -- @message: content, userId, channelId, $USER, $USERNAME, $CHANNEL, $CONTENT
    trigger("message",{content,user,channelid},args)
    -- @messageOnce: content, userId, channelId, $USER, $USERNAME, $CHANNEL, $CONTENT
    triggerOnce("messageOnce",{content,user,channelid},args)
end)

event_emitter:on("userBan",function(user,guild)
    args = {
        ["%$USER"] = user.id,
        ["%$USERNAME"] = user.name
    }
    -- @ban: userId, $USER, $USERNAME
    trigger("ban",{user.id},args)
    -- @banOnce: userId, $USER, $USERNAME
    triggerOnce("banOnce",{user.id},args)
end)    

event_emitter:on("userUnban",function(user,guild)
    args = {
        ["%$USER"] = user.id,
        ["%$USERNAME"] = user.name
    }
    -- @unban: userId, $USER, $USERNAME
    trigger("unban",{user.id},args)
    -- @unbanOnce: userId, $USER, $USERNAME
    triggerOnce("unbanOnce",{user.id},args)
end)

event_emitter:on("memberJoin", function(member)
    args = {
        ["%$USER"] = member.id,
        ["%$USERNAME"] = member.name,
        ["%$AGE"] = discordia.Date():toSeconds()-member.user.createdAt,
        ["%$DISCRIM"] = member.user.discriminator,
        ["%$TAG"] = member.user.tag
    }
    -- @join: userid, username, age, $USER, $USERNAME, $AGE, $DISCRIM, $TAG
    trigger("join",{
        member.id,
        member.name,
        discordia.Date():toSeconds()-member.user.createdAt
    },args)
    -- @joinOnce: userid, username, age, $USER, $USERNAME, $AGE, $DISCRIM, $TAG
    triggerOnce("joinOnce",{
        member.id,
        member.name,
        discordia.Date():toSeconds()-member.user.createdAt
    },args)
end)

event_emitter:on("memberLeave", function(member)
    args = {
        ["%$USER"] = member.id,
        ["%$USERNAME"] = member.name,
        ["%$AGE"] = discordia.Date():toSeconds()-member.user.createdAt,
        ["%$DISCRIM"] = member.user.discriminator,
        ["%$TAG"] = member.user.tag,
        ["%$GUILDTIME"] = member.joinedAt,
        ["%$ROLE"] = member.highestRole.name,
    }
    --@leave: userid, username, role, $USER, $USERNAME, $AGE, $DISCRIM, $TAG, $GUILDTIME, $ROLE
    trigger("leave",{
        member.id,
        member.name,
        member.highestRole.name,
    },args)
    --@leave: userid, username, role, $USER, $USERNAME, $AGE, $DISCRIM, $TAG, $GUILDTIME, $ROLE
    triggerOnce("leaveOnce",{
        member.id,
        member.name,
        member.highestRole.name,
    },args)
end)
