-- Lua cron parser
--[[
Copyright © 2022 Yessiest

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
local find_strings = require("string_parse")

local safe_regex = function(str,pattern)
    local status,ret = pcall(string.match,str,pattern)
    if status then return ret end
end

-- Adjustments for lua5.1
if _VERSION=="Lua 5.1" then
    table.unpack = unpack
end

local cron = {
    directive_handler = nil
}

local units = {
    m = 60,
    h = 60*60,
    d = 60*60*24,
    y = 60*60*24*356,
    w = 60*60*24*7
}
cron.convert_delay = function(str)
    local time = os.time()
    str:gsub("(%d+)([hmdyw])",function(n,unit)
        time = time+(units[unit]*tonumber(n))
    end)
    return time
end

-- Utility functions
local mdays = {31,28,31,30,31,30,31,31,30,31,30,31}
cron._date = function(d,m,y)
    local current_date = os.date("*t")
    local y = ("2000"):sub(1,4-tostring(y):len())..tostring(y)
    d = tonumber(d or current_date.day)
    m = tonumber(m or current_date.month)
    y = tonumber(y or current_date.year)
    if ((y%4 == 0) and (y%100 ~= 0)) or ((y%100 == 0) and (y%400 == 0)) then
        mdays[2] = 29
    else
        mdays[2] = 28
    end
    return {
        assert((d > 0) and (d <= (mdays[m] or 31)) and d, "Invalid day: "..tostring(d)),
        assert(mdays[m] and m, "Invalid month: "..tostring(m)),
        y 
    }
end

cron._time = function(h,m)
    local current_date = os.date("*t")
    h = tonumber(h or current_date,hour)
    m = tonumber(m or current_date.min)
    return {
        assert((h >= 0) and (h < 24) and h, "Invalid hour: "..tostring(h)),
        assert((m >= 0) and (m < 60) and m, "Invalid min: "..tostring(m))
    }
end

cron._compare_tables = function(d1,d2)
    for k,v in pairs(d1) do
        if d2[k] ~= v then
           return false
        end
    end
    return true
end
-- Token types, in (regex, type, preprocessor) format
local token_types = {
    {"^@(%w+)$", "directive", function(text)
        return text 
    end},
    {"^(%d%d)%.(%d%d)%.(%d%d%d?%d?)$","date",function(d,m,y)
        return cron._date(d,m,y)
    end},
    {"^(%d%d):(%d%d)$","time",function(h,m)
        return cron._time(h,m)
    end},
    {"^(%d+,[%d,]+)$", "any_list",function(text)
        return function(num)
            local status = false
            text:gsub("%d*",function(number)
                if num == tonumber(number) then
                    status = true
                end
            end)
            return status
        end
    end},
    {"^%*/(%d+)$", "any_modulo", function(text)
        return function(num)
            return (num % tonumber(text) == 0)
        end
    end},
    {"^%*$", "any", function()
        return function()
            return true 
        end
    end},
    {"^%d+$", "number", function(text) 
        return function(num)
            return num == tonumber(text) 
        end
    end},
    {"^%s*$","spacer", function(text) return text end},  
    {"^%S+$","command", function(text) return text end} 
}
-- Valid argument matching predicates for directives
local predtypes = {
    {"^([<>])(=?)(%d+)$","comparison",function(lm,eq,number)
        local number = tonumber(number)
        return function(input)
            local input = tonumber(input)
            if not input then return false end
            return ((eq == "=") and number == input) or
                   ((lm == ">") and number < input) or
                   ((lm == "<") and number > input)
        end
    end},
    {"^/([^/]*)/$","regex",function(regex)
        return function(input)
            return (safe_regex(tostring(input),regex) ~= nil)
        end
    end},
    {"^\"([^\"]*)\"$","string",function(str)
        return function(input)
            return str==tostring(input)
        end
    end},
    {"^'([^']*)'$","string",function(str)
        return function(input)
            return str==tostring(input)
        end
    end},
    {"^%d+$","number",function(number)
        return function(input)
            return number == tostring(input)
        end
    end},
    {"^%*$","any",function()
        return function()
            return true
        end
    end},
    {"^:$","delimiter",function()
        return function()
            error("Delimiter is not a predicate!")
        end
    end},
    {"^%s+$","spacer",function()
        return function()
            error("Spacer is not a predicate!")
        end
    end},
    {"^%S+$","command", function(text) 
        return function()
            return text 
        end
    end}
}

-- Valid syntactic constructions
local syntax = {
    {{"number","number","number","number","number"},"cronjob",
    function(min,hour,day,mo,dw,comm)
        return function(date)
            local status = min(date.min)
            status = status and hour(date.hour)
            status = status and day(date.day)
            status = status and mo(date.month)
            status = status and dw(wday)
            return status,comm
        end
    end},
    {{"date","time"},"onetime",function(date,time,comm)
        local time = os.time({day = date[1], month = date[2], year = date[3],
            hour = time[1], min = time[2]
        })
        return function(cdate)
            return os.time(cdate) >= time,comm
        end
    end},
    {{"time","date"},"onetime",function(time,date,comm)
        local time = os.time({day = date[1], month = date[2], year = date[3],
            hour = time[1], min = time[2]
        })
        return function(cdate)
            return os.time(cdate) >= time,comm
        end
    end}
}

local startfrom = function(pos,t) 
    local newtable = {}
    for i = pos,#t do
        newtable[i+1-pos] = t[i]
    end
    return newtable
end

cron._split = function(text)
    -- Parse strings
    local tokens = {}
    text:gsub("(%S*)(%s*)",function(text,padding)
        table.insert(tokens,text)
        if padding:len() > 0 then
            table.insert(tokens,padding)
        end
    end)
    return tokens
end

cron._split_with_strings = function(text)
    -- Parse strings
    local nt = find_strings(text)
    local tokens = {}
    for k,v in pairs(nt) do
        if not ((v:sub(1,1) == v:sub(-1,-1)) and (v:match("^[\"'/]"))) then
            -- Parse space-separated tokens
            v:gsub("(%S*)(%s*)",function(text,padding)
                table.insert(tokens,text)
                if padding:len() > 0 then
                    table.insert(tokens,padding)
                end
            end)
        else
            -- Insert pre-parsed strings into tokens
            table.insert(tokens,v)
        end
    end
    return tokens
end

cron.parse_token = function(text)
    local token = {text}
    for _,pair in pairs(token_types) do
        if text:match(pair[1]) then
            token.type = pair[2]
            token[1] = pair[3](token[1]:match(pair[1]))
            return token
        end
    end
end

cron.parse_directive = function(tokens)
    table.remove(tokens,1)
    -- Prepare predicate chain
    local argmatches = {}
    local stop = nil
    for k,v in pairs(tokens) do
        for _,pair in pairs(predtypes) do
            if v:match(pair[1]) then
                -- Stop at delimiter
                if pair[2] == "delimiter" then
                    stop = k
                    break
                end
                -- Ignore spacers - they're not predicates
                if pair[2] ~= "spacer" then
                    table.insert(argmatches,pair[3](v:match(pair[1])))
                end
                break
            end
        end
        if stop then
            break
        end
    end
    -- We use a delimiter so that command start wouldn't be ambiguous
    -- Rather than defining an amount of arguments to directives, we 
    -- simply allow the directive to match any amount of arguments all times
    if not stop then
        return false, "Directive arguments should end with a : delimiter"
    end
    local command = table.concat(startfrom(stop+2,tokens))
    -- Return the function that matches against a predicate chain
    return function(arguments)
        for k,v in pairs(argmatches) do
            if not v(arguments[k]) then
               return false
            end
        end
        return true, command
    end,"directive"
end

cron.parse_generic = function(tokens)
    -- Parse tokens
    local parsed_tokens = {}
    for k,v in pairs(tokens) do
        local status,token = pcall(cron.parse_token,v)
        if not status then
            return false,token
        end
        table.insert(parsed_tokens,token)
    end
    -- Match against a syntactic construction
    for k,v in pairs(syntax) do
        local matches = true
        local args = {}
        for pos,type in pairs(v[1]) do
            -- Remove trailing spacer tokens
            while parsed_tokens[pos] and parsed_tokens[pos].type == "spacer" do
                table.remove(parsed_tokens,pos)
            end
            if not parsed_tokens[pos] then
                break
            end
            -- Numbers are a special case because they can be matched
            -- by multiple predicates
            if type == "number" then
                if (parsed_tokens[pos].type ~= "number") and
                   (not parsed_tokens[pos].type:match("^any")) then
                        matches = false
                        break
                end
            else
                if (parsed_tokens[pos].type ~= type) then
                    matches = false
                    break
                end
            end
            table.insert(args,parsed_tokens[pos][1])
        end
        if matches then
            -- Calculate cut position
            local cut_pos = #v[1]*2+1
            local command = table.concat(startfrom(cut_pos,tokens))
            args[#args+1] = command
            return v[3](table.unpack(args)),v[2]
        end
    end
    return false, "Syntax doesn't match any valid construction"
end 

cron.parse_line = function(line) 
    local tokens = cron._split(line)
    local status,first_token = pcall(cron.parse_token,tokens[1])
    if not status then
        return false,first_token
    end
    if first_token.type == "directive" then

        return cron.parse_directive(cron._split_with_strings(line))
        -- ...
    else
        return cron.parse_generic(tokens)
        -- ...
    end
end

cron.parse = function(text)
    text:gsub("\n.-\n?$",function(line)
        cron.parse_line(line)
    end)
end

return cron
