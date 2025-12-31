local allowedPull = {
  ["main"] = true,
  --["src"] = true,
  ["dst"] = true,
  ["output"] = true,
  --["fuel"] = true,
}

local allowedPush = {
  ["main"] = true,
  ["src"] = true,
  ["fuel"] = true,
  ["input"] = true,
  ["shift"] = true,
}

local disallowedPullLists = {
  -- to be filled in on a mod by mod basis
}

local disallowedPushLists = {
  -- to be filled in on a mod by mod basis
}

local allowedPullListsByNode = {
  -- to be filled in on a mod by mod basis
}

local allowedPushListsByNode = {
  -- to be filled in on a mod by mod basis
}

-- this MUST be a subset of the allowed push list above
local logisticaBucketEmptierAllowedPush = {
  ["input"] = true,
}

local function get_lists(targetPosition, usePushLists)
  logistica.load_position(targetPosition)
  local node = minetest.get_node(targetPosition)

  local allowedLists = {}
  local disallowedLists = {}
  local allowedForNode = {}
  if logistica.GROUPS.bucket_emptiers.is(node.name) then
    if usePushLists then
      allowedLists = logisticaBucketEmptierAllowedPush
      disallowedLists = {}
    else return {} end -- can only push to bucket emptier, it acts as a supplier so no need to pull
  elseif logistica.is_machine(node.name) then return {}
  elseif usePushLists then
    allowedLists = allowedPush
    disallowedLists = disallowedPushLists
    allowedForNode = allowedPushListsByNode[node.name] or {}
  else
    allowedLists = allowedPull
    disallowedLists = disallowedPullLists
    allowedForNode = allowedPullListsByNode[node.name] or {}
  end

  local availableLists = minetest.get_meta(targetPosition):get_inventory():get_lists()
  local lists = {}
  for name, _ in pairs(availableLists) do
    if (allowedLists[name] or allowedForNode[name])
      and not (disallowedLists[node.name] and disallowedLists[node.name][name]) then
      table.insert(lists, name)
    end
  end
  return lists
end

local function is_not_str(o) return type(o) ~= "string" end

----------------------------------------------------------------
-- API
----------------------------------------------------------------

-- returns a string of comma separated lists allowed to push to at the given position
function logistica.get_push_lists(targetPosition)
  return get_lists(targetPosition, true)
end

-- returns a string of comma separated lists allowed to pull to at the given position
function logistica.get_pull_lists(targetPosition)
  return get_lists(targetPosition, false)
end

-- nodeName is used to check against mod-specific disallowed lists
-- returns true if list is allowed pull list for this node, false if not
function logistica.is_allowed_pull_list(listName, nodeName)
  if disallowedPullLists[nodeName] and disallowedPullLists[nodeName][listName] then return false end
  return allowedPull[listName] == true or (allowedPullListsByNode[nodeName] or {})[listName] == true
end

-- nodeName is used to check against mod-specific disallowed lists
-- returns true if list is allowed push list for this node, false if not
function logistica.is_allowed_push_list(listName, nodeName)
  if disallowedPushLists[nodeName] and disallowedPushLists[nodeName][listName] then return false end
  return allowedPush[listName] == true or (allowedPushListsByNode[nodeName] or {})[listName] == true
end

function logistica.add_allowed_push_list(listName)
  if is_not_str(listName) then return end
  allowedPush[listName] = true
end

function logistica.add_allowed_pull_list(listName)
  if is_not_str(listName) then return end
  allowedPull[listName] = true
end

function logistica.add_allowed_push_list_for_node(nodeName, listName)
  if is_not_str(listName) or is_not_str(nodeName) then return end
  if not allowedPushListsByNode[nodeName] then allowedPushListsByNode[nodeName] = {} end
  allowedPushListsByNode[nodeName][listName] = true
end

function logistica.add_allowed_pull_list_for_node(nodeName, listName)
  if is_not_str(listName) or is_not_str(nodeName) then return end
  if not allowedPullListsByNode[nodeName] then allowedPullListsByNode[nodeName] = {} end
  allowedPullListsByNode[nodeName][listName] = true
end

-- nodeName and listName must be strings
function logistica.add_disallowed_pull_list(nodeName, listName)
  if is_not_str(listName) or is_not_str(nodeName) then return end
  if not disallowedPullLists[nodeName] then disallowedPullLists[nodeName] = {} end
  disallowedPullLists[nodeName][listName] = true
end

-- nodeName and listName must be strings
function logistica.add_disallowed_push_list(nodeName, listName)
  if is_not_str(listName) or is_not_str(nodeName) then return end
  if not disallowedPushLists[nodeName] then disallowedPushLists[nodeName] = {} end
    disallowedPushLists[nodeName][listName] = true
end


-- a safer way to get inv list, returns an empty table if something goes wrong
function logistica.get_list(inventory, listName)
  if not inventory or is_not_str(listName) then return {} end
  return inventory:get_list(listName) or {}
end
