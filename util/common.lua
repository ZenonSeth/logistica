
logistica.TRANSLATOR = minetest.get_translator(logistica.MODNAME)


local META_ON_OFF_KEY = "logonoff"

local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function rand_str(length, seed)
  math.randomseed(seed)
  local ret = {}
  local r
  for i = 1, length do
    r = math.random(1, #charset)
    table.insert(ret, charset:sub(r, r))
  end
  return table.concat(ret)
end

----------------------------------------------------------------
-- global namespaced functions
----------------------------------------------------------------

-- Loads and returns the given position, or nil if its outisde the current bounds
function logistica.load_position(pos)
  if pos.x < -30912 or pos.y < -30912 or pos.z < -30912 or
     pos.x >  30927 or pos.y >  30927 or pos.z >  30927 then return end
  if minetest.get_node_or_nil(pos) then return pos end
  local vm = minetest.get_voxel_manip()
  vm:read_from_map(pos, pos)
	return pos
end

function logistica.swap_node(pos, newName)
  local node = minetest.get_node(pos)
  if node.name ~= newName then
    node.name = newName
    minetest.swap_node(pos, node)
  end
end

function logistica.get_rand_string_for(pos)
  local p1 = rand_str(3, pos.x)
  local p2 = rand_str(3, pos.y)
  local p3 = rand_str(3, pos.z)
  return p1.."-"..p2.."-"..p3
end

function logistica.set_infotext(pos, txt)
  local meta = minetest.get_meta(pos)
  meta:set_string("infotext", txt)
end

function logistica.ttos(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or true
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    local newline = (not skipnewlines and "\n" or "")
    if name then tmp = tmp .. name .. " = " end
    if type(val) == "table" then
        tmp = tmp .."{"..newline
        for k, v in pairs(val) do
            tmp =  tmp..logistica.ttos(v, k, skipnewlines, depth + 1)..","..newline
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then tmp = tmp .. tostring(val)
    elseif type(val) == "string" then tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then tmp = tmp .. (val and "true" or "false")
    else tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\"" end
    return tmp
end

function logistica.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function logistica.start_node_timer(pos, time)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    timer:start(time)
    return timer
  end
  return nil
end

function logistica.is_machine_on(pos)
  local meta = minetest.get_meta(pos)
  return meta:get_int(META_ON_OFF_KEY) > 0
end

-- toggles the state and returns the new state (true for on, false for off)
function logistica.toggle_machine_on_off(pos)
  logistica.load_position(pos)
  local node = minetest.get_node(pos)
  local meta = minetest.get_meta(pos)
  local newState = (meta:get_int(META_ON_OFF_KEY) + 1) % 2
  local def = minetest.registered_nodes[node.name]
  if def and def.logistica and def.logistica.on_power then
    def.logistica.on_power(pos, newState > 0)
    meta:set_int(META_ON_OFF_KEY, newState)
    return newState > 0
  end
  return nil
end

-- `isOn` is optional
-- `extraText` is optional
-- `overrideState` is optional
function logistica.set_node_tooltip_from_state(pos, extraText, overrideState)
  if extraText == nil then extraText = "" else extraText = "\n"..extraText end
  local isOn = overrideState
  if isOn == nil then isOn = logistica.is_machine_on(pos) end
  logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  local node = minetest.get_node(pos)
  local isOnText = (minetest.registered_nodes[node.name].logistica.on_power and (isOn and "Running" or "Stopped")) or ""
  local text = minetest.registered_nodes[node.name].description..extraText.."\n"..isOnText
  meta:set_string("infotext", text)
end

-- returns a value in the range [1,#listSize], incrementing the slot each 
-- time this is called, and returining a slot that has an item
-- if there's no item in the list, it will return 0
function logistica.get_next_filled_item_slot(nodeMeta, listName)
  local metaKey = listName.."rot"
  local inv = nodeMeta:get_inventory()
  local listSize = inv:get_list(listName)
  if not listSize then return 0 end
  listSize = #listSize
  local startPos = nodeMeta:get_int(metaKey) or 0
  for i = startPos, startPos + listSize do
    i = (i % listSize) + 1
    local items = inv:get_stack(listName, i)
    if items:get_count() > 0 then
      nodeMeta:set_int(metaKey, i)
      return i
    end
  end
  nodeMeta:set_int(metaKey, 0)
  return 0
end

-- takes a list of ItemStacks and returns a single string representation
function logistica.inv_list_to_table(list)
  local itemstackTable = {}
  for k,v in ipairs(list) do
    itemstackTable[k] = v and v:to_string() or ""
  end
  return itemstackTable
end

function logistica.table_to_inv_list(table)
  local list = {}
  for k,v in ipairs(table) do
    if v == nil then list[k] = ""
    else list[k] = ItemStack(v) end
  end
  return list
end

-- returns a serialized string of the inventory
function logistica.serialize_inv(inv)
  local lists = inv:get_lists()
  local invTable = {}
  for name, list in pairs(lists) do
    invTable[name] = logistica.inv_list_to_table(list)
  end
  return minetest.serialize(invTable)
end

-- takes a inventory serialized string and returns a table
function logistica.deserialize_inv(serializedInv)
  local strTable = minetest.deserialize(serializedInv)
  if not strTable then return {} end
  local liveTable = {}
  for name, listStrTable in pairs(strTable) do
    liveTable[name] = logistica.table_to_inv_list(listStrTable)
  end
  return liveTable
end

-- returns a timer that will not do anything is power is turned off
function logistica.on_timer_powered(func)
  return function(pos, elapsed)
    if logistica.is_machine_on(pos) then return func(pos, elapsed)
		else return false end
  end
end

function logistica.table_is_empty(table)
  return table == nil or (next(table) == nil)
end

-- returns true a given percentage of the time
function logistica.random_chance(percent)
  return percent >= math.random(1, 100)
end

function logistica.table_map(table, func)
  local t = {}
  for k,v in pairs(table) do t[k] = func(v) end
  return t
end

function logistica.table_to_list_indexed(table, func)
  local t = {}
  local index = 0
  for k,v in pairs(table) do index = index + 1; t[index] = func(k, v) end
  return t
end

function logistica.round(x)
	if x >= 0 then
		return math.floor(x + 0.5)
	end
	return math.ceil(x - 0.5)
end
