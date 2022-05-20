--This class manages the loading, unloading, scanning and event manipulation for plugin objects
--This class requries communication between itself and the command handler
--in order to load commands.
--Remember: there can only be one command handler and plugin handler
--per a server handler. Side effects of using multiple command handlers and
--plugin handlers are unknown.
local class = import("classes.baseclass")
local plugin_handler = class("PluginHandler")
local file = import("file")
local json = import("json")
local core = import("core")
local emitter_proxy = import("classes.emitter-proxy")
local table_utils = import("table-utils") 
function plugin_handler:__init(parent_server)
    assert(parent_server,"server handler to assign the plugin handler to has not been provided")
    self.server_handler = parent_server
    self.plugins = {}
    self.plugin_info = {}
    self.plugin_paths = {}
    self.server_handler.event_emitter:on("serverSaveConfig",function()
        print("[SERVER] Saving plugins configs")
        for name,plugin in pairs(self.plugins) do
            self:save_plugin_config(name)
        end
    end)
end

function plugin_handler:load_plugin_config(name)
    return file.readJSON(self.server_handler.config_path..name..".json",{})
end

function plugin_handler:save_plugin_config(name)
    if self.plugins[name] then
        file.writeJSON(self.server_handler.config_path..name..".json",self.plugins[name].__env.config)
    end
end

function plugin_handler:add_plugin_folder(path)
    assert(type(path) == "string","path should be a string, got "..type(path))
    table.insert(self.plugin_paths,path)
end

function plugin_handler:scan_folder(path)
    local file = io.open(path.."/meta.json","r")
    if file then
        local metadata,code,err = json.decode(file:read("*a"))
        if metadata and metadata.name then
            self.plugin_info[metadata.name] = metadata
            self.plugin_info[metadata.name].path = path.."/"
            self.plugin_info[metadata.name].loaded = false
        end
        file:close()
    else
        for k,v in pairs({"/init.lua","/main.lua"}) do
            local file = io.open(path..v,"r")
            if file then
                local name = path:match("[^/]+$")
                self.plugin_info[name] = {["main"]=v:gsub("/","")}
                self.plugin_info[name].path = path.."/"
                self.plugin_info[name].loaded = false
                file:close()
            end
        end
    end
end

function plugin_handler:update_plugin_info()
    for k,v in pairs(self.plugin_paths) do
        if file.existsDir(v) then
            file.ls(v):gsub("[^\n]+",function(c)
                self:scan_folder(v..c)
            end)
        end
    end
end

function plugin_handler:list_loadable()
    return table_utils.deepcopy(self.plugin_info)
end

function plugin_handler:load(name)
    if not self.plugin_info[name] then
        return false, "No such plugin"
    end
    if not self.plugin_info[name].main then
        return false, "Plugin metadata entry doesn't specify the main file path or main file isn't found"
    end
    if self.plugin_info[name].loaded then
        return false, "Plugin is already loaded"
    end
    local environment = setmetatable({
        id = self.server_handler.id,
        globals = self.server_handler.config,
        signals = emitter_proxy(self.server_handler.signal_emitter),
        client = self.server_handler.client,
        events = emitter_proxy(self.server_handler.event_emitter),
        discordia = import("discordia"),
        server = self.server_handler,
        command_handler = self.server_handler.command_handler,
        plugin_handler = self.server_handler.plugin_handler,
        log = function() end,
        config = self:load_plugin_config(name),
        import = import,
    },{__index = _G})
    local plugin_meta = self.plugin_info[name]
    if file.exists(plugin_meta.path..plugin_meta.main) then
        environment["plugin_path"] = plugin_meta.path
        local plugin_content = file.read(plugin_meta.path..plugin_meta.main,"*a")
        local plugin_loader,err = load(plugin_content,"plugin loader: "..plugin_meta.path..plugin_meta.main,nil,environment)
        if plugin_loader then
            local plugin_object = plugin_loader()
            if plugin_object then
                plugin_object.name = name
                plugin_object:load(environment)
                self.plugins[name] = plugin_object
                self.plugins[name].__env = environment
                self.plugin_info[name].loaded = true
                return true
            else
                return false, "Plugin object missing"
            end
        else
            return false, err
        end
    else
        return false, "File specified as the main file is inaccessible"
    end
end 

function plugin_handler:unload(name)
    if self.plugins[name] then
        self.plugins[name].__env.signals:destroy()
        self.plugins[name].__env.events:destroy()
        self.plugins[name]:unload()
        self.plugin_info[name].loaded = false
        return true
    else 
        return false,"Plugin is not loaded"
    end
end
return plugin_handler
