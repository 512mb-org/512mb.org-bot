local discordia = require('discordia')
return { 
    ["enable"] = {embed = {
        title = "Enable plugin",
        description = [[This command loads a plugin,
addng its commands to the command pool]],
        fields = {
            {name = "Usage:",value = "load <plugin-name>"},
            {name = "Perms:",value = "Administrator, other (via ``rules --allow``)"}
        },
        color = discordia.Color.fromHex("ff5100").value
    }},
    ["disable"] = {embed = {
        title = "Disable a loaded plugin",
        description = [[This commands unloads a previously loaded plugin,
removing its commands from the command pool]],
        fields = {
            {name = "Usage:",value = "unload <plugin-name>"},
            {name = "Perms:",value = "Administrator, other (via ``rules --allow``)"}
        },
        color = discordia.Color.fromHex("ff5100").value
    }},
    ["plugins"] = {embed = {
        title = "View all known plugins",
        description = [[This commmand prints info on loaded and unloaded plugins]],
        fields = {
            {name = "Usage:",value = "plugins"},
            {name = "Perms:",value = "Administrator, other (via ``rules --allow``)"}
        },
        color = discordia.Color.fromHex("ff5100").value
    }},
}
