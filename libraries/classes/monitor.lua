local RPC_server = import("classes.RPC-server")
local class = import("classes.baseclass")
local monitor = class("Monitor")

--we only generate proxies as far as 1 object deep. 
--to provide seamlessness, metamethods that request object proxies from their
--pointers may be used on the client side

--pointers here mean tables that contain the __id and __type properties.
--they do not hold any info on the object besides its class name and id

--a lookup table of all classes that we do not ignore. we exclude client and containers
--because they might break the sandboxing. we *do not* want that.
local allowed_types = {    
    ["guild"] = true,
    ["member"] = true,
    ["emoji"] = true,
    ["message"] = true,
    ["channel"] = true,
    ["role"] = true,
    ["user"] = true,
    ["invite"] = true,
    ["guildtextchannel"] = true,
    ["textchannel"] = true,
    ["iterable"] = true,
    ["cache"] = true,
    ["arrayiterable"] = true,
    ["filteretediterable"] = true,
    ["secondarycache"] = true,
    ["weakcache"] = true,
    ["tableiterable"] = true,
}

--a lookup table of classes that can be explicitly converted to arrays. 
local iterable_types = {
    ["iterable"] = true,
    ["cache"] = true,
    ["arrayiterable"] = true,
    ["filteretediterable"] = true,
    ["secondarycache"] = true,
    ["weakcache"] = true,
    ["tableiterable"] = true,
}

local comprehend_object = function(object)
    local output
    if (type(object) == "table") and (object.__class) then
        --our object is an instance of a class
        local class = object.__class.__name:lower()
        if allowed_types[class] and (not iterable_types[class]) then
            --our object can only be pointed to
            output = {__id = object[k].id, __type = class}
        else
            --our object can be converted to an array
      
        end
    else
        --our object is either an atomic data type, a string or a table.

    end
end

local create_proxy = function(object)
    local output = {}
    for k,v in pairs(getmetatable(object).__getters) do
    end
end

local proto_api = {
    msg = {
        get = function(channel,id)
            channel:getMessage(id)
        end,
    },
    guild = {
        
    },
    member = {

    },
    channel = {

    }
}

function monitor:__init(guild,options)
    assert(guild,"No guild provided")
    assert(options,"No options provided (arg 2)")
    

