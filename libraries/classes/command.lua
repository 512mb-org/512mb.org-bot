--[[
This class handles command management.
]]
local table_utils = import("table-utils")
local class = import("classes.baseclass")
local command = class("Command")
local acl = import("classes.command-acl")
function command:__init(name,callback)
  self.rules = acl()
  self.name = name
  self.timer = os.time()
  self.options = {
    allow_bots = false, --allow bots to execute the command
    typing_decorator = false, --set if the bot should be "typing" while the command executes
    prefix = true, --if true and if regex isn't enabled, check for prefix at the start. if not, don't check for prefix
    regex = false, --check if the message matches this regular expression (should be a string)
    no_parsing = false, --check if you want to disable the message argument parsing process
    timeout = 1000, --set the timeout for a command
  }
  if type(callback) == "table" then
    for k,v in pairs(callback.options or {}) do 
        self.options[k] = v
    end
    self.callback = callback.exec
    self.args = callback.args or self.args
    if callback.users then
      for k,v in pairs(callback.users) do
        self.rules:set_user_rule(k,v)
      end
    end
    if callback.roles then
      for k,v in pairs(callback.roles) do
        self.rules:set_group_rule(k,v)
      end
    end
    if callback.perm then
      self.rules:set_perm_rules(callback.perm)
    end
    if callback.help then
      self:set_help(callback.help,callback.usage)
    end
  elseif type(callback) == "function" then
    self.callback = callback
  end
end
--set the callback to be called on comm:exec(msg)
function command:set_callback(fn)
  assert(type(fn) == "function","function expected, got "..type(fn))
  self.callback = fn
  return self
end
--generate help using only description and usage, or nothing at all
function command:generate_help(description,usage)
  assert(not description or (type(description) == "string"),"Description should be either string or nil, got "..type(description))
  assert(not usage or (type(usage) == "string"),"Usage should be either string or nil, got "..type(usage))
  local backup_usage_str
  if self.args then
    backup_usage_str = self.name.." <"..table.concat(self.args,"> <")..">"
  else
    backup_usage_str = "not defined"
  end
  local permissions = table.concat(self.rules:export_snapshot()["perms"] or {},"\n")
  if permissions == "" then
    permissions = "All"
  end
  self.help = {embed = {
    title = "Help for ``"..self.name.."``",
    description = description,
    fields = {
      {name = "Usage: ",value = usage or backup_usage_str},
      {name = "Perms: ",value = permissions}
    }
  }}
  return self
end
--set the help message to be sent
function command:set_help(obj,usage)
  if type(obj) == "string" then
    self:generate_help(obj,usage)
  elseif type(obj) == "table" then
    self.help = obj
  else
    error("Type "..type(obj).." cannot be set as a help message")
  end
  return self
end
--print the help message, or generate it if there is none
function command:get_help()
  if not self.help then
    self:generate_help("Description not defined")
  end
  return self.help
end
function command:set_timeout_callback(fn)
  assert(type(fn) == "function","function expected, got "..type(fn))
  self.timeout_callback = fn
  return self
end

--check the permissions for command
function command:check_permissions(message)
  if message.author.bot and (not self.options.allow_bots) then
    return false
  end
  if discordia.Date():toMilliseconds()-self.options.timeout < self.timer then
    if self.timeout_callback then
      self.timeout_callback(fn)
      return false
    end
  end
  self.timer = discordia.Date():toMilliseconds()
  if self.rules:check_user(message.author.id) then
    local found,allow = self.rules:check_user(message.author.id)
    return allow
  end
  if self.rules:check_group(message.member.roles) then
    local found,allow = self.rules:check_group(message.member.roles)
    return allow
  end
  return self.rules:check_perm(message.member:getPermissions(message.channel))
end
--the main entry point for the command - execute the callback within after
--multiple checks
function command:exec(message,args,opts)
  local exec = self.callback
  if not self.callback then
    error("Callback not set for command "..self.name)
  end
  if self.decorator then
    self.callback = self.decorator(self.callback)
  end
  local content
  if self.options.regex then
    content = message.content
  else
    local strstart,strend = message.content:find(self.name,1,true)
    content = message.content:sub(strend+1,-1)
  end
  if self:check_permissions(message) then
    local status,args,opts,err = import("air").parse(content,self.args,message.client,message.guild.id)
    if status then
      self.callback(message,args,opts)
    else
      msg:reply(err)
    end
  end
end
--add decorators for the callback
function command:set_decorator(fn)
  assert(type(fn) == "function","a decorator function expected, got "..type(fn))
  self.decorator = fn
  return self
end
--get a list of all properties of the command
function command:get_properties()
  return {
    name = self.name,
    args = table_utils.deepcopy(self.args),
    help = table_utils.deepcopy(self.help),
    prefix = self.prefix
  }
end
return command
