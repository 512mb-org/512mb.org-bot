--Luvit's deadly sin - a library that fixes the dumbest problem in luvit
--That is, unability to load core modules from the files that were required
return function(reqfunc)
    local function import(path)
        local paths = {}
        package.path:gsub("[^;]+",function(path)
            table.insert(paths,path)
        end)
        local filename = path:gsub("%.","/")
        local file = io.open(filename..".lua","r")
        local iterator = 0
        local last_filename = ""
        while not file do
            iterator = iterator + 1
            if paths[iterator] then
                file = io.open(paths[iterator]:gsub("%?",filename),"r")
                last_filename = paths[iterator]
            else
                break
            end
        end
        if not file then
            return reqfunc(path)
        else
            content = file:read("*a")
            local f,err = load(content,"import: "..filename,nil,setmetatable({
                require = reqfunc,
                import = import,
            },{__index = _G}))
            if err then
                error("[import: "..filename.."] "..tostring(err))
            end
            return f()
        end
    end
    return import
end
--[[
Usage:
import = require("import")(require)
file = import("file")

yes, THAT easy. moreover, once you have imported the import function, it will be passed
to the loaded libraries.

how hard is that to implement this but with the luvit's require, eh?
]]
