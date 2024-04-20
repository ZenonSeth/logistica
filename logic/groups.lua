
local logistica_groups = {}
local network_groups = {}

logistica.TIER_ALL = "logistica_all_tiers"
logistica.GROUP_ALL = "group:" .. logistica.TIER_ALL
logistica.TIER_CABLE_OFF = "logistica_cable_off"
logistica.GROUP_CABLE_OFF = "group:" .. logistica.TIER_CABLE_OFF
logistica.TIER_ACCESS_POINT = "logistica_acspt"

-- default groups, and shortcut for checking them

local function make_group_table(groupName, networkGroup)
  return {
    name = groupName,
    networkGroup = networkGroup,
    -- returns true if the given nodeName belongs to this group, false otherwise
    is = function(nodeName)
      return logistica.group_check(groupName, nodeName)
    end,
    -- returns true if registering the node name succeeds, false if the node name already exists
    register = function(nodeName)
      return logistica.group_register_node(groupName, nodeName)
    end,
    -- returns which network group this general group maps to
    network_group = function()
      return logistica.group_get_mapped_network_group(groupName)
    end
  }
end

-- The default network groups of Logistica.
-- These have special meaning and are treated with special actions. Each node group above must
-- map to one network group, though multiple node groups can map to the same network group<br>
-- More can be registered via logistica.network_group_register
logistica.NETWORK_GROUPS = {
  cables = "cables",
  requesters = "requesters",
  injectors = "injectors",
  suppliers = "suppliers",
  mass_storage = "mass_storage",
  item_storage = "item_storage",
  misc = "misc",
  trashcans = "trashcans",
  reservoirs = "reservoirs",
  wireless_transmitters = "wireless_transmitters",
  wireless_receivers = "wireless_receivers",
}

