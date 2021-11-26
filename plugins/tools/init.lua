local plugin_class = import("classes.plugin")
local command = import("classes.command")
local plugin = plugin_class()
local markov = require("markov")
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
		help = "Simulates a dice throw, prints the value of each die",
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
		help = "Draw a specific amount of playing cards and display them",
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
		help = "Calculate maths using lua's interpeter. Math functions from C included, use ``sin(x)`` or ``cos(x)`` for example. Additionally, BitOp module is included with the name ``bit`` (example: ``bit.bnot(1,1)``)",
        usage = [[
calculate <expression>
``--bit``; ``-b`` - if the output is a number, convert it to binary
``--hex``; ``-h`` - if the output is a number, convert it to hexadecimal
		]],
		args = {
			"string"
		},
		exec = function(msg,args,opts)
			local calculation_coroutine = coroutine.wrap(function()
				local sandbox = {}
				sandbox = safe_clone(math,{randomseed = true})
				sandbox["bit"] = safe_clone(bit,{})
				local expression = (table.concat(args," ") or "")
				local exception_keywords = { --this causes too much trouble
					"while",
					"function",
					"for",
					"if",
					"then",
					"do",
					"end",
					"repeat",
					"until"
				}
				for k,v in pairs(exception_keywords) do
					if expression:find("%W"..v.."%W") then
						msg:reply("Invalid syntax")
						return
					end
				end
				local state,answer = pcall(load("return "..expression,"calc","t",setmetatable(sandbox,{})))
				if state then
					if type(answer) == "number" then
						if opts["bit"] or opts["b"] then
							answer = "0b"..to_bit_string(answer)
						elseif opts["hex"] or opts["h"] then
							answer = "0x"..bit.tohex(answer)
						end
					end
					msg:reply(tostring(answer))
				else
					msg:reply(answer)
				end
			end)
			calculation_coroutine()
		end,
})
plugin:add_command(calculate)
local pfp = command("pfp",{
		help = "Show the profile picture of a user, or if none is specified, of yourself",
        usage = "pfp <user or none>",
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
		help = "Generate some text using markov chains",
        usage = "markov <text to start with>",[[
--preset=<preset> - Select a text preset. Currently available:
``default`` - Generated from a wikipedia page on markov chains
``freud`` - The largest one, generated from a page on Sigmund Freud
``reddit`` - Generated from reddit comments
``travisscott`` - Generated from transcript of a video by PlasticPills on travis scott burger
]],
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
		help = "Convert JSON objects into embeds",
		usage = "If you've worked with discord.js before, this might be simple. If you haven't, then check out https://github.com/yessiest/SuppaBot/wiki/Embeds",
		args = {
			"string"
		},
		exec = function(msg,args,opts)
			local embed = msg.content:match("{.+}")
			if not embed then
				msg:reply("Invalid embed object")
				return
			end
			local embed_obj,code,err = require("json").decode(embed)
			if not embed_obj then
				msg:reply("Error while decoding JSON object: "..tostring(err))
				return
			end
			embed_obj.color = discordia.Color.fromHex(embed_obj.color).value
			msg:reply({embed = embed_obj})
		end
})
plugin:add_command(embed)
return plugin
