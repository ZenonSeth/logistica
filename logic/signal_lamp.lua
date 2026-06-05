
local META_SIGNAL_NAME = "signal_name"
local META_SIGNAL_NOT  = "signal_not"
local DEFAULT_SIGNAL_NAME = "signal"
local ON_SUFFIX = "_on"

function logistica.signal_lamp_get_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_lamp_get_not(pos)
  return minetest.get_meta(pos):get_string(META_SIGNAL_NOT) == "1"
end

function logistica.signal_lamp_is_on(pos)
  return minetest.get_node(pos).name:sub(-#ON_SUFFIX) == ON_SUFFIX
end

function logistica.signal_lamp_set_state(pos, shouldBeOn)
  local node = minetest.get_node(pos)
  local isOn = node.name:sub(-#ON_SUFFIX) == ON_SUFFIX
  if isOn == shouldBeOn then return end
  local baseName = isOn and node.name:sub(1, -#ON_SUFFIX - 1) or node.name
  local newName = shouldBeOn and (baseName .. ON_SUFFIX) or baseName
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
    minetest.get_meta(pos):set_string("infotext", shouldBeOn and "On" or "Off")
  end
end

-- Evaluates signal state + NOT flag and updates the lamp.
local function apply_signal(pos, sigIsOn)
  local notFlag = logistica.signal_lamp_get_not(pos)
  logistica.signal_lamp_set_state(pos, notFlag ~= sigIsOn) -- XOR: NOT flips the meaning
end

function logistica.signal_lamp_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.signal_lamp_get_name(pos) then return end
  apply_signal(pos, sigIsOn)
end

function logistica.signal_lamp_on_connect(pos, networkId)
  local sigIsOn = logistica.signal_get_state(networkId, logistica.signal_lamp_get_name(pos))
  apply_signal(pos, sigIsOn)
end

function logistica.signal_lamp_on_disconnect(pos, _networkId)
  -- treat disconnect as signal absent
  apply_signal(pos, false)
end
