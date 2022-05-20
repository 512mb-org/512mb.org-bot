return {
    ["dice"] = "Simulates a dice throw, prints the value of each die",
    ["cards"] = "Draw a specific amount of playing cards and display them",
    ["calculate"] = {embed={
        title = "Calculate an expression",
		description = "Calculates maths using libqalculate. https://qalculate.github.io/ for more info",
        fields = {
            {name = "Usage",value = [[calculate "<expression>"]]},
            {name = "Perms: ",value = "All"},
            {name = "Options",value = "`-e` - exact mode"}
        }
    }},
	["pfp"] = "Show the profile picture of a user, or if none is specified, of yourself",
	["markpov"] = { embed = {
        title = "Generate some text using markov chains",
        description = "Generates text using the markov chain rule applied to a predefined set of words",
        fields = {
            {name = "Usage: ", value = "markov <text to start with>"},
            {name = "Options: ", value = [[
--preseteset> - Select a text preset. Currently available:
``defaul- Generated from a wikipedia page on markov chains
``freud`The largest one, generated from a page on Sigmund Freud
``reddit Generated from reddit comments
``travist`` - Generated from transcript of a video by PlasticPills on travis scott burger
]]          },
            {name = "Perms: ", value = "any"}
        }
    }},
    ["embed"] = {embed={
        title = "Convert JSON objects into embeds",
		description = "If you've worked with discord.js before, this might be simple. If you haven't, then check out https://github.com/yessiest/SuppaBot/wiki/Embeds",
        fields = {
            {name = "Usage",value = [[embed {code}]]},
            {name = "Perms: ",value = "All"},
        }
    }},
}