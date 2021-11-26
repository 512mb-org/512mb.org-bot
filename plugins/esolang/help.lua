local discordia = require("discordia")
return {
    ["brainfuck"] = {embed = {
      title = "Run brainfuck code",
      description = "specification can be found at https://esolangs.org/wiki/brainfuck",
      color = discordia.Color.fromHex("#32cd32").value,
      fields = {
         {name = "Usage: ",value = "brainfuck <brainfuck code> [<input>]"},
         {name = "Perms: ",value = "all"},
         {name = "Options: ",value = [[
 -o; --output-only  -  print only the output, without an embed
         ]]}
      }
    }},
    ["befunge"] = {embed = {
      title = "Run befunge-93 code",
      description = "specification can be found at https://esolangs.org/wiki/befunge",
      fields = {
        {name = "Usage: ",value = "befunge \\`\\`\\`<code here>\\`\\`\\` [<input>]"},
        {name = "Perms: ",value = "all"},
        {name = "Options: ",value = [[
-o; --output-only  -  print only the output, without an embed
        ]]}
      },
      color = discordia.Color.fromHex("#32cd32").value,
    }},
}
