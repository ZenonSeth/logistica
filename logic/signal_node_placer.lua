
local META_SIGNAL_NAME = "signal_name"
local META_DISTANCE    = "distance"
local META_LAST_ERROR  = "last_error"
local META_PREV_SIG    = "prev_signal_state"
local META_OWNER       = "owner"
local MIN_DISTANCE     = 1
local MAX_DISTANCE     = 16

function logistica.node_placer_get_signal_name(pos)
  local v = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  return (v and v ~= "") and v or ""
end

function logistica.node_placer_get_distance(pos)
  local v = minetest.get_meta(pos):get_int(META_DISTANCE)
  return (v >= MIN_DISTANCE and v <= MAX_DISTANCE) and v or MIN_DISTANCE
end

function logistica.node_placer_set_distance(pos, d)
  minetest.get_meta(pos):set_int(META_DISTANCE, logistica.clamp(d, MIN_DISTANCE, MAX_DISTANCE))
end

function logistica.node_placer_get_filter(pos)
  local stack = minetest.get_meta(pos):get_inventory():get_stack("filter", 1)
  return stack:get_name()
end

function logistica.node_placer_get_owner(pos)
  return minetest.get_meta(pos):get_string(META_OWNER) or ""
end

function logistica.node_placer_set_owner(pos, playerName)
  minetest.get_meta(pos):set_string(META_OWNER, playerName)
end

local function get_target_pos(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local dist = logistica.node_placer_get_distance(pos)
  local dir  = logistica.get_rot_directions(node.param2).backward
  return vector.add(pos, vector.multiply(dir, dist))
end

function logistica.node_placer_get_target_pos(pos)
  return get_target_pos(pos)
end

function logistica.node_placer_show_target(pos)
  local targetPos = get_target_pos(pos)
  if not targetPos then return end
  logistica.show_output_at(targetPos, tostring(minetest.hash_node_position(pos)))
end

-- Returns (placed: bool, errorKey: string|nil)
-- errorKey nil              = silent fail (no filter, or target protected)
-- errorKey "target_blocked" = target position is occupied
-- errorKey "no_item"        = item not found in network
-- errorKey "owner_offline"  = owner player not currently online
function logistica.node_placer_try_place(pos)
  local filterName = logistica.node_placer_get_filter(pos)
  if filterName == "" then return false, nil end

  local targetPos = get_target_pos(pos)
  if not targetPos then return false, nil end

  local existing    = minetest.get_node(targetPos)
  local existingDef = minetest.registered_nodes[existing.name]
  if not existingDef or not existingDef.buildable_to then return false, "target_blocked" end

  local ownerName   = logistica.node_placer_get_owner(pos)
  local ownerPlayer = (ownerName ~= "") and minetest.get_player_by_name(ownerName) or nil
  if not ownerPlayer then return false, "owner_offline" end

  if minetest.is_protected(targetPos, ownerName) then return false, nil end

  local network = logistica.get_network_or_nil(pos)
  if not network then return false, "no_item" end

  local placed = false
  logistica.take_stack_from_network(
    ItemStack(filterName .. " 1"),
    network,
    function(stack)
      core.place_node(targetPos, {name = stack:get_name()}, ownerPlayer)
      placed = true
      return 0
    end,
    true, false, false
  )
  return placed, placed and nil or "no_item"
end

function logistica.node_placer_update_infotext(pos)
  local filterName = logistica.node_placer_get_filter(pos)
  local dist       = logistica.node_placer_get_distance(pos)
  local sigName    = logistica.node_placer_get_signal_name(pos)
  local ownerName  = logistica.node_placer_get_owner(pos)
  local filterStr  = (filterName ~= "") and ItemStack(filterName):get_short_description() or "(none)"
  local lastError  = minetest.get_meta(pos):get_string(META_LAST_ERROR)
  local stateStr
  if lastError == "no_item" then
    stateStr = "Error: item not found in network"
  elseif lastError == "owner_offline" then
    stateStr = "Paused: owner offline (" .. ownerName .. ")"
  elseif lastError == "target_blocked" then
    stateStr = "Warning: target position is occupied"
  else
    stateStr = "Ready"
  end
  minetest.get_meta(pos):set_string("infotext",
    "Node Placer [" .. ownerName .. "]: " .. filterStr .. " at dist " .. dist .. "\n" ..
    "-> " .. sigName .. "\n" ..
    stateStr
  )
end

function logistica.node_placer_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.node_placer_get_signal_name(pos) then return end
  local meta  = minetest.get_meta(pos)
  local wasOn = meta:get_string(META_PREV_SIG) == "1"
  meta:set_string(META_PREV_SIG, sigIsOn and "1" or "0")
  if not (sigIsOn and not wasOn) then return end -- only act on rising edge
  local placed, errorKey = logistica.node_placer_try_place(pos)
  if placed then
    meta:set_string(META_LAST_ERROR, "")
  elseif errorKey then
    meta:set_string(META_LAST_ERROR, errorKey)
  end
  logistica.node_placer_update_infotext(pos)
end

function logistica.node_placer_on_connect(pos, networkId)
  local meta    = minetest.get_meta(pos)
  local sigName = logistica.node_placer_get_signal_name(pos)
  if networkId and sigName ~= "" then
    local state = logistica.signal_get_state(networkId, sigName)
    meta:set_string(META_PREV_SIG, state and "1" or "0")
  else
    meta:set_string(META_PREV_SIG, "0")
  end
  logistica.node_placer_update_infotext(pos)
end

function logistica.node_placer_on_disconnect(pos, _networkId)
  minetest.get_meta(pos):set_string(META_PREV_SIG, "0")
  logistica.node_placer_update_infotext(pos)
end

function logistica.node_placer_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then
    local sigName = logistica.node_placer_get_signal_name(pos)
    local state   = logistica.signal_get_state(networkId, sigName)
    minetest.get_meta(pos):set_string(META_PREV_SIG, state and "1" or "0")
  end
  logistica.node_placer_update_infotext(pos)
end
