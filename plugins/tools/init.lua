local plugin_class = import("classes.plugin")
local command = import("classes.command")
local plugin = plugin_class()
local markov = require("markov")
local qalculator = require("libqalculator")
local markov_instance = markov.new()
math.randomseed(os.time()+os.clock())

local safe_clone = function(tab,disallow)
	local new_tab = {}
	for k,v in pairs(tab) do
		if not disallow[k] then
			new_tab[k] = v
		end
	end
	return new_tab
end

function to_bit_string(num)
    local t=""
		local rest
    while num>0 do
        rest=math.fmod(num,2)
        t=t..rest
        num=(num-rest)/2
    end
    return t:reverse()
end

local flip = command("flip",{
    category = "Miscellaneous",
	help = "Flips a coin, obv.",
    usage = "flip",
	exec = function(msg,args,opts)
		local coin = math.random(1,100)%2
		if coin > 0 then
			msg:reply("Heads")
		else
			msg:reply("Tails")
		end
	end,
})
plugin:add_command(flip)
local dice = command("dice",{
    category = "Miscellaneous",
    usage = "dice <2d6,d30,d20+4,etc>",
	exec = function(msg,args,opts)
		local out = {embed = {
			fields = {},
			footer = {
				text = 0
			}
		}}
		for I = 1,#args do
			local v = args[I]
            for J = 1,(v:match("(%d+)d%d+") or 1) do
                local value = math.random(1,tonumber(v:match("d(%d+)")))
    			if v:find("d%d+[%+%-]%d+") then
                    if v:match("d%d+([%+%-])") == "+" then
	    			    value = value + tonumber(v:match("d%d+[%+%-](%d+)"))
                    else
                        value = value - tonumber(v:match("d%d+[%+%-](%d+)"))
                    end
		    	end
			    out.embed.fields[#out.embed.fields+1] = {name = "d"..v:match("d(%d+)"),value = value,  inline = true}
			    out.embed.footer.text = out.embed.footer.text+value
	    		if #out.embed.fields >= 25 then
		    		break
			    end
		    end
	    	if #out.embed.fields >= 25 then
		   		break
		    end
        end
		out.embed.footer.text = "Total: "..out.embed.footer.text
		msg:reply(out)
    end,
})
plugin:add_command(dice)
local cards = command("cards",{
    category = "Miscellaneous",
    usage = "cards <amount>",
	args = {"number"},
	exec = function(msg,args,opts)
		local out = {embed = {
			fields = {}
		}}
		local random = math.random
		for I = 1,(args[1] < 25 and args[1]) or 25 do
			local suits = {"spades","clubs","diamonds","hearts"}
			local values = {
				"A","1","2","3","4","5",
				"6","7","8","9","J","Q","K"
			}
			out.embed.fields[I] = {name = "card", value = " :"..suits[random(1,4)]..":"..values[random(1,11)].." ",inline = true}
		end
		msg:reply(out)
	end,
})
plugin:add_command(cards)
local calculate = command("calculate",{
    category = "Miscellaneous",
	args = {
		"string"
	},
	exec = function(msg,args,opts)
        local e,i,f = opts["e"],opts["i"],opts["f"]
        local result = {embed = {
            title = "Result",
            fields = {
                {name = "Value: ",value = nil},
            },
            footer = {
                text = "Powered by libqalculate"
            },
            color = discordia.Color.fromHex("7A365F").value
        }}
        local value,err = qalculator.qalc(table.concat(args," "),e,i,f)
        result.embed.fields[1].value = "```"..value.."```"
        if opts["o"] then
            msg:reply(value)
            return
        end
        if #err > 0 then
            result.embed.fields[2] = {
                name = "Messages: ",
                value = "```"..table.concat(err,"\n").."```"
            }
        end
        msg:reply(result)
	end,
})
plugin:add_command(calculate)
local pfp = command("pfp",{
    category = "Miscellaneous",
	exec = function(msg,args,opts)
		local user = client:getUser((args[1] or ""):match("%d+"))
		if user then
			msg:reply(user:getAvatarURL().."?size=2048")
		else
			msg:reply(msg.author:getAvatarURL().."?size=2048")
		end
	end,
})
plugin:add_command(pfp)
local markov = command("markov",{
    category = "Miscellaneous",
	exec = function(msg,args,opts)
		local preset,code,err = import("file").readJSON("./resources/"..(opts["preset"] or "default"):match("%w+")..".json",{system_failed = true})
		if preset.system_failed then
			msg:reply("No such preset")
			return
		end
		markov_instance:load_state(preset)
		local output = markov_instance:run("The",100)
		msg:reply(output)
	end
})
plugin:add_command(markov)
local embed = command("embed",{
    category = "Miscellaneous",
	args = {
		"string"
	},
	exec = function(msg,args,opts)
		local embed = msg.content:match("{.+}")
		if not embed then
			msg:reply("Invalid embed object")
			return
		end
		local embed_obj,code,err = import("json").decode(embed)
		if not embed_obj then
			msg:reply("Error while decoding JSON object: "..tostring(err))
			return
		end
        if pcall(discordia.Color.fromHex,embed_obj.color) then
			embed_obj.color = discordia.Color.fromHex(embed_obj.color).value
        end
		msg:reply({embed = embed_obj})
	end
})
plugin:add_command(embed)
plugin:load_helpdb(plugin_path.."help.lua")
return plugin