-- The default node groups of Logistica, with utility shorthand attached.<br>
-- More can be registered via logistica.group_register_type, and other related functions (see API below)
logistica.GROUPS = {
  cables = make_group_table("cables", logistica.NETWORK_GROUPS.cables),
  controllers = make_group_table("controllers", nil),
  injectors = make_group_table("injectors", logistica.NETWORK_GROUPS.injectors),
  requesters = make_group_table("requesters", logistica.NETWORK_GROUPS.requesters),
  suppliers = make_group_table("suppliers", logistica.NETWORK_GROUPS.suppliers),
  crafting_suppliers = make_group_table("craftsups", logistica.NETWORK_GROUPS.suppliers),
  bucket_emptiers = make_group_table("bucket_emptiers", logistica.NETWORK_GROUPS.suppliers),
  bucket_fillers = make_group_table("bucket_fillers", logistica.NETWORK_GROUPS.suppliers),
  pumps = make_group_table("pumps", logistica.NETWORK_GROUPS.misc),
  mass_storage = make_group_table("mass_storage", logistica.NETWORK_GROUPS.mass_storage),
  item_storage = make_group_table("item_storage", logistica.NETWORK_GROUPS.item_storage),
  misc_machines = make_group_table("misc_machines", logistica.NETWORK_GROUPS.misc),
  trashcans = make_group_table("trashcans", logistica.NETWORK_GROUPS.trashcans),
  vaccuum_suppliers = make_group_table("vaccuum_suppliers", logistica.NETWORK_GROUPS.suppliers),
  reservoirs = make_group_table("reservoirs", logistica.NETWORK_GROUPS.reservoirs),
  wireless_transmitters = make_group_table("wireless_transmitters", logistica.NETWORK_GROUPS.wireless_transmitters),
  wireless_receivers = make_group_table("wireless_receivers", logistica.NETWORK_GROUPS.wireless_receivers),
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--------------------------------
-- Helpers
--------------------------------

-- this is a utility function that checks if a nodeName is in any logistica node group, except cables
function logistica.is_machine(nodeName)
  local group = logistica.group_get_node_group_name(nodeName)
  return group ~= nil and group ~= logistica.GROUPS.cables.name
end

-- shorthand for calling group_get_node_group_name followed by group_get_mapped_network_group
-- returns nil if it has no node group, or it maps to no network group
function logistica.get_network_group_for_node_name(nodeName)
  local nodeGroup = logistica.group_get_node_group_name(nodeName)
  if not nodeGroup then return nil end
  return logistica.group_get_mapped_network_group(nodeGroup)
end

--------------------------------
-- Node Groups
--------------------------------

-- Logistica node group registration. Node groups are mostly used for looking up types of nodes, and
-- to also map them to network groups, to allow them to connect to a network.<br>
-- returns true/false if registering of a new group type succeeds<br>
-- `groupName` must be non-nil, string and unique - the name of the node group to register<br>
-- `networGroupItMapsTo` should be an existing network group (e.g. one of the default or a newly registered one)
-- or it could be `nil` if the given node group is not meant to connect to a network
function logistica.group_register_type(groupName, networkGroupItMapsTo)
  if type(groupName) ~= "string" or logistica_groups[groupName] ~= nil then return false end
  logistica_groups[groupName] = { _networkGroup = networkGroupItMapsTo }
  return true
end

-- returns true/false if the given group exists and the nodeName wasn't already part of that group
function logistica.group_register_node(groupName, nodeName)
  if not logistica_groups[groupName] or logistica_groups[groupName][nodeName] ~= nil then return false end
  logistica_groups[groupName][nodeName] = true
end

-- returns true if groupName exists and nodeName is a registered member of that group
function logistica.group_check(groupName, nodeName)
  return logistica_groups[groupName] and logistica_groups[groupName][nodeName]
end

-- returns a copy of the group names as a lua set {groupName = true, groupTwo = true, ...}
function logistica.group_get_all_group_names()
  local copy = {}
  for k, _ in pairs(logistica_groups) do copy[k] = true end
  return copy
end

-- returns the group name (a string) to which the given nodeName belongs to, or nil if it doesn't belong to any group
function logistica.group_get_node_group_name(nodeName)
  for k, v in pairs(logistica_groups) do
    if v[nodeName] then return k end
  end
  return nil
end

-- returns a lua list of group all the nodes belonging to this group,
-- or empty list if no such group exists, or is empty
function logistica.group_get_all_nodes_for_group(groupName)
  local nodeNames = {}
  local index = 1
  for nodeName, _ in pairs(logistica_groups[groupName] or {}) do
    if nodeName ~= "_networkGroup" then
      nodeNames[index] = nodeName
      index = index + 1
    end
  end
  return nodeNames
end

--------------------------------
-- Network groups
--------------------------------

-- Network Group registration
-- These should be used along side logistica.group.group_register_type to map those general group types
-- to these network-specific group types<br>
-- You can re-use the default groups if necessary, so long as the new nodes registered provide same interaction capabilities.<br>
-- Any of these groups can be accessed via logistica.get_network_or_nil(..).network_group_name -
-- which contains a lua set of hashed node positions that are connected to this network<br>
-- `group_name` must be lowercase only, and contain no spaces - if any are present, they will be removed and then the group registered<br>
-- returns nil if registration failed, or the actual registered group name if it succeeds
-- (which will be identical to passed in group_name if that followed all the requirements are followed)
function logistica.network_group_register(group_name)
  local lname = group_name:lower():gsub(" ", "")
  if network_groups[lname] then return nil end
  network_groups[lname] = true
  return lname
end

-- returns which network group this general group maps to,
-- or nil if the given group doesn't exist, or it doesn't map to any network group
function logistica.group_get_mapped_network_group(groupName)
  if not logistica_groups[groupName] then return nil end
  return logistica_groups[groupName]._networkGroup
end

-- returns true/false if the network group has already been registered
function logistica.network_group_exists(group_name)
  local lname = group_name:lower():gsub(" ", "")
  return network_groups[lname] ~= nil
end

----------------------------------------------------------------
-- Register all the default/built-in network groups, and then all node groups
----------------------------------------------------------------

for _, v in pairs(logistica.NETWORK_GROUPS) do
  logistica.network_group_register(v)
end

for _, v in pairs(logistica.GROUPS) do
  logistica.group_register_type(v.name, v.networkGroup)
end

-- due to this copy, this had to be placed below the registration
local network_groups_copy = table.copy(network_groups)
-- returns a copy of all the network groups as a lua set<br>
-- WARNING The copy is static, so treat it as read-only!
function logistica.network_group_get_all()
  return network_groups_copy
end
