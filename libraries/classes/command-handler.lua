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
    self.pool = {}
    self.prefixes = {}
    self.meta = {
        plugins = {},
        categories = {}
    }
end
function command_handler:add_prefix(prefix)
    self.prefixes[prefix] = purify.purify_escapes(prefix)
    return true
end
function command_handler:remove_prefix(prefix)
    if self.prefixes[prefix] and table_utils.count(self.prefixes) > 1 then
        self.prefixes[prefix] = nil
        return true
    end
    if not self.prefixes[prefix] then
        return false, "Prefix not found"
    end
    return false, "Cannot remove last remaining prefix!"
end
function command_handler:get_prefixes()
    return table_utils.deepcopy(self.prefixes)
end
function command_handler:add_command(command)
    assert(type(command) == "table","command object expected")
    if self.pool[command.name] then
        return false, "Already have a command with the same name"
    end
    self.pool[command.name] = command
    if not self.meta.plugins[command.parent.name] then
        self.meta.plugins[command.parent.name] = {}
    end
    self.meta.plugins[command.parent.name][command.name] = command.name
    if not self.meta.categories[command.category] then
        self.meta.categories[command.category] = {}
    end
    self.meta.categories[command.category][command.name] = command.name
    return command
end
function command_handler:remove_command(command)
    assert(type(command) == "table","command object expected")
    if not self.pool[command.name] then
        return false
    end
    self.pool[command.name] = nil
    self.meta.categories[command.category][command.name] = nil
    self.meta.plugins[command.parent.name][command.name] = nil
end
function command_handler:get_command(name)
    return self.pool[name] 
end
function command_handler:get_commands(name)
    local list = {}
    for k,v in pairs(self.pool) do
        table.insert(list,k)
    end
    return list
end
function command_handler:get_metadata()
    local plugins,categories = {},{}
    for k,v in pairs(self.meta.plugins) do
        plugins[k] = table_utils.listcopy(v)
    end
    for k,v in pairs(self.meta.categories) do
        categories[k] = table_utils.listcopy(v)
    end 
    return {
        plugins = plugins,
        categories = categories
    }
end
function command_handler:handle(message,ignore_flag)
    local content = message.content
    local prefix = ""
    local command
    for k,v in pairs(self.prefixes) do
        if content:match("^"..v) then
            prefix = k
        end
    end
    command = content:sub(prefix:len()+1,-1):match("^[%-_%w]+")
    if self.pool[command] then
        if (prefix == "") and self.pool[command].options.prefix == false then
            self.pool[command]:exec(message,ignore_flag)
        elseif (prefix ~= "") and self.pool[command].options.prefix == true then
            self.pool[command]:exec(message,ignore_flag)
        end
    end
end
return command_handler
