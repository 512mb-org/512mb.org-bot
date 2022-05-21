--[[
This class handles command management.
]]
local table_utils = import("table-utils")
local class = import("classes.baseclass")
local command = class("Command")
local acl = import("classes.command-acl")
local discordia = import("discordia")
function command:__init(name,callback)
    assert(name:match("^[-_%w]+$"),"Name can only contain alphanumeric characters, underscores or dashes")
    self.rules = acl()
    self.name = name
    self.timer = discordia.Date():toMilliseconds()
    self.category = "None"
    self.options = {
        allow_bots = false, --allow bots to execute the command
        typing_decorator = false, --set if the bot should be "typing" while the command executes
        prefix = true, --if true check for prefix at the start. if not, don't check for prefix
        timeout = 1000, --set the timeout for a command
    }
    if type(callback) == "table" then
        for k,v in pairs(callback.options or {}) do 
            self.options[k] = v
        end
        self.callback = callback.exec
        if callback.category then
            self.category = callback.category
        end
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
        callback.perms = callback.perms and self.rules:set_perm_rules(callback.perms)
        callback.help = callback.help and self:set_help(callback.help,callback.usage)
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
    local permissions = table.concat(self.rules:export_snapshot()["perms"] or {"All"},"\n")
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
    if type(obj) == "table" then
        self.help = obj
    else
        self:generate_help(obj,
                (type(usage) == "string" and usage)
        or "No description provided.")
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
function command:check_permissions(message,special_flag)
    local ctime = discordia.Date():toMilliseconds()
    if (ctime-self.options.timeout < self.timer) and (not ignore_flag) then
        if self.timeout_callback then
            self.timeout_callback(message)
        end
        return false
    end
    self.timer = discordia.Date():toMilliseconds()
    -- user rules first, group second, permission rules last
    if ignore_flag == 2 then
        return true
    end
    local User, allowUser = self.rules:check_user(tostring(message.author.id))
    local Group, allowGroup = self.rules:check_group(message.member.highestRole)
    if User then
        return allowUser
    end
    if Group then
        return allowGroup
    end
    return self.rules:check_perm(message.member:getPermissions(message.channel))
end
--the main entry point for the command - execute the callback within after
--multiple checks
function command:exec(message,ignore_flag)
    if message.author.bot and (not self.options.allow_bots) then
        return false
    end
    if self:check_permissions(message,ignore_flag) then
        local exec = self.callback
        if not self.callback then
            error("Callback not set for command "..self.name)
        end 
        if self.decorator then
            self.callback = self.decorator(self.callback)
        end
        local strstart,strend = message.content:find(self.name,1,true)
        content = message.content:sub(strend+1,-1)
        if self.options.typing_decorator then
            message.channel:broadcastTyping()
        end
        local status,args,opts,err = import("air").parse(content,self.args,message.client,message.guild.id)
        if status then
            local callst,status,response = pcall(self.callback,message,args,opts)
            if callst then
                if type(status) == "boolean" then
                    message:addReaction((status and "✅") or "❌")
                end
                return
            end
            message:addReaction("⚠️")
            message:reply("An internal error occured: "..status)
            return
        end
        message:addReaction("❌")
        message:reply(err)
        return
    end
    message:addReaction("❌")
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
        category = self.options.category,
        args = table_utils.deepcopy(self.args),
        help = table_utils.deepcopy(self.help),
        prefix = self.prefix
    }
end
return command
