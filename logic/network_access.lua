local META_ACCESS_PLAYERS = "access_players"
local META_HIDE_WITH_PROTECTION = "hide_with_protection"

local function get_controller_meta_for_pos(pos)
  local network = logistica.get_network_or_nil(pos, nil, true)
  if not network then return nil end
  local controllerPos = minetest.get_position_from_hash(network.controller)
  return minetest.get_meta(controllerPos)
end

local function is_in_access_list(controllerMeta, playerName)
  local accessList = controllerMeta:get_string(META_ACCESS_PLAYERS)
  if accessList == "" then return false end
  for _, name in ipairs(string.split(accessList, ",")) do
    if string.trim(name) == playerName then return true end
  end
  return false
end

-- Returns true if playerName may interact with machines on this network
-- (take/move/put items, press buttons). Allows if the player has area access
-- OR is in the controller's "Give Access To" list.
-- Falls back to area-protection-only when the machine has no network.
function logistica.player_has_network_access(pos, playerName)
  if not minetest.is_protected(pos, playerName) then return true end
  local controllerMeta = get_controller_meta_for_pos(pos)
  if not controllerMeta then return false end
  return is_in_access_list(controllerMeta, playerName)
end

-- Returns true if the formspec for a machine at pos should be hidden from playerName.
-- When the controller "Hide network content" checkbox is unchecked (default), returns
-- false for all players so anyone can view. When checked, behaves like the old
-- area-protection check. Falls back to area-protection when the machine has no network.
function logistica.should_hide_from_player(pos, playerName)
  local controllerMeta = get_controller_meta_for_pos(pos)
  if not controllerMeta then
    return minetest.is_protected(pos, playerName)
  end
  if controllerMeta:get_int(META_HIDE_WITH_PROTECTION) == 1 then
    return minetest.is_protected(pos, playerName)
  end
  return false
end
