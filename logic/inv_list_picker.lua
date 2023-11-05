local ALLOWED_PULL_LISTS = {}
ALLOWED_PULL_LISTS["main"] = true
ALLOWED_PULL_LISTS["src"] = true
ALLOWED_PULL_LISTS["dst"] = true
ALLOWED_PULL_LISTS["output"] = true
ALLOWED_PULL_LISTS["fuel"] = true

local ALLOWED_PUSH_LISTS = {}
ALLOWED_PUSH_LISTS["main"] = true
ALLOWED_PUSH_LISTS["src"] = true
ALLOWED_PUSH_LISTS["fuel"] = true
ALLOWED_PUSH_LISTS["input"] = true
ALLOWED_PUSH_LISTS["shift"] = true

-- returns a string of comma separated lists we're allowed to push to at the given pushToPos
local function get_lists(pushToPos, allowedLists)
  logistica.load_position(pushToPos)
  local availableLists = minetest.get_meta(pushToPos):get_inventory():get_lists()
  local pushLists = {}
  for name, _ in pairs(availableLists) do
    if allowedLists[name] then
      table.insert(pushLists, name)
    end
  end
  return pushLists
end

local function list_dropdown(name, itemTable, x, y, default)
  local defaultIndex = 0
  for i, v in ipairs(itemTable) do if default == v then defaultIndex = i end end
  local items = table.concat(itemTable, ",")
  return "dropdown["..x..","..y..";2,0.6;"..name..";"..items..";"..defaultIndex..";false]"
end

function logistica.get_pull_list_dropdown(name, x, y, pullFromPos, default)
  return list_dropdown(name, get_lists(pullFromPos, ALLOWED_PULL_LISTS), x, y, default)
end

function logistica.get_push_list_dropdown(name, x, y, pushToPos, default)
  return list_dropdown(name, get_lists(pushToPos, ALLOWED_PUSH_LISTS), x, y, default)
end

function logistica.is_allowed_pull_list(listName)
  return ALLOWED_PULL_LISTS[listName] == true
end

function logistica.is_allowed_push_list(listName)
  return ALLOWED_PUSH_LISTS[listName] == true
end
