local allowedPull = {}
allowedPull["main"] = true
--allowedPull["src"] = true
allowedPull["dst"] = true
allowedPull["output"] = true
--allowedPull["fuel"] = true

local allowedPush = {}
allowedPush["main"] = true
allowedPush["src"] = true
allowedPush["fuel"] = true
allowedPush["input"] = true
allowedPush["shift"] = true

local function get_lists(targetPosition, allowedLists)
  logistica.load_position(targetPosition)
  local availableLists = minetest.get_meta(targetPosition):get_inventory():get_lists()
  local pushLists = {}
  for name, _ in pairs(availableLists) do
    if allowedLists[name] then
      table.insert(pushLists, name)
    end
  end
  return pushLists
end

----------------------------------------------------------------
-- API
----------------------------------------------------------------

-- returns a string of comma separated lists allowed to push to at the given position
function logistica.get_push_lists(targetPosition)
  return get_lists(targetPosition, allowedPush)
end

-- returns a string of comma separated lists allowed to pull to at the given position
function logistica.get_pull_lists(targetPosition)
  return get_lists(targetPosition, allowedPull)
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

