--rewrite this lib (P.S: done)
--P.S: air stands for Advanced Input Recognition, although technically it's not all that advanced
local parse_string = require("string_parse")
air = {}
object_types = {
    ["voiceChannel"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local channel = guild:getChannel(id:match("(%d+)[^%d]*$"))
        if tostring(channel):match("^GuildVoiceChannel: ") then
            return true,channel
        else
            return false
        end
    end,
    ["textChannel"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local channel = guild:getChannel(id:match("(%d+)[^%d]*$"))
        if tostring(channel):match("^GuildTextChannel: ") then
            return true,channel
        else
            return false
        end
    end,
    ["messageLink"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local channelId,messageId = id:match("(%d+)/(%d+)[^%d]*$")
        channel = guild:getChannel(channelId)
        if tostring(channel):find("GuildTextChannel") then
            message = channel:getMessage(messageId)
            if message then
                return true,message
            end
        end
        return false
    end,
    ["role"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local role = guild:getRole(id:match("(%d+)[^%d]*$"))
        if role then
            return true,role
        else
            return false
        end
    end,
    ["member"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local member = guild:getMember(id:match("(%d+)[^%d]*$"))
        if member then
            return true,member
        else
            return false
        end
    end,
    ["emoji"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local emoji = guild:getEmoji(id:match("(%d+)[^%d]*$"))
        if emoji then
            return true,emoji
        else
            return false
        end
    end,
    ["ban"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local ban = guild:getBan(id:match("(%d+)[^%d]*$"))
        if ban then
            return true,ban
        else
            return false
        end
    end,
    ["channel"] = function(id,client,guild_id)
        local guild = client:getGuild(guild_id)
        local channel = guild:getChannel(id:match("(%d+)[^%d]*$"))
        if channel then
            return true,channel
        else
            return false
        end
    end,
    ["user"] = function(id,client,guild_id)
        local user = client:getUser(id:match("(%d+)[^%d]*$"))
        if user then
            return true,user
        end
        return false
    end,
    ["id"] = function(id)
        if tonumber(id:match("(%d+)[^%d]*$")) and tostring(id:match("(%d+)[^%d]*$")):len() > 10 then
            return true,id
        end
        return false
    end,
    ["string"] = function(str)
        if str:match("^[\"'].*[\"']$") then
            return true, str:match("^[\"'](.*)[\"']$") 
        end
        return true,str
    end,
    ["number"] = function(n)
        local number = tonumber(n)
        return (number ~= nil), number
    end
}

air.parse = function(string,argmatch,client,guild_id)
    local strings = parse_string(string,"[\"']")
    local argmatch = argmatch or {}
    local tokens,args,opts = {},{},{}
    -- Tokenize
    for k,v in pairs(strings) do
        local padded_string = v:match("^%s*(.+)%s*$")
        if padded_string:match("^[\"'].*[\"']$") then
            table.insert(tokens,padded_string)
        else
            v:gsub("%S+",function(text)
                table.insert(tokens,text)
            end)
        end
    end
    -- Remove opts and match arguments
    for k,v in pairs(tokens) do
        if v:match("^%-%-%w+=$") then
            local optname = table.remove(tokens,k):match("^%-%-(%w+)=$")
            local value = tokens[k]
            opts[optname] = value
        elseif v:match("^%-%-%w+$") then
            local optname = v:match("^%-%-(%w+)$")
            opts[optname] = true
        elseif v:match("^%-%w+$") then
            local opts = v:gsub("%w",function(c)
                opts[c] = true
            end)
        else
            local arg = table.remove(argmatch,1)
            if arg then
                local status,obj = object_types[arg](v,client,guild_id)
                if not status then
                    return false, args, opts, "Mismatched argument "..tostring(#arg)..": "..arg.." expected."
                end
                table.insert(args,obj)
            else
                table.insert(args,select(2,object_types["string"](v)))
            end
        end
    end
    if #argmatch > 0 then
        return false, args, opts, "Missing arguments: "..table.concat(argmatch,", ")
    end
    return true, args, opts
end
return air
