return {
    ["pivot"] = {embed={
      title = "Select a pivot message to manipulate",
      description = "Pivot is like a message selector which allows easy reaction manipulations",
      fields = {
        {name = "Usage: ",value = "pivot <message link>"},
        {name = "Perms: ",valeu = "Administartor"}
      }
    }},
    ["role-toggle"] = {embed={
      title = "Add a simple role switch to the pivot",
      description = "Note: you cannot assign more than one role to a single reaction",
      fields = {
        {name = "Usage: ",value = "role-toggle <emoji> <role ping or role id>"},
        {name = "Perms: ",value = "administrator"}
      }
    }},
    ["remove-reaction"] = {embed={
      title = "Remove a reaction from a pivot",
      description = "If you don't specify a reaction to remove, the entire pivot for the message is removed automatically",
      fields = {
        {name = "Usage: ",value = "remove-reaction <emoji>"},
        {name = "Perms: ",value = "Administrator"}
      }
    }},
    ["toggle"] = {embed={
      title = "Add a toggle that runs specific commands",
      description = "Note: you cannot assign more than one action to a single reaction \n``$user`` gets replaced with the id of the user that interacted with the reaction.",
      fields = {
        {name = "Usage: ",value = "toggle <emoji> <command-on> <command-off>"},
        {name = "Perms: ",value = "administrator"}
      }
    }},
    ["button"] = {embed={
      title = "Add a button that runs specific command when pressed",
      description = "Note: you cannot assign more than one action to a single reaction \n``$user`` gets replaced with the id of the user that interacted with the reaction.",
      fields = {
        {name = "Usage: ",value = "button <emoji> <command>"},
        {name = "Perms: ",value = "administrator"}
      }
    }},
}
