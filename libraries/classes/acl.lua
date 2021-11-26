--Access control list class
--Note that it isn't directly used by anything,
--Instead it is extended to work with discord's permission system
--as command-acl
local class = import("classes.baseclass")
local table_utils = import("table-utils")
local acl = class("ACL")
function acl:__init()
  self.user_rules = {}
  self.group_rules = {}
end
function acl:set_user_rule(user_id,status)
  assert(
    (status == nil) or (status == 0) or (status == -1) or (status == 1),
    "invalid status setting"
  )
  self.user_rules[user_id] = status
end
function acl:set_group_rule(group_id,status)
  assert(
    (status == nil) or (status == 0) or (status == -1) or (status == 1),
    "invalid status setting"
  )
  self.group_rules[group_id] = status
end
function acl:check_user(user_id)
  if self.user_rules[user_id] and self.user_rules[user_id] ~= 0 then
    return true,(self.user_rules[user_id] == 1)
  else
    return false
  end
end
function acl:check_group(groups)
  local allow = false
  local found = false
  for k,v in pairs(groups) do
    if self.group_rules[v] then
      found = true
      allow = self.group_rules[v]
    end
  end
  return found,(allow and allow == 1)
end
function acl:export_all_lists()
  local lists = {
    users = "",
    groups = ""
  }
  for k,v in pairs(self.user_rules) do
    lists.users = lists.users..k..":"..tostring(v)..";\n"
  end
  for k,v in pairs(self.group_rules) do
    lists.groups = lists.groups..k..":"..tostring(v)..";\n"
  end
  return lists
end
function acl:export_user_list()
  local list = ""
  for k,v in pairs(self.user_rules) do
    list = list..k..":"..tostring(v)..";\n"
  end
  return list
end
function acl:export_group_list()
  local list = ""
  for k,v in pairs(self.group_rules) do
    list = list..k..":"..tostring(v)..";\n"
  end
  return list
end
function acl:export_snapshot()
  return {
    user_rules = bot_utils.deepcopy(self.user_rules),
    group_rules = bot_utils.deepcopy(self.group_rules)
  }
end
function acl:import_snapshot(t)
  self.user_rules = t.user_rules
  self.group_rules = t.group_rules
end
function acl:import_user_list(list)
  list:gsub("(%w+):(%d+)",function(id,status)
    self.user_rules[id] = status
  end)
end
function acl:import_group_list(list)
  list:gsub("(%w+):(%d+)",function(id,status)
    self.group_rules[id] = status
  end)
end

return acl
