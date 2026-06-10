
local META_SIGNAL_NAME = "signal_name"
local META_DISTANCE    = "distance"
local META_LAST_ERROR  = "last_error"
local META_PREV_SIG    = "prev_signal_state"
local META_OWNER       = "owner"
local MIN_DISTANCE     = 1
local MAX_DISTANCE     = logistica.settings.node_digger_max_distance
local FILTER_SIZE      = 8

function logistica.node_digger_get_signal_name(pos)
  local v = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  return (v and v ~= "") and v or ""
end

function logistica.node_digger_get_distance(pos)
  local v = minetest.get_meta(pos):get_int(META_DISTANCE)
  return (v >= MIN_DISTANCE and v <= MAX_DISTANCE) and v or MIN_DISTANCE
end

function logistica.node_digger_set_distance(pos, d)
  minetest.get_meta(pos):set_int(META_DISTANCE, logistica.clamp(d, MIN_DISTANCE, MAX_DISTANCE))
end

function logistica.node_digger_get_owner(pos)
  return minetest.get_meta(pos):get_string(META_OWNER)
end

function logistica.node_digger_set_owner(pos, playerName)
  minetest.get_meta(pos):set_string(META_OWNER, playerName)
end

local function get_target_pos(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local dist = logistica.node_digger_get_distance(pos)
  local dir  = logistica.get_rot_directions(node.param2).backward
  return vector.add(pos, vector.multiply(dir, dist))
end

function logistica.node_digger_get_target_pos(pos)
  return get_target_pos(pos)
end

function logistica.node_digger_show_target(pos)
  local targetPos = get_target_pos(pos)
  if not targetPos then return end
  logistica.show_input_at(targetPos, tostring(minetest.hash_node_position(pos)))
end

local function can_tool_dig_node(nodename, toolcaps)
  local nodedef = minetest.registered_nodes[nodename]
  if not nodedef then return false end
  local diggable = minetest.get_dig_params(nodedef.groups, toolcaps).diggable
  if not diggable then
    local hand_caps = minetest.registered_items[""].tool_capabilities
    diggable = minetest.get_dig_params(nodedef.groups, hand_caps).diggable
  end
  return diggable
end

local function get_filter_set(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  local filter = {}
  local hasFilter = false
  for i = 1, FILTER_SIZE do
    local stack = inv:get_stack("filter", i)
    if not stack:is_empty() then
      filter[stack:get_name()] = true
      hasFilter = true
    end
  end
  return filter, hasFilter
end

-- Returns (dug: bool, errorKey: string|nil)
-- errorKey nil               = silent fail (no nodedef, protected, or no network)
-- errorKey "owner_offline"   = owner not online
-- errorKey "nothing_to_dig"  = target is air or unloaded
-- errorKey "no_match"        = target doesn't match filter
-- errorKey "wrong_tool"        = tool cannot dig this node type
-- errorKey "tool_too_damaged"  = next dig would break the tool
function logistica.node_digger_try_dig(pos)
  local filterSet, hasFilter = get_filter_set(pos)

  local targetPos = get_target_pos(pos)
  if not targetPos then return false, nil end

  local targetNode = minetest.get_node(targetPos)
  if targetNode.name == "air" or targetNode.name == "ignore" then
    return false, "nothing_to_dig"
  end

  if hasFilter and not filterSet[targetNode.name] then
    return false, "no_match"
  end

  local nodedef = minetest.registered_nodes[targetNode.name]
  if not nodedef or not nodedef.on_dig then return false, nil end

  local ownerName   = logistica.node_digger_get_owner(pos)
  local ownerPlayer = (ownerName ~= "") and minetest.get_player_by_name(ownerName) or nil
  if not ownerPlayer then return false, "owner_offline" end

  if minetest.is_protected(targetPos, ownerName) then return false, nil end

  if not logistica.get_network_id_or_nil(pos) then return false, nil end

  local toolStack = minetest.get_meta(pos):get_inventory():get_stack("tool", 1)
  local toolName  = toolStack:is_empty() and "" or toolStack:get_name()
  local toolCaps  = toolStack:is_empty()
    and minetest.registered_items[""].tool_capabilities
    or toolStack:get_tool_capabilities()
  local on_use    = (not toolStack:is_empty())
    and (minetest.registered_items[toolName] or {}).on_use
    or nil

  if on_use then
    local digNode = minetest.get_node(pos)
    local dir = logistica.get_rot_directions(digNode.param2).backward
    local pointed_thing = {
      type  = "node",
      under = targetPos,
      above = vector.subtract(targetPos, dir),
    }
    local newStack = on_use(toolStack, ownerPlayer, pointed_thing)
    minetest.get_meta(pos):get_inventory():set_stack("tool", 1, newStack or toolStack)
    return true, nil
  end

  if not can_tool_dig_node(targetNode.name, toolCaps) then
    return false, "wrong_tool"
  end

  if not toolStack:is_empty() then
    local digWear = minetest.get_dig_params(nodedef.groups, toolCaps).wear
    if digWear > 0 and toolStack:get_wear() + digWear >= 65535 then
      return false, "tool_too_damaged"
    end
  end

  -- Intercept drops before they reach the player's inventory
  local intercepted = {}
  local origHandleDrops = minetest.handle_node_drops
  minetest.handle_node_drops = function(_, drops, digger)
    if digger == ownerPlayer then
      for _, drop in ipairs(drops) do
        table.insert(intercepted, ItemStack(drop))
      end
    else
      origHandleDrops(_, drops, digger)
    end
  end

  -- Wield the digger's tool so on_dig sees the right item for wear/capabilities
  local prevWielded = ownerPlayer:get_wielded_item()
  ownerPlayer:set_wielded_item(toolStack)

  local ok, err = pcall(nodedef.on_dig, targetPos, targetNode, ownerPlayer)

  -- Save worn tool back to slot and restore owner's hand
  local wornTool = ownerPlayer:get_wielded_item()
  ownerPlayer:set_wielded_item(prevWielded)
  minetest.handle_node_drops = origHandleDrops

  minetest.get_meta(pos):get_inventory():set_stack("tool", 1, wornTool)

  if not ok then
    minetest.log("error", "[logistica] node_digger on_dig failed at "
      .. minetest.pos_to_string(targetPos) .. ": " .. tostring(err))
    return false, nil
  end

  -- Store drops in own "main" inventory; network can pull from there
  local selfInv = minetest.get_meta(pos):get_inventory()
  local cacheNeeded = false
  for _, drop in ipairs(intercepted) do
    if not drop:is_empty() then
      local leftover = selfInv:add_item("main", drop)
      if not leftover:is_empty() then
        minetest.item_drop(leftover, ownerPlayer, targetPos)
      end
      cacheNeeded = true
    end
  end
  if cacheNeeded then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end

  return true, nil
end

function logistica.node_digger_update_infotext(pos)
  local inv       = minetest.get_meta(pos):get_inventory()
  local dist      = logistica.node_digger_get_distance(pos)
  local sigName   = logistica.node_digger_get_signal_name(pos)
  local ownerName = logistica.node_digger_get_owner(pos)
  local lastError = minetest.get_meta(pos):get_string(META_LAST_ERROR)
  local hasFilter = false
  for i = 1, FILTER_SIZE do
    if not inv:get_stack("filter", i):is_empty() then hasFilter = true; break end
  end
  local filterStr = hasFilter and "(filtered)" or "(any)"
  local stateStr
  if lastError == "owner_offline" then
    stateStr = "Paused: owner offline (" .. ownerName .. ")"
  elseif lastError == "nothing_to_dig" then
    stateStr = "Warning: nothing to dig at target"
  elseif lastError == "no_match" then
    stateStr = "Warning: target does not match filter"
  elseif lastError == "wrong_tool" then
    stateStr = "Warning: tool cannot dig target node"
  elseif lastError == "tool_too_damaged" then
    stateStr = "Warning: tool too damaged, replace it"
  elseif lastError ~= "" then
    stateStr = "Error: " .. lastError
  else
    stateStr = "Ready"
  end
  minetest.get_meta(pos):set_string("infotext",
    "Node Digger [" .. ownerName .. "]: " .. filterStr .. " at dist " .. dist .. "\n" ..
    "-> " .. sigName .. "\n" ..
    stateStr
  )
end

function logistica.node_digger_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.node_digger_get_signal_name(pos) then return end
  local meta  = minetest.get_meta(pos)
  local wasOn = meta:get_string(META_PREV_SIG) == "1"
  meta:set_string(META_PREV_SIG, sigIsOn and "1" or "0")
  if not (sigIsOn and not wasOn) then return end
  local dug, errorKey = logistica.node_digger_try_dig(pos)
  if dug then
    meta:set_string(META_LAST_ERROR, "")
  elseif errorKey then
    meta:set_string(META_LAST_ERROR, errorKey)
  end
  logistica.node_digger_update_infotext(pos)
end

function logistica.node_digger_on_connect(pos, networkId)
  local meta    = minetest.get_meta(pos)
  local sigName = logistica.node_digger_get_signal_name(pos)
  if networkId and sigName ~= "" then
    local state = logistica.signal_get_state(networkId, sigName)
    meta:set_string(META_PREV_SIG, state and "1" or "0")
  else
    meta:set_string(META_PREV_SIG, "0")
  end
  logistica.node_digger_update_infotext(pos)
end

function logistica.node_digger_on_disconnect(pos, _networkId)
  minetest.get_meta(pos):set_string(META_PREV_SIG, "0")
  logistica.node_digger_update_infotext(pos)
end

function logistica.node_digger_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then
    local sigName = logistica.node_digger_get_signal_name(pos)
    local state   = logistica.signal_get_state(networkId, sigName)
    minetest.get_meta(pos):set_string(META_PREV_SIG, state and "1" or "0")
  end
  logistica.node_digger_update_infotext(pos)
end
