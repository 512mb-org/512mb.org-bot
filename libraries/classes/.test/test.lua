class = require("baseclass")
tests = {}
tests[1] = function()
  print("Basic class initialization test")
  local newclass = class("TestObject")
  function newclass:__init(value)
    self.prop = value
  end
  function newclass:setProp(value)
    self.prop = value
    print("Property for object "..tostring(self).." set to "..tostring(value))
  end
  function newclass:printProp()
    print(self.prop)
  end
  local object_a = newclass(3)
  object_a:printProp()
  object_a:setProp(30)
  object_a:printProp()
end

tests[2] = function()
  print("Class instance independence test")
  local newclass = class("TestObject")
  function newclass:__init(value)
    self.prop = value
  end
  function newclass:setProp(value)
    self.prop = value
    print("Property for object "..tostring(self).." set to "..tostring(value))
  end
  function newclass:printProp()
    print(self.prop)
  end
  local object_a = newclass(3)
  local object_b = newclass()
  object_a:printProp()
  object_b:printProp()
  object_a:setProp(30)
  object_b:setProp(20)
  object_a:printProp()
  object_b:printProp()
end

tests[3] = function()
  print("Extension test")
  local newclass = class("Accumulator")
  function newclass:ret()
    return self.acc
  end
  function newclass:setA(a)
    self.a = a
  end
  function newclass:setB(b)
    self.b = b
  end
  local adder = newclass:extend("Adder")
  function adder:add()
    self.acc = self.a + self.b
  end
  local subber = newclass:extend("Subtracter")
  function subber:sub()
    self.acc = self.a - self.b
  end
  obj1 = adder()
  obj1:setA(1)
  obj1:setB(2)
  obj1:add()
  print(obj1:ret())
  obj2 = subber()
  obj2:setA(1)
  obj2:setB(2)
  obj2:sub()
  print(obj2:ret())
end
--here run tests
print("Deteceted "..#tests.." tests. Starting now.")
OK = 0
for k,v in pairs(tests) do
  status,errcode = pcall(v)
  print("TEST #"..k.." "..((status and "OK") or "ERROR")..(((not status) and errcode) or ""))
  if status then
    OK = OK + 1
  end
end
print(OK.."/"..#tests.." tests completed successfully")
