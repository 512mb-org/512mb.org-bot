local file = require("file")
local guild = client:getGuild(id)
local fake_message = require("fake_message")
local command = import("classes.command")
local plugin = import("classes.plugin")("reactions")
local segment = {}
segment.pivots = config

local getEmoji = function(id)
  local emoji = guild:getEmoji(id:match("(%d+)[^%d]*$"))
  if emoji then
    return emoji
  else
    return id
  end
end

local function count(tab)
  local n = 0
  for k,v in pairs(tab) do
    n = n + 1
  end
  return n
end

local pivot = command("pivot",{
    help = {embed={
      title = "Select a pivot message to manipulate",
      description = "Pivot is like a message selector which allows easy reaction manipulations",
      fields = {
        {name = "Usage: ",value = "pivot <message link>"},
        {name = "Perms: ",valeu = "Administartor"}
      }
    }},
    args = {
      "messageLink"
    },
    perms = {
      "administrator"
    },
    exec = function(msg,args,opts)
      if segment.pivot and count(segment.pivot.buttons) == 0 then
        print("[REACTIONS] Deleting pivot: "..tostring(segment.pivot.message))
        segment.pivots[segment.pivot.message] = nil
      end
      local message = args[1]
      if not message then
        msg:reply("Couldn't find message with id "..args[2])
        return false
      end
      if not segment.pivots[message.id] then
        print("[REACTIONS] Creating pivot: "..tostring(message.id))
        segment.pivots[message.id] = {}
        segment.pivots[message.id].message = message.id
        segment.pivots[message.id].channel = message.channel.id
        segment.pivots[message.id].buttons = {}
      end
      segment.pivot = segment.pivots[message.id]
      return true
    end
  })
plugin:add_command(pivot)

local role_toggle = command("role-toggle",{
    help = {embed={
      title = "Add a simple role switch to the pivot",
      description = "Note: you cannot assign more than one role to a single reaction",
      fields = {
        {name = "Usage: ",value = "role-toggle <emoji> <role ping or role id>"},
        {name = "Perms: ",value = "administrator"}
      }
    }},
    args = {
      "string",
      "role",
    },
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
      if not segment.pivot then
        msg:reply("Pivot not selected. Use "..globals.prefix.."pivot to select it and then try again")
        return false
      end
      local emoji = getEmoji(args[1])
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      print("[REACTIONS] Adding role-toggle listener")
      local grabEmoji = function(reaction)
        segment.pivot.buttons[tostring(reaction.emojiId or reaction.emojiName)] = {
          type = "role-toggler",
          role = tostring(args[2].id)
        }
      end
      message:removeReaction(emoji,client.user.id)
      client:once("reactionAdd",grabEmoji)
      if not message:addReaction(emoji) then
        client:removeListener("reactionAdd",grabEmoji)
        msg:reply("Couldn't add reaction - emoji might be invalid")
        return false
      else
        return true
      end
    end
  })
plugin:add_command(role_toggle)
local remove_reaction = command("remove-reaction",{
    help = {embed={
      title = "Remove a reaction from a pivot",
      description = "If you don't specify a reaction to remove, the entire pivot for the message is removed automatically",
      fields = {
        {name = "Usage: ",value = "remove-reaction <emoji>"},
        {name = "Perms: ",value = "Administrator"}
      }
    }},
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      print("[REACTIONS] Removing reaction listener")
      if args[1] then
        local emoji = getEmoji(args[1])
        message:removeReaction(emoji,client.user.id)
        segment.pivot.buttons[((type(emoji) == "table") and emoji.id) or emoji] = nil
        return true
      else
        message:clearReactions()
        segment.pivots[tostring(message.id)] = nil
        segment.pivot = nil
        return true
      end
    end
  })
plugin:add_command(remove_reaction)
local toggle = command("toggle",{
    help = {embed={
      title = "Add a toggle that runs specific commands",
      description = "Note: you cannot assign more than one action to a single reaction \n``$user`` gets replaced with the id of the user that interacted with the reaction.",
      fields = {
        {name = "Usage: ",value = "toggle <emoji> <command-on> <command-off>"},
        {name = "Perms: ",value = "administrator"}
      }
    }},
    args = {
      "string",
      "string",
      "string",
    },
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
      if not segment.pivot then
        msg:reply("Pivot not selected. Use "..globals.prefix.."pivot to select it and then try again")
        return false
      end
      local emoji = getEmoji(args[1])
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      print("[REACTIONS] Adding toggle listener")
      local grabEmoji = function(reaction)
        segment.pivot.buttons[tostring(reaction.emojiId or reaction.emojiName)] = {
          type = "toggler",
          on = args[2],
          off = args[3],
        }
      end
      message:removeReaction(emoji,client.user.id)
      client:once("reactionAdd",grabEmoji)
      if not message:addReaction(emoji) then
        client:removeListener("reactionAdd",grabEmoji)
        msg:reply("Couldn't add reaction - emoji might be invalid")
        return false
      else
        return true
      end
    end
  })
