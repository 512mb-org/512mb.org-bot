local aliases = {}
local command = import("classes.command")
local plugin = import("classes.plugin")("scc")
local sql = import("sqlite3")
local db = sql.open(server.config_path.."scc.sqlite")
local cache = {
    users = {},
    rules = {},
    usermsg = {}
}

if not db:rowexec("SELECT name FROM sqlite_master WHERE type='table' AND name='score'") then
    db:exec [[
CREATE TABLE score(user TEXT PRIMARY KEY, score INTEGER);
CREATE TABLE rules(rulename TEXT NOT NULL PRIMARY KEY, value TEXT);
INSERT INTO rules VALUES("bump", 50);
INSERT INTO rules VALUES("message", 5);
INSERT INTO rules VALUES("bumpchannel","0");
INSERT INTO rules VALUES("bumpbot","0");
]]
end

local update_entry = db:prepare([[INSERT INTO score VALUES(?, ?) ON CONFLICT(user) DO UPDATE SET score = ?]])
local update_rules = db:prepare([[UPDATE rules SET value = ? WHERE rulename = ?]])
local get_rule = db:prepare("SELECT value FROM rules WHERE rulename = ?")
cache.rules.message = tonumber(get_rule:reset():bind("message"):step()[1])
cache.rules.bump = tonumber(get_rule:reset():bind("bump"):step()[1])
cache.rules.bumpchannel = get_rule:reset():bind("bumpchannel"):step()[1]
cache.rules.bumpbot = get_rule:reset():bind("bumpbot"):step()[1]
local score_init = db:exec("SELECT * FROM score;")
if score_init then
    for id,uid in ipairs(score_init.user) do
        cache.users[uid] = tonumber(score_init.score[id])
    end
end

local timer = discordia.Clock()
timer:on("min", function() 
    if os.date("*t")["min"]%5 == 0 then
        log("SCC","Saving SCC data")
        for uname,uscore in pairs(cache.users) do
            update_entry:reset():bind(uname,uscore,uscore):step()
        end
    end
end)
timer:start(true)

events:on("typingStart",function(userid,channelid)
    if cache.rules.bumpchannel == tostring(channelid) then
        cache.last_typing_user = userid
    end
end)

events:on("messageCreate",function(msg)
    if (not msg.author.bot) and 
       msg.content and
       (msg.content:len() > 10) then
        local stripped_content = msg.content:match("^%s*(.-)%s*$")
        if not (stripped_content == cache.usermsg[msg.author.id]) then
            cache.users[msg.author.id] = (cache.users[msg.author.id] or 0) +
                cache.rules.message
        end
        cache.usermsg[msg.author.id] = stripped_content
    end
    if msg.author.bot and (msg.author.id == tostring(cache.rules.bumpbot)) then
        if cache.last_typing_user and msg.embed and msg.embed.description and msg.embed.description:match("Bump done") then
            cache.users[cache.last_typing_user] = (cache.users[cache.last_typing_user] or 0) + cache.rules.bump
        end
    end
end)

local c_sccrules = command("scc-rules", {
    category = "Utilities",
    perms = {
        "administrator"
    },
    exec = function(msg,args,opts)
        if not args[1] then
            msg:reply({embed = {
                title = "Current score rules: ",
                fields = {
                    { name = "message", value = tostring(cache.rules.message) },
                    { name = "bump", value = tostring(cache.rules.bump) },
                    { name = "bumpbot", value = tostring(cache.rules.bumpbot) },
                    { name = "bumpchannel", value = tostring(cache.rules.bumpchannel) }
                }
            }})
        else
            local valid_params = {
                message = tonumber,
                bump = tonumber,
                bumpchannel = tostring,
                bumpbot = tostring
            }
            if valid_params[args[1]] then
                if valid_params[args[1]](args[2]) then
                    local value = valid_params[args[1]](args[2])
                    cache.rules[args[1]] = value
                    update_rules:reset():bind(args[2],args[1]):step()
                else
                    msg:reply("Invalid parameter: "..tostring(args[2]))
                    return false
                end
            else
                msg:reply("Invalid rule name: "..tostring(args[1]))
                return false
            end
            return true
        end
    end
})
plugin:add_command(c_sccrules)

local c_sccscore = command("scc-score", {
    category = "Utilities",
    exec = function(msg,args,opts)
        if not args[1] then
            msg:reply({embed = {
                title="Your score: "..tostring(cache.users[msg.author.id] or 0),
                color = discordia.Color.fromHex("2FC02A").value
            }})
        else
            local user = msg.guild:getMember(args[1]:match("^%d*"))
            if not user then
                msg:reply("Invalid user")
                return false
            end
            msg:reply({embed={
                title = tostring(user.name).."'s score: "..tostring(cache.users[user] or 0),
                color = discordia.Color.fromHex("2FC02A").value
            }})
        end
    end
})
plugin:add_command(c_sccscore)

plugin.removal_callback = function()
    for uname,uscore in pairs(cache.users) do
        update_entry:reset():bind(uname,uscore,uscore):step()
    end
end

local helpdb = import(plugin_path:sub(3,-1).."help")
plugin:for_all_commands(function(command)
    if helpdb[command.name] then
        command:set_help(helpdb[command.name])
    end
end)

return plugin
