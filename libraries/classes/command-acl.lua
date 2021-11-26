--Generic ACL extended to work with discord-specific features
local acl = import("classes.acl")
local command_acl = acl:extend("CommandACL")
local table_utils = import("table-utils")
--The following method extends the ACL class to work with rule-specific features,
--such as the role position
function command_acl:check_group(roles)
  local found = false
  local highest_role = nil
  local highest_role_status = nil
  for k,v in pairs(roles) do
    if self.group_rules[v.id] then
      found = true
      if not highest_role then
        highest_role = v
        highest_role_status = self.group_rules[v.id]
      end
      if v.position > highest_role.position then
        highest_role = v
        highest_role_status = self.group_rules[v.id]
      end
    end
  end
  local allow = highest_role_status
  return found,(allow and allow == 1)
end
--The following methods extend the ACL class to add the "perm" permissions
--(the fallback when no rule/user permissions are found)
function command_acl:__init()
  self.user_rules = {}
  self.group_rules = {}
  self.perm_rules = {}
end
function command_acl:check_perm(perms)
   local output = true
   for k,v in pairs(self.perm_rules) do
     if not perms[v] then
       output = false
     end
   end
   return output
end
function command_acl:set_perm_rules(list)
  assert(type(list)=="table","table expected, got "..type(list))
  self.perm_rules = list
end
function command_acl:export_all_lists()
  local lists = {
    users = "",
    groups = "",
    perm = ""
  }
  for k,v in pairs(self.user_rules) do
    lists.users = lists.users..k..":"..tostring(v)..";\n"
  end
  for k,v in pairs(self.group_rules) do
    lists.groups = lists.groups..k..":"..tostring(v)..";\n"
  end
  for k,v in pairs(self.perm_rules) do
    lists.perm = lists.perm..k..":"..tostring(v)..";\n"
  end
  return lists
end
function command_acl:export_perm_list()
  local list = ""
  for k,v in pairs(self.perm_rules) do
    list = list..k..":"..tostring(v)..";\n"
  end
  return list
end
function command_acl:export_snapshot()
  return {
    user_rules = table_utils.deepcopy(self.user_rules),
    group_rules = table_utils.deepcopy(self.group_rules),
    perm_rules = table_utils.deepcopy(self.perm_rules)
  }
end
function command_acl:import_snapshot(t)
  self.user_rules = t.user_rules
  self.group_rules = t.group_rules
  self.perm_rules = t.perm_rules
end
function command_acl:import_perm_list()
  list:gsub("(%w+):(%d+)",function(id,status)
    self.perm_rules[id] = status
  end)
end
return command_acl
