return function(text,custom_strings)
    local delimiters = custom_strings or "[\"'/]"
    -- Find 2 string delimiters.
    -- Partition text into before and after if the string is empty
    -- Partition text into before, string and after if the string isn't empty
    local strings = {text}
    while strings[#strings]:match(delimiters) do
        local string = strings[#strings]
        -- Opening character for a string
        local open_pos = string:find(delimiters)
        local open_char = string:sub(open_pos,open_pos)
        if strings[#strings]:sub(open_pos+1,open_pos+1) == open_char then
            -- Empty string
            local text_before = string:sub(1,open_pos-1)
            local text_after = string:sub(open_pos+2,-1)
            strings[#strings] = text_before
            table.insert(strings,open_char..open_char)
            table.insert(strings,text_after)
        else
            -- Non-empty string
            local text_before = string:sub(1,open_pos-1)
            local _,closing_position = string:sub(open_pos,-1):find("[^\\]"..open_char)
            if not closing_position then
                break
            else
                closing_position = closing_position+open_pos-1
            end
            local text_string = string:sub(open_pos,closing_position)
            local text_after = string:sub(closing_position+1,-1)
            strings[#strings] = text_before
            table.insert(strings,text_string)
            table.insert(strings,text_after)
        end
    end
    for k,v in pairs(strings) do
        if v:len() == 0 then
            table.remove(strings,k)
        end
    end
    return strings
    -- P.S: This one is the best one i've written. Sure it looks clunky, but it 
    -- does exactly what I expect it to do - handle cases when there are string
    -- delimiters inside other strings. Lovely. Also kinda horrifying.
end
