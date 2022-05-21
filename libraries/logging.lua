local logging_facilities = {
    ["ALIAS"] = "0;32",
    ["REACTIONS"] = "0;32",
    ["SERVER"] = "1;34",
    ["ERROR"] = "1;31",
    ["WARNING"] = "1;33"
}
local clear = "\27[0m"
local concat = function(tab,separator)
    local text = ""
    local separator = separator or "\9"
    for k,v in pairs(tab) do
        text = text..tostring(v)..separator
    end
    return text:sub(1,-1-separator:len())
end
return function(facility, ...)
    local effect = "\27["
    if logging_facilities[facility] then
        effect = effect..logging_facilities[facility].."m"
    else
        effect = effect.."1m"
    end
    print(os.date("%Y-%m-%d %H:%M:%S | ")..effect.."["..facility.."]"..clear.."\9| "..concat({...}))
end

