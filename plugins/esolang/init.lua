local brainfuck = require("esolangs.brainfuck")
local befunge = require("esolangs.befunge")
local plugin_class = import("classes.plugin")
local command = import("classes.command")
local plugin = plugin_class()
local settings = {
    tapesize = 30000,
    cellsize = 1,
    debug = true,
    limit = 500000
}
c_brainfuck = command("brainfuck",{
        args = {
            "string"
        },
        exec = function(msg,args,opts)
            settings.load_extensions = {}
            settings.path = "./lib/brainfuck/"
            local instance = brainfuck.new(args[1],settings)
            local result,opcount,err = instance:run(args[2] or "")
            if result == "" then
                result = ""
            end
            if not err then
                if opts["o"] or opts["output-only"] then
                    msg:reply(tostring(result):gsub("@","\\@"))
                else
                    msg:reply({ embed = {
                        title = "Result:",
                        color = discordia.Color.fromHex("#32cd32").value,
                        description = "```"..tostring(result):gsub("`","\\`").." ```",
                        footer = {
                         text = "Finished in "..opcount.." operations"
                        }
                    }})
                end
            else
                msg:reply({
                    embed = {
                        title = "Error:",
                        description = "```"..tostring(err).." ```",
                        color = discordia.Color.fromHex("#32cd32").value,
                    }
                })
            end
        end
})
plugin:add_command(c_brainfuck)
c_befunge = command("befunge",{
        args = {
            "string"
        },
        exec = function(msg,args,opts)
            local code = msg.content:match("```(.+)```")
            if not code then
                msg:reply("Invalid syntax")
                return
            end
            local input = msg.content:match("```.+``` ?(.+)") or ""
            local stdout = ""
            local stderr = ""
            befunge:init(code,{
                opcount = 10000,
                handle_int_input = function()
                    local int = input:match("^%d+")
                    if not int then
                        return
                    end
                    input = input:gsub("^%d+","",1)
                    return tonumber(int)
                end,
                handle_input = function()
                    local char = input:sub(1,1)
                    if not char then
                        return
                    end
                    input = input:sub(2,-1)
                    return string.byte(char)
                end,
                handle_output = function(char)
                    stdout = stdout..char
                end,
                handle_warning = function(warn)
                    stderr = stderr.."[warning] "..warn.."\n"
                end,
                handle_error = function(error)
                    stderr = stderr.."[error] "..error.."\n"
                    befunge.interpreter_state = false
                end
            })
            local opcount = befunge:run()
            if opts["o"] or opts["output-only"] then
                msg:reply(tostring(stdout):gsub("@","\\@"))
            else
                msg:reply({embed = {
                    title = "Result: ",
                    color = discordia.Color.fromHex("#32cd32").value,
                    fields = {
                        {name = "out",value = "```"..stdout:gsub("`","\\`").." ```"},
                        {name = "err",value = "```"..stderr.." ```"}
                    },
                    footer = {
                        text = "Finished in "..opcount.." operations"
                    }
                }})
            end
        end
})
plugin:add_command(c_befunge)
plugin:load_helpdb(plugin_path.."help.lua")
return plugin
