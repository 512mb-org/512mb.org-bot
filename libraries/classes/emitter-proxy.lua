local class = import("classes.baseclass")
local emitter_proxy = class("EmitterProxy")

function emitter_proxy:__init(emitter)
  self.original = emitter
  self.callback_pool = {}
end

function emitter_proxy:on(event,callback)
  if not self.callback_pool[event] then 
    self.callback_pool[event] = {}
  end
  self.callback_pool[event][callback] = callback
  self.original:on(event,callback)
  return callback
end

function emitter_proxy:once(event,callback)
  if not self.callback_pool[event] then
    self.callback_pool[event] = {}
  end
  local wrapper = function(...)
    callback(...)
    self.callback_pool[event][callback] = nil
  end
  self.callback_pool[event][callback] = wrapper
  self.callback_pool[event][wrapper] = wrapper
  self.original:once(event,wrapper)
  return callback
end

function emitter_proxy:removeListener(event,callback)
  if self.callback_pool[event] and self.callback_pool[event][callback] then
    self.callback_pool[event][callback] = nil
    self.original:removeListener(event,callback)
  end
end

function emitter_proxy:removeAllListeners(event,callback)
  if self.callback_pool[event] then 
    for k,v in pairs(self.callback_pool[event]) do
      self.original:removeListener(event,v)
    end
    self.callback_pool[event] = nil
  end
end

function emitter_proxy:listeners(event)
  local copy = {}
  if self.callback_pool[event] then
    for k,v in pairs(self.callback_pool[event]) do
      table.insert(copy,v)
    end
  end
  return copy
end

function emitter_proxy:listenerCount(event)
  local count = 0
  if event then 
    if self.callback_pool[event] then
      for k,v in pairs(self.callback_pool[event]) do
        count = count + 1
      end
    end
  else 
    for k,v in pairs(self.callback_pool) do
      for k2,v2 in pairs(v) do
        count = count + 1
      end
    end
  end
  return count
end

function emitter_proxy:propogate(event,emitter)
  if not self.callback_pool[event] then
    self.callback_pool[event] = {}
  end
  local emitter_propogate_handler = function(...)
    emitter:emit(event,...)
  end
  self.callback_pool[event][emitter_propogate_handler] = emitter_propogate_handler
  self.original:on(event,emitter_propogate_handler)
  return emitter_propogate_handler
end

function emitter_proxy:destroy()
  for k,v in pairs(self.callback_pool) do
    for k2,v2 in pairs(v) do
      self.original:removeListener(k,v2)
    end
  end
end
return emitter_proxy
