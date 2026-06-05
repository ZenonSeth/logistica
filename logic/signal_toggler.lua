
local META_SIGNAL_NAME = "signal_name"
local META_SIGNAL_NOT  = "signal_not"
local DEFAULT_SIGNAL_NAME = "signal"
local ON_SUFFIX = "_on"

function logistica.get_signal_toggler_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local dirs = logistica.get_rot_directions(node.param2)
  if not dirs then return nil end
  return vector.add(pos, dirs.backward)
end

function logistica.signal_toggler_get_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_toggler_get_not(pos)
  return minetest.get_meta(pos):get_string(META_SIGNAL_NOT) == "1"
end

local function update_infotext(pos)
  minetest.get_meta(pos):set_string("infotext", logistica.signal_toggler_is_on(pos) and "On" or "Off")
end

function logistica.signal_toggler_is_on(pos)
  return minetest.get_node(pos).name:sub(-#ON_SUFFIX) == ON_SUFFIX
end

-- Swaps to on/off variant. Returns true if state actually changed.
local function set_toggler_state(pos, shouldBeOn)
  local node = minetest.get_node(pos)
  local isOn = node.name:sub(-#ON_SUFFIX) == ON_SUFFIX
  if isOn == shouldBeOn then return false end
  local baseName = isOn and node.name:sub(1, -#ON_SUFFIX - 1) or node.name
  local newName = shouldBeOn and (baseName .. ON_SUFFIX) or baseName
  if not minetest.registered_nodes[newName] then return false end
  logistica.swap_node(pos, newName)
  update_infotext(pos)
  return true
end

local function apply_signal(pos, sigIsOn)
  local shouldBeOn = logistica.signal_toggler_get_not(pos) ~= sigIsOn
  if set_toggler_state(pos, shouldBeOn) then
    logistica.rescan_network_at_pos(pos)
  end
end

function logistica.signal_toggler_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.signal_toggler_get_name(pos) then return end
  apply_signal(pos, sigIsOn)
end

function logistica.signal_toggler_on_connect(pos, _networkId)
  -- defer so all senders have fired their on_connect callbacks before we check signal state
  minetest.get_node_timer(pos):start(0.1)
end

function logistica.signal_toggler_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  local sigIsOn = logistica.signal_get_state(networkId, logistica.signal_toggler_get_name(pos))
  apply_signal(pos, sigIsOn)
  return false
end

function logistica.signal_toggler_on_disconnect(pos, _networkId)
  -- revert to OFF so the next connect starts with no forward propagation
  set_toggler_state(pos, false)
end
