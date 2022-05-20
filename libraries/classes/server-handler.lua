local class = import("classes.baseclass")
local server_handler = class("ServerHandler")
local core = import("core")
local plugin_handler = import("classes.plugin-handler")
local command_handler = import("classes.command-handler")
local file = import("file")
local eventlist = import("eventlist")
local discordia = import("discordia")

local function check_partitioning(id,...)
    args = {...}
    v = args[1]
    if type(v) == "table" and v.guild and v.guild.id == id then
        return true
    elseif not (type(v) == "table") then
        return true
    elseif type(v) == "table" and (not v.guild) and (tostring(v):find("Guild: ")) and v.id == id then
        return true
    elseif type(v) == "table" and (not v.guild) and (v.message) and (v.message.guild.id == id) then
        return true
    else
        return false
    end
end


function server_handler:__init(client,guild,options)
    assert(type(client) == "table","discordia client expected, got "..type(client))
    self.client = client
    self.uptime = discordia.Date()
    self.event_emitter = core.Emitter:new()
    self.signal_emitter = core.Emitter:new()
    self.plugin_handler = plugin_handler(self)
    self.command_handler = command_handler(self)
    self.id = guild.id
    --conifgurable properties
    self.config_path = options.path or "./servers/%id/"
    self.autosave = options.path or true
    self.autosave_frequency = options.autosave_frequency or 10
    self.plugin_search_paths = options.plugin_search_paths or {"./plugins/"}
    self.default_plugins = options.default_plugins or {"plugins"}
    self.default_prefixes = options.default_prefixes or {"&","<@"..self.client.user.id.."> "}
    self.config = {}
    self.config_path = self.config_path:gsub("%%id",self.id)
    self:load_config()
    self.config["prefix"] = self.config["prefix"] or self.default_prefixes[1] or "(missing prefix)"
    self.message_counter = 0
    if self.autosave then
        self.client:on("messageCreate",function(msg)
            self.message_counter = self.message_counter + 1
            if math.fmod(self.message_counter,self.autosave_frequency) == 0 then
                self:save_config()
            end
        end)
    end
    if not file.existsDir(self.config_path) then
        os.execute("mkdir -p "..self.config_path)
    end
    for k,v in pairs(eventlist) do
        self.client:on(v,function(...)
            --check if the event is for this server, and then emit.
            if check_partitioning(self.id,...) then
                self.event_emitter:emit(v,...)
            end
        end)
    end
    self.client:on("messageCreate",function(msg)
        if msg.guild and msg.guild.id == self.id then
            self.command_handler:handle(msg)
        end
    end)
    for _,path in pairs(self.plugin_search_paths) do
        self.plugin_handler:add_plugin_folder(path)
    end
    self.plugin_handler:update_plugin_info()
    for _,plugin_name in pairs(self.default_plugins) do
        print("[SERVER] Loading plugin: "..tostring(plugin_name).." - ", self.plugin_handler:load(plugin_name))
    end
    for _,prefix in pairs(self.default_prefixes) do
        self.command_handler:add_prefix(prefix)
    end
end

function server_handler:load_config(path)
    print("[SERVER] Loading config")
    if path then
        self.config = file.readJSON(path,{})
    else
        self.config = file.readJSON(self.config_path.."config.json")
    end
    self.event_emitter:emit("serverLoadConfig",self.config)
end

function server_handler:save_config(path)
    print("[SERVER] Saving config")
    if path then
        file.writeJSON(path,self.config)
    else
        file.writeJSON(self.config_path.."config.json",self.config)
    end
    self.event_emitter:emit("serverSaveConfig",self.config)
end
return server_handler
