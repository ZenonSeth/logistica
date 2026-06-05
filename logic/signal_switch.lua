
local META_SIGNAL_NAME = "signal_name"
local DEFAULT_SIGNAL_NAME = "signal"
local ON_SUFFIX = "_on"

function logistica.signal_switch_update_infotext(pos)
  local text = logistica.signal_switch_is_on(pos) and "On" or "Off"
  minetest.get_meta(pos):set_string("infotext", text)
end

function logistica.signal_switch_get_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_switch_is_on(pos)
  local nodeName = minetest.get_node(pos).name
  return nodeName:sub(-#ON_SUFFIX) == ON_SUFFIX
end

-- Toggles the switch at pos. Returns the new on/off state.
function logistica.signal_switch_toggle(pos)
  local node = minetest.get_node(pos)
  local isOn = logistica.signal_switch_is_on(pos)
  local newName = isOn
    and node.name:sub(1, -#ON_SUFFIX - 1)
    or  node.name .. ON_SUFFIX
  if not minetest.registered_nodes[newName] then return isOn end
  logistica.swap_node(pos, newName)
  logistica.signal_send(pos, logistica.signal_switch_get_name(pos), not isOn)
  logistica.signal_switch_update_infotext(pos)
  return not isOn
end

-- Sets the signal name, re-sending signals if state changes.
function logistica.signal_switch_set_name(pos, newName)
  newName = newName:gsub("%s+", "_")
  if newName == "" then return end
  local oldName = logistica.signal_switch_get_name(pos)
  if oldName == newName then return end
  if logistica.signal_switch_is_on(pos) then
    logistica.signal_send(pos, oldName, false)
  end
  minetest.get_meta(pos):set_string(META_SIGNAL_NAME, newName)
  if logistica.signal_switch_is_on(pos) then
    logistica.signal_send(pos, newName, true)
  end
end

function logistica.signal_switch_on_connect(pos, _networkId)
  if logistica.signal_switch_is_on(pos) then
    logistica.signal_send(pos, logistica.signal_switch_get_name(pos), true)
  end
end

function logistica.signal_switch_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
end
