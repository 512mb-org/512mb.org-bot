local class = import("classes.baseclass")
local plugin = class("Plugin")

function plugin:__init()
    self.command_pool = {}
    self.config = {}
end

function plugin:load(environment)
    self.command_handler = environment.server.command_handler
    for k,v in pairs(self.command_pool) do
        self.command_handler:add_command(v)
    end
end

function plugin:unload()
    if self.removal_callback then
        self.removal_callback()
    end
    for k,v in pairs(self.command_pool) do
        self.command_handler:remove_command(v)
    end
end

function plugin:for_all_commands(fn)
    assert(type(fn)=="function","function expected, got "..type(fn))
    for k,v in pairs(self.command_pool) do
        fn(v)
    end
end

function plugin:for_every_new_command(fn)
    assert(type(fn)=="function","function expected, got "..type(fn))
    self.decorator = fn
end

function plugin:add_command(command_object)
    if self.decorator then
        self.fn(command_object)
    end
    command_object.parent = self
    self.command_pool[command_object] = command_object
    --in post init state: we request the command handler to add the commands
    --that way, we can link our plugin back to the command handler
    if self.command_handler then
        self.command_handler:add_command(command_object)
    end
end

function plugin:remove_command(command_object)
    if self.command_pool[command_object] then
        self.command_pool[command_object] = nil
    end
    --remove command after post-init state
    if self.command_handler then
        self.command_handler:remove_command(command_object)
    end
end
return plugin
