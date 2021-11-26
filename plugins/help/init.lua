local pluginc = import("classes.plugin")
local command = import("classes.command")
local plugin = pluginc("help")
math.randomseed(os.time()+os.clock())
local help_message
local function randomize_stuff()
  local chance = math.random(1,100)
  if chance < 10 then
    help_message = [[
This button here, builds Teleporters. This button, builds Dispensers.
And this little button makes them enemy sum-bitches wish they'd never been born!

--the inspiration behind this bot's design    ]]
  elseif chance >= 10 and chance < 90 then
    help_message = [[
This plugin provides the help command, which can view help messages for plugins and commands
    ]]
  else 
    help_message = [[
see the invisible 
do the impossible
row row
fight da powah
    ]]
  end
end

local function count(tab)
  local count = 0
  for k,v in pairs(tab) do
    count = count+1
  end
  return count
end

local function concatenate_keys(tab)
  local key_list = {}
  for k,v in pairs(tab) do
    table.insert(key_list,k)
  end
  return "``"..table.concat(key_list,"``,\n``").."``"
end

local help_command = command("help",{
    help = {embed={
      title = "View help embeds for commands and plugins",
      description = "To specify if it's a plugin or a command, simply add the option accordingly",
      fields = {
        {name = "Usage:",value = "help [<command> or --plugin <plugin>]"},
        {name = "Perms:",value = "any"},
        {name = "Options:",value = "--plugin"}
      }
    }},
    exec = function(msg,args,opts)
      randomize_stuff()
      local embed = {
        color = discordia.Color.fromHex("32b3bc").value
      }
      if args[1] then
        if count(opts) < 1 then
          if command_handler:get_command(args[1]) then
            local command = command_handler:get_command(args[1])
            embed = command:get_help().embed
          else
            embed.description = "No such command"
          end
        elseif (opts["plugin"]) then
          --[[ if plugin_data["plugins"] [args[1] ] then
            embed.title = "Plugin ``"..args[1].."``:"
            embed.description = plugin_data["plugins"] [args[1] ]["_help"]
            embed.fields = {{
              name = "Commands:",
              value ="``"..table.concat(plugin_data["plugins"] [args[1] ],"``,\n``").."``"
            }}
          else
            embed.description = "No such plugin"
          end
          --]]
          embed.title = "Not yet implemented"
          embed.description = "Check again later"
        end
      else
        embed.title = "512mb.org commands:"
        embed.description = "use ``help <command>`` to view help messages. (type ``help help`` for more info)"
        embed.fields = {}
        for k,v in pairs(command_handler:get_commands_metadata().plugins) do
          table.insert(embed.fields,{
            name = k,
            value = "``"..table.concat(v,"``, ``").."``"
          })
        end
      end
      msg:reply({embed = embed})
    end,
    })
plugin:add_command(help_command)
return plugin
