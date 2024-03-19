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

-- this MUST be a subset of the allowed push list above
local logisticaBucketEmptierAllowedPush = {
  ["input"] = true,
}

local function get_lists(targetPosition, usePushLists)
  logistica.load_position(targetPosition)
  local node = minetest.get_node(targetPosition)

  local allowedLists = {}
  if logistica.GROUPS.bucket_emptiers.is(node.name) then
    if usePushLists then allowedLists = logisticaBucketEmptierAllowedPush
    else return {} end -- can only push to bucket emptier, it acts as a supplier so no need to pull
  elseif logistica.is_machine(node.name) then return {}
  elseif usePushLists then allowedLists = allowedPush
  else   allowedLists = allowedPull end

  local availableLists = minetest.get_meta(targetPosition):get_inventory():get_lists()
  local lists = {}
  for name, _ in pairs(availableLists) do
    if allowedLists[name] then
      table.insert(lists, name)
    end
  end
  return lists
end

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

function logistica.is_allowed_pull_list(listName)
  return allowedPull[listName] == true
end

function logistica.is_allowed_push_list(listName)
  return allowedPush[listName] == true
end

function logistica.add_allowed_push_list(listName)
  if not listName then return end
  allowedPush[listName] = true
end

function logistica.add_allowed_pull_list(listName)
  if not listName then return end
  allowedPull[listName] = true
end
