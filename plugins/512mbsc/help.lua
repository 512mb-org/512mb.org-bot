return {
    ["scc-score"] = { embed = {
        title = "Check SCC score",
        description = "nuff said.",
        fields = {
            {name = "Usage: ", value = "scc-score [<user>]"},
            {name = "Perms: ", value = "any"},
        }
    }},
    ["scc-rules"] = { embed = {
        title = "Change SCC system rules",
        description = "If no arguments are given the command displays rules instead",
        fields = {
            {name = "Usage: ", value = "scc-rules [<rulename> <value>]"},
            {name = "Perms: ", value = "administrator"},
        }
    }}
}
