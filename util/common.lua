
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

-- Lowercases, strips any character that isn't a-z, 0-9, or _.
function logistica.sanitize_signal_name(name)
  if not name then return "" end
  return name:lower():gsub("[^a-z0-9_]", "")
end

-- formspec escape translation
logistica.FTRANSLATOR = function (...)
return minetest.formspec_escape(logistica.TRANSLATOR(...))
end

-- Loads and returns the given position, or nil if its outisde the current bounds
function logistica.load_position(pos)
  if pos.x < -30912 or pos.y < -30912 or pos.z < -30912 or
     pos.x >  30927 or pos.y >  30927 or pos.z >  30927 then return end
  if minetest.get_node_or_nil(pos) then return pos end
  local vm = minetest.get_voxel_manip()
  vm:read_from_map(pos, pos)
  return pos
end

-- Places a node at pos, replicating core.item_place_node behaviour but using
-- playerName (string) for protection checks so it works when the owner is offline.
-- The player object is resolved internally and only used where available.
-- Returns true on success, false on failure.
function logistica.place_node(pos, node, playerName)
  local player = (playerName and playerName ~= "")
    and minetest.get_player_by_name(playerName) or nil

  logistica.load_position(pos)

  if minetest.is_protected(pos, playerName or "") then
    minetest.record_protection_violation(pos, playerName or "")
    return false
  end

  local def = minetest.registered_nodes[node.name]
  if not def then return false end

  local oldnode = minetest.get_node(pos)

  local param2 = 0
  if def.place_param2 ~= nil then
    param2 = def.place_param2
  elseif (def.paramtype2 == "wallmounted"
      or def.paramtype2 == "colorwallmounted") then
    local belowPos = vector.new(pos.x, pos.y - 1, pos.z)
    param2 = minetest.dir_to_wallmounted(vector.subtract(belowPos, pos))
  elseif (def.paramtype2 == "facedir" or def.paramtype2 == "colorfacedir"
      or def.paramtype2 == "4dir" or def.paramtype2 == "color4dir") and player then
    local playerPos = player:get_pos()
    if playerPos then
      param2 = minetest.dir_to_facedir(vector.subtract(pos, playerPos))
    end
  end

  local newnode = {name = node.name, param1 = 0, param2 = param2}
  minetest.add_node(pos, newnode)

  if def.sounds and def.sounds.place then
    minetest.sound_play(def.sounds.place, {
      pos = pos,
      exclude_player = playerName or "",
    }, true)
  end

  local itemstack = ItemStack(node.name)
  local belowPos = vector.new(pos.x, pos.y - 1, pos.z)
  local pointed_thing = {type = "node", under = belowPos, above = pos}

  if def.after_place_node then
    local ok, err = pcall(def.after_place_node, vector.copy(pos), player,
      itemstack, pointed_thing)
    if not ok then
      minetest.log("warning", "[logistica] after_place_node for " .. node.name
        .. " at " .. minetest.pos_to_string(pos) .. ": " .. tostring(err))
    end
  end

  for _, callback in ipairs(minetest.registered_on_placenodes) do
    local ok, err = pcall(callback, vector.copy(pos), newnode, player,
      oldnode, itemstack, pointed_thing)
    if not ok then
      minetest.log("warning", "[logistica] on_placenode callback: " .. tostring(err))
    end
  end

  return true
end

