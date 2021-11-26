--string purifier library
local purify = {}
purify.purify_pings = function(msg,input)
  local text = input
  while text:match("<@(%D*)(%d*)>") do
    local obj,id = text:match("<@(%D*)(%d*)>")
    local substitution = ""
    if obj:match("!") then
      local member = msg.guild:getMember(id)
      if member then
        substitution = "@"..member.name
      end
    elseif obj:match("&") then
      local role = msg.guild:getRole(id)
      if role then
        substitution = "@"..role.name
      end
    end
    if substitution == "" then
      substitution = "<\\@"..obj..id..">"
    end
    text = text:gsub("<@(%D*)"..id..">",substitution)
  end
  return text
end

purify.purify_escapes = function(text)
  local match = "([%(%)%.%%%+%-%*%?%[%]%^%$])"
  return text:gsub(match,"%%%1")
end

return purify
