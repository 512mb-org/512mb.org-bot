return {
  ["prefix"] = {embed={
      title = "Set or view current prefix for this bot",
      description = "If you're not sure what's the current prefix, just ping the bot",
      fields = {
        {name = "Usage:",value = "prefix [<new prefix> or \"<new prefix>\"]"},
        {name = "Perms:",value = "Administrator"},
      }
  }},
  ["alias"] = {embed={
      title = "Creates aliases",
      description = "Add an alias for a command. (https://en.wikipedia.org/wiki/Alias_(command))",
      fields = {
        {name = "Usage: ",value = "alias \"<alias name>\" \"<command>\""},
        {name = "Examples: ",value = [[
``alias !hi "!speak Hello!"`` - reply to !hi with "Hello!" using speak command
``alias !say "!speak ..."`` - reply to !hi with everything typed after !hi
``alias !say "!speak $1"`` - reply to !hi with the first argument sent along with !hi
More at https://github.com/yessiest/SuppaBot/wiki/Tasks]]
        },
        {name = "Perms: ",value = "Administrator (doesn't apply to created aliases)"}
      }
  }},
  ["unalias"] = {embed = {
      title = "Removes aliases",
      description = "Remove a previously created alias",
      fields = {
        {name = "Usage: ",value = "unalias \"<alias name>\""},
        {name = "Perms: ",value = "Administrator"}
      }
  }},
  ["aliases"] = {embed = {
      title = "Lists aliases",
      description = "List all previously created aliases",
      fields = {
        {name = "Usage: ",value = "aliases"},
        {name = "Perms: ",value = "all"}
      }
  }},
  ["ping"] = {embed = {
      title = "View response latency",
      description = "This command shows some latency stats",
      fields = {
        {name = "Usage: ",value = "ping"},
        {name = "Perms: ",value = "all"}
      }
  }},
  ["about"] = {embed = {
      title = "View bot info",
      description = "self-descriptive",
      fields = {
        {name = "Usage: ",value = "about"},
        {name = "Perms: ",value = "all"}
      }
  }},
  ["server"] = "Show server stats in a form of embed",
  ["user"] = "View users stats",
  ["speak"] = "Repeats the message, but suppresses the pings",
  ["adminSpeak"] = "Repeats the message without suppressing pings (administrator permissions required)",
  ["echo"] = "Repeats the message without deleting the command",
}
