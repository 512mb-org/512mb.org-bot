local interface = {}
interface.wrapper = function(client,guild_id)
    local new_i = {}
    new_i.message = {}
    new_i.message.get = function(channel,id)
        local new_m = {}
        local message = client.getMessage(id)
        local new_m.content = message.content
        local new_m.created_at = message.createdAt
        local new_m.attachments = {}
        for k,v in pairs(message.attachments) do
            table.insert(new_m
