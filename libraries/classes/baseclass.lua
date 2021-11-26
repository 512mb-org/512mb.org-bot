--class generator (for the purpose of creating classes)
return function(name)
  local new_class = {}
  new_class.__classname = name or "Object"
  new_class.__index = new_class
  new_class.__new = function(self,...)
    local obj = {}
    --set metamethod proetection measures
    setmetatable(obj,{__index = function(obj,key)
      if key:find("^__") then
        return nil
      else
        return self[key]
      end
    end,
    __name = new_class.__classname})
    if self.__init then
      self.__init(obj,...)
    end
    return obj
  end
  new_class.extend = function(self,name)
    local new_class = {}
    new_class.__classname = name or "Object"
    new_class.__index = new_class
    setmetatable(new_class,{__index = self,__call = function(...) return new_class.__new(...) end, __name = new_class.__classname.." (class)"})
    return new_class
  end
  --make our class callable; on call, it will initialize a new instance of itself
  setmetatable(new_class,{__call = function(...) return new_class.__new(...) end, __name = new_class.__classname.." (class)"})
  return new_class
end
