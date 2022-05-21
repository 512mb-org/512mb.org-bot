return {
    ["grant-role"] = {embed={
        title = "Grant a role to the user",
        description = "If <user> is not provided, the caller is assumed as the <user> argument.",
        fields = {
            {name = "Usage:",value = "grant-role <role id> [<user>]"},
            {name = "Perms:",value = "administrator"},
            {name = "Options:",value = "-q - quiet (don't print the result)"}
        }
    }},
    ["revoke-role"] = {embed={
        title = "Revoke a role from the user",
        description = "If <user> is not provided, the caller is assumed as the <user> argument.",
        fields = {
            {name = "Usage:",value = "revoke-role <role id> [<user>]"},
            {name = "Perms:",value = "administrator"},
            {name = "Options:",value = "-q - quiet (don't print the result)"}
        }
    }},
    ["warn"] = {embed={
        title = "Warn a user",
        description = "nuff said.",
        fields = {
            {name = "Usage:",value = "warn <user> <reason>"},
            {name = "Perms:",value = "kickMembers"},
        }
    }},
    ["infractions"] = { embed = {
        title = "List user infractions",
        description = "Infractions include kicks, bans, mutes and warnings.",
        fields = {
            {name = "Usage: ", value = "infractions <user> [<startfrom>]"},
            {name = "Perms: ", value = "kickMembers"},
            {name = "Options: ", value = "--type=(warn default,ban,kick)"}
        }
    }},
    ["purge"] = { embed = {
        title = "Purge a number of messages",
        description = "nuff said.",
        fields = {
            {name = "Usage: ", value = "purge <number>"},
            {name = "Perms: ", value = "manageMessages"},
            {name = "Options: ", value = "`--regex (regex)` - match content against regex; \n`--user (user)` - match user against id/name; \n`-w` - match webhook messages"}
        }
    }},
    ["ban"] = { embed = {
        title = "Ban members",
        description = "nuff said.",
        fields = {
            {name = "Usage: ", value = "ban <member>"},
            {name = "Perms: ", value = "banMembers"},
            {name = "Options: ", value = "--reason=\"<reason>\""},
        },
    }},
    ["kick"] = { embed = {
        title = "Ban members",
        description = "nuff said.",
        fields = {
            {name = "Usage: ", value = "kick <member>"},
            {name = "Perms: ", value = "kickMembers"},
            {name = "Options: ", value = "--reason=\"<reason>\""},
        },
    }},
}