plugin:add_command(toggle)
local button = command("button",{
    help = {embed={
      title = "Add a button that runs specific command when pressed",
      description = "Note: you cannot assign more than one action to a single reaction \n``$user`` gets replaced with the id of the user that interacted with the reaction.",
      fields = {
        {name = "Usage: ",value = "button <emoji> <command>"},
        {name = "Perms: ",value = "administrator"}
      }
    }},
    args = {
      "string",
      "string",
    },
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
      if not segment.pivot then
        msg:reply("Pivot not selected. Use "..globals.prefix.."pivot to select it and then try again")
        return false
      end
      local emoji = getEmoji(args[1])
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return false
      end
      print("[REACTIONS] Adding button listener")
      local grabEmoji = function(reaction)
        segment.pivot.buttons[tostring(reaction.emojiId or reaction.emojiName)] = {
          type = "button",
          on = args[2],
        }
      end
      message:removeReaction(emoji,client.user.id)
      client:once("reactionAdd",grabEmoji)
      if not message:addReaction(emoji) then
        client:removeListener("reactionAdd",grabEmoji)
        msg:reply("Couldn't add reaction - emoji might be invalid")
        return false
      else
        return true
      end
    end
  })
plugin:add_command(button)

local buttonOn = function(message,hash,userID)
  if not message then
    log("ERROR","Attempted to find a deleted message")
    return 
  end
  if segment.pivots[tostring(message.id)] and userID ~= client.user.id  then
    local current_pivot = segment.pivots[tostring(message.id)]
    if current_pivot.buttons[tostring(hash)] then
      local current_button = current_pivot.buttons[tostring(hash)]
      local new_content
      if current_button.on then
        new_content = current_button.on:gsub("%$user",userID)
      end
      if current_button.type == "role-toggler" then
        guild:getMember(userID):addRole(current_button.role)
      end
      if current_button.type == "toggler" then
        command_handler:handle(fake_message(message,{
          delete = function() end,
          content = new_content
        }))
      end
      if current_button.type == "button" then
        command_handler:handle(fake_message(message,{
          delete = function() end,
          content = new_content
        }))
      end
    end
  end
end

local buttonOff = function(message,hash,userID)
  if not message then
    log("ERROR","Attempted to find a deleted message")
    return
  end
  if segment.pivots[tostring(message.id)] and userID ~= client.user.id  then
    local current_pivot = segment.pivots[tostring(message.id)]
    if current_pivot.buttons[tostring(hash)] then
      local current_button = current_pivot.buttons[tostring(hash)]
      local new_content
      if current_button.off then
        new_content = current_button.off:gsub("%$user",userID)
      end
      if current_button.type == "role-toggler" then
        guild:getMember(userID):removeRole(current_button.role)
      end
      if current_button.type == "toggler" then
        command_handler:handle(fake_message(message,{
          delete = function() end,
          content = new_content
        }))
      end
    end
  end
end

events:on("reactionAdd",function(reaction,userID)
  local message = reaction.message
  local hash = tostring(reaction.emojiId or reaction.emojiName)
  buttonOn(message,hash,userID)
end)

events:on("reactionRemove",function(reaction,userID)
  local message = reaction.message
  local hash = tostring(reaction.emojiId or reaction.emojiName)
  buttonOff(message,hash,userID)
end)

events:on("reactionAddUncached",function(channelId,messageId,hash,userId)
  local message = client:getChannel(channelId):getMessage(messageId)
  local hash = tostring(hash)
  buttonOn(message,hash,userId)
end)

events:on("reactionRemoveUncached",function(channelId,messageId,hash,userId)
  local message = client:getChannel(channelId):getMessage(messageId)
  local hash = tostring(hash)
  buttonOff(message,hash,userId)
end)

return plugin
