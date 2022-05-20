--This class acts as a pipe between the incoming messages and commands.
--It observes the content of the incoming messages, and, depending on the optional flags,
--executes specific commands
--Remember: there can only be one command handler and plugin handler
--per a server handler. Side effects of using multiple command handlers and
--plugin handlers are unknown.
local class = import("classes.baseclass")
local command_handler = class("Command-handler")
local table_utils = import("table-utils")
local purify = import("purify")
function command_handler:__init(parent_server)
    self.server_handler = assert(parent_server,"parent server handler not provided")
    self.command_pool = {}
    self.prefixes = {}
    self.command_meta = {
        plugins = {},
        categories = {}
    }
end
function command_handler:add_prefix(prefix)
    local purified_prefix = purify.purify_escapes(prefix)
    self.prefixes[purified_prefix] = purified_prefix
    return true
end
function command_handler:remove_prefix(prefix)
    local purified_prefix = purify.purify_escapes(prefix)
    if self.prefixes[purified_prefix] or table_utils.count(self.prefixes) <= 1 then
        self.prefix[purified_prefix] = nil
        return true
    else 
        return false, (
                (self.prefixes[purified_prefix] and "No such prefix") or
                "Cannot remove the last remaining prefix"
                )
    end
end
function command_handler:get_prefixes()
    return table_utils.deepcopy(self.prefixes)
end
function command_handler:add_command(command)
    assert(type(command) == "table","command object expected")
    local purified_name = purify.purify_escapes(command.name)
    self.command_pool[purified_name] = command
    if not self.command_meta.plugins[command.parent.name] then
        self.command_meta.plugins[command.parent.name] = {} 
    end
    if not self.command_meta.categories[command.options.category] then
        self.command_meta.categories[command.options.category] = {}
    end
    table.insert(self.command_meta.categories[command.options.category],command.name)
    table.insert(self.command_meta.plugins[command.parent.name],command.name)
    return command
end
function command_handler:remove_command(command)
    assert(type(command) == "table","command object expected")
    local purified_name = purify.purify_escapes(command.name)
    if self.command_pool[purified_name] then
        local command = self.command_pool[purified_name]
        --not exactly optimal, but lists are lists. can't do much about them.
        table_utils.remove_value(self.command_meta.plugins[command.parent.name],command.name)
        if #self.command_meta.plugins[command.parent.name] == 0 then
                self.command_meta.plugins[command.parent.name] = nil
        end
        table_utils.remove_value(self.command_meta.categories[command.options.category],command.name)
        if #self.command_meta.categories[command.options.category] == 0 then
                self.command_meta.categories[command.options.category] = nil
        end
        self.command_pool[purified_name] = nil
        return true
    else 
        return false
    end
end
function command_handler:get_command(name)
    local purified_name = purify.purify_escapes(assert(type(name) == "string") and name)
    if self.command_pool[purified_name] then 
        return self.command_pool[purified_name]
    else
        return false
    end
end
function command_handler:get_commands(name)
    local list = {}
    for k,v in pairs(self.command_pool) do
        table.insert(list,k)
    end
    return list
end
function command_handler:get_commands_metadata()
    return table_utils.deepcopy(self.command_meta)
end
function command_handler:handle(message)
        for name,command in pairs(self.command_pool) do
        if command.options.regex then
            if message.content:match(command.options.regex) then
                command:exec(message)
                return
            end
        else
            if command.options.prefix then
                for _,prefix in pairs(self.prefixes) do
                    if message.content:match("^"..prefix..name.."$") or message.content:match("^"..prefix..name.."%s") then
                        command:exec(message)
                        return
                    end
                end
            else
                if message.content:match("^"..name.."$") or message.content:match("^"..name.."%s") then
                    command:exec(message)
                    return
                end
            end
        end
    end
end
return command_handler
