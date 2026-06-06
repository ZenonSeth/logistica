
local META_SIGNAL_NAME = "signal_name"
local DEFAULT_SIGNAL_NAME = ""
local ON_SUFFIX = "_on"
local PRESS_DURATION = 1.0

local function is_pressed(pos)
  return minetest.get_node(pos).name:sub(-#ON_SUFFIX) == ON_SUFFIX
end

function logistica.signal_button_get_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_button_update_infotext(pos)
  local sigName = logistica.signal_button_get_name(pos)
  local state = is_pressed(pos) and "Pressed" or "Ready"
  minetest.get_meta(pos):set_string("infotext",
    "Button [" .. sigName .. "]: " .. state .. "\nUse Hyperspanner to configure")
end

function logistica.signal_button_press(pos)
  if is_pressed(pos) then return end
  local newName = minetest.get_node(pos).name .. ON_SUFFIX
  if not minetest.registered_nodes[newName] then return end
  logistica.swap_node(pos, newName)
  logistica.signal_send(pos, logistica.signal_button_get_name(pos), true)
  minetest.get_node_timer(pos):start(PRESS_DURATION)
  logistica.signal_button_update_infotext(pos)
end

function logistica.signal_button_timer(pos)
  if not is_pressed(pos) then return false end
  local newName = minetest.get_node(pos).name:sub(1, -#ON_SUFFIX - 1)
  if not minetest.registered_nodes[newName] then return false end
  logistica.swap_node(pos, newName)
  logistica.signal_send(pos, logistica.signal_button_get_name(pos), false)
  logistica.signal_button_update_infotext(pos)
  return false
end

function logistica.signal_button_set_name(pos, newName)
  newName = logistica.sanitize_signal_name(newName)
  local oldName = logistica.signal_button_get_name(pos)
  if oldName == newName then return end
  if is_pressed(pos) then logistica.signal_send(pos, oldName, false) end
  minetest.get_meta(pos):set_string(META_SIGNAL_NAME, newName)
  if is_pressed(pos) then logistica.signal_send(pos, newName, true) end
end

function logistica.signal_button_on_connect(pos, _networkId)
  if is_pressed(pos) then
    logistica.signal_send(pos, logistica.signal_button_get_name(pos), true)
  end
end

function logistica.signal_button_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
end
