return {
    ["event"] = {embed={
      title = "Add a cron event",
      description = "https://github.com/512mb-org/512mb.org-bot/wiki/Events-and-cronjobs",
      fields = {
        {name = "Usage:",value = "event ..."},
        {name = "Perms:",value = "administrator"},
      }
    }},
    ["delay"] = {embed={
      title = "Delay a command",
      description = "Delay fromat is <number><unit>, where unit is one of the follwing:\n\"h\" - hour,\n\"m\" - minute,\n\"d\" - day,\n\"w\" - week,\n\"y\" - year",
      fields = {
        {name = "Usage:",value = "delay <delayformat> <command>"},
        {name = "Perms:",value = "any"},
      }
    }},
    ["events"] = {embed={
      title = "View your running events",
      description = "nuff said.",
      fields = {
        {name = "Usage:",value = "events <page>"},
        {name = "Perms:",value = "any"},
      }
    }},
    ["user-events"] = {embed={
      title = "View running events of a certain user",
      description = "nuff said.",
      fields = {
        {name = "Usage:",value = "user-events <user> <page>"},
        {name = "Perms:",value = "administrator"},
      }
    }},
    ["remove-event"] = {embed={
      title = "Remove an event",
      description = "nuff said.",
      fields = {
        {name = "Usage:",value = "remove-event <id>"},
        {name = "Perms:",value = "any"},
      }
    }},
    ["remove-user-event"] = {embed={
      title = "Remove an event from a user",
      description = "nuff said.",
      fields = {
        {name = "Usage:",value = "remove-user-event <user> <id>"},
        {name = "Perms:",value = "administrator"},
      }
    }},
    ["date"] = "Print current date and time"
}
