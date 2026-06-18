local META_ACCESS_PLAYERS = "access_players"
local META_HIDE_WITH_PROTECTION = "hide_with_protection"
local META_OWNER = "owner"

local function get_controller_meta_for_pos(pos)
  local network = logistica.get_network_or_nil(pos, nil, true)
  if not network then return nil end
  local controllerPos = minetest.get_position_from_hash(network.controller)
  return minetest.get_meta(controllerPos)
end

local function is_network_owner(controllerMeta, playerName)
  local owner = controllerMeta:get_string(META_OWNER)
  return owner ~= "" and owner == playerName
end

local function is_in_access_list(controllerMeta, playerName)
  local accessList = controllerMeta:get_string(META_ACCESS_PLAYERS)
  if accessList == "" then return false end
  for _, name in ipairs(string.split(accessList, ",")) do
    local trimmed = string.trim(name)
    if trimmed:upper() == "<ALL>" then return true end
    if trimmed == playerName then return true end
  end
  return false
end

-- Returns true if playerName may interact with machines on this network
-- (take/move/put items, press buttons). The network owner always has access.
-- Others are allowed if they have area protection access OR are in the
-- controller's "Give Access To" list.
-- Falls back to area-protection-only when the machine has no network.
function logistica.player_has_network_access(pos, playerName)
  local controllerMeta = get_controller_meta_for_pos(pos)
  if controllerMeta and is_network_owner(controllerMeta, playerName) then return true end
  if not minetest.is_protected(pos, playerName) then return true end
  if not controllerMeta then return false end
  return is_in_access_list(controllerMeta, playerName)
end

-- Returns true if the formspec for a machine at pos should be hidden from playerName.
-- The network owner always sees the formspec.
-- When the controller "Hide network content" checkbox is unchecked (default), returns
-- false for all players so anyone can view. When checked, behaves like the old
-- area-protection check. Falls back to area-protection when the machine has no network.
function logistica.should_hide_from_player(pos, playerName)
  local controllerMeta = get_controller_meta_for_pos(pos)
  if controllerMeta and is_network_owner(controllerMeta, playerName) then return false end
  if not controllerMeta then
    return minetest.is_protected(pos, playerName)
  end
  if controllerMeta:get_int(META_HIDE_WITH_PROTECTION) == 1 then
    return minetest.is_protected(pos, playerName)
  end
  return false
end