-- Digs a node at pos, replicating core.node_dig behaviour but using playerName
-- (string) for protection checks so it works when the owner is offline.
-- toolStack is the ItemStack of the tool to dig with (or nil for bare hands).
-- The player object is resolved internally and only used where available.
-- Does NOT apply tool wear (matching the signal digger's existing design).
-- Returns the list of dropped ItemStacks, or nil on failure.
function logistica.dig_node(pos, node, playerName, toolStack)
  local player = (playerName and playerName ~= "")
    and minetest.get_player_by_name(playerName) or nil

  local def = minetest.registered_nodes[node.name]
  if def and (not def.diggable or (def.can_dig and not def.can_dig(vector.copy(pos), player))) then
    return nil
  end

  if minetest.is_protected(pos, playerName or "") then
    minetest.record_protection_violation(pos, playerName or "")
    return nil
  end

  local wielded = toolStack or ItemStack()
  local drops = minetest.get_node_drops(node, wielded:get_name())

  if def and def.preserve_metadata then
    local oldmeta = minetest.get_meta(pos):to_table().fields
    local drop_stacks = {}
    for k, v in pairs(drops) do
      drop_stacks[k] = ItemStack(v)
    end
    drops = drop_stacks
    pcall(def.preserve_metadata, vector.copy(pos),
      {name = node.name, param1 = node.param1, param2 = node.param2},
      oldmeta, drops)
  end

  local oldmetadata = nil
  if def and def.after_dig_node then
    oldmetadata = minetest.get_meta(pos):to_table()
  end

  minetest.remove_node(pos)

  if def and def.sounds and def.sounds.dug then
    minetest.sound_play(def.sounds.dug, {
      pos = pos,
      exclude_player = playerName or "",
    }, true)
  end

  if def and def.after_dig_node then
    pcall(def.after_dig_node, vector.copy(pos),
      {name = node.name, param1 = node.param1, param2 = node.param2},
      oldmetadata, player)
  end

  for _, callback in ipairs(minetest.registered_on_dignodes) do
    pcall(callback, vector.copy(pos),
      {name = node.name, param1 = node.param1, param2 = node.param2},
      player)
  end

  local result = {}
  for _, item in ipairs(drops) do
    table.insert(result, ItemStack(item))
  end
  return result
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
    if skipnewlines == nil then skipnewlines = true end
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

function logistica.start_node_timer(pos, time, optAddRandomOffset)
  local timer = minetest.get_node_timer(pos)
  if not timer:is_started() then
    if optAddRandomOffset then time = time + math.random() / 2 end
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
    meta:set_int(META_ON_OFF_KEY, newState)
    def.logistica.on_power(pos, newState > 0)
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
  local isOnText = (minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].logistica and minetest.registered_nodes[node.name].logistica.on_power and (isOn and "Running" or "Stopped")) or ""
  local nodeDef = minetest.registered_nodes[node.name]
  local text = (nodeDef and nodeDef.description or "")..extraText.."\n"..isOnText
  meta:set_string("infotext", text)
end

function logistica.append_makes_infotext(pos, itemstack)
  local meta = minetest.get_meta(pos)
  local existing = meta:get_string("infotext")
  existing = existing:gsub("\nMakes: [^\n]*$", "")
  local desc = (not itemstack:is_empty()) and ("\nMakes: " .. itemstack:get_short_description()) or ""
  meta:set_string("infotext", existing .. desc)
end

function logistica.append_recipe_infotext(pos, inputStack, outputStack)
  local meta = minetest.get_meta(pos)
  local existing = meta:get_string("infotext")
  existing = existing:gsub("\nRecipe: [^\n]*$", "")
  local desc = (not outputStack:is_empty())
    and ("\nRecipe: "..inputStack:get_short_description().." -> "..outputStack:get_short_description())
    or ""
  meta:set_string("infotext", existing .. desc)
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
  for k,v in pairs(table) do index = index + 1; t[index] = func(k, v, index) end
  return t
end

-- filter a list (aka indexed table), return new list with selected elements
-- selectFunc must return true if we add the element, false if we exclude it
function logistica.list_filter(table, selectFunc)
  local r = {}
  local index = 0
  for _,v in ipairs(table) do if selectFunc(v) then index = index + 1 ; r[index] = v end end
  return r
end

function logistica.round(x)
  if x >= 0 then
    return math.floor(x + 0.5)
  end
  return math.ceil(x - 0.5)
end

function logistica.format_count(n)
  if n >= 1000000 then
    local v = n / 1000000
    if v >= 10 then return math.floor(v + 0.5).."M" end
    return string.format("%.1f", v).."M"
  elseif n >= 1000 then
    local v = n / 1000
    if v >= 10 then return math.floor(v + 0.5).."k" end
    return string.format("%.1f", v).."k"
  end
  return tostring(n)
end
