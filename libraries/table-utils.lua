local utilities = {}
utilities.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    local depth = depth
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utilities.deepcopy(orig_key)] = utilities.deepcopy(orig_value)
        end
        setmetatable(copy, utilities.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
utilities.slice = function(list,start,list_end)
  local output = {}
  for I = (start or 1),(list_end or #table) do
    table.insert(output,list[I])
  end
  return output
end
utilities.shallowcopy = function(orig)
  local copy = {}
  for k,v in pairs(orig) do
    copy[k] = v
  end
  return copy
end
--overwrite the original table's properties with new properties
utilities.overwrite = function(original,overwrite)
  local new = utilities.shallowcopy(original)
  for k,v in pairs(overwrite) do
    new[k] = v
  end
  return new
end
--merge all objects passed as arguments into a table.
--if the object is a table, merge all of it's contents with the table
utilities.merge = function(...)
  local args = {...}
  local new = {}
  for k,v in pairs(args) do
    if type(v) == "table" then
      for k2,v2 in pairs(v) do
        table.insert(new,v2)
      end
    else
       table.insert(new,v)
     end
   end
   return new
end
utilities.remove_value = function(tb,v)
    local id_to_remove = nil
    for k,f in pairs(tb) do
        if f == v then 
            id_to_remove = k
        end
    end
    if id_to_remove then
        table.remove(tb,id_to_remove)
        return true
    else
        return false
    end
end
utilities.count = function(tb)
    local count = 0
    for k,v in pairs(tb) do
        count = count + 1
    end
    return count
end
utilities.exists = function(tb,vc)
    local kout 
    for k,v in pairs(tb) do
        if v == vc then
            kout = k
        end
    end
    return kout
end
return utilities
