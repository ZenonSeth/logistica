
local META_SIGNAL_NAME = "signal_name"
local META_ON_SECONDS  = "on_seconds"
local META_OFF_SECONDS = "off_seconds"
local META_PHASE       = "phase"
local DEFAULT_SIGNAL_NAME = "signal"
local DEFAULT_ON_SECONDS  = 2.0
local DEFAULT_OFF_SECONDS = 2.0
local ON_SUFFIX = "_on"


function logistica.signal_timer_get_signal_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_timer_get_on_seconds(pos)
  local v = minetest.get_meta(pos):get_float(META_ON_SECONDS)
  return (v >= 0.5) and v or DEFAULT_ON_SECONDS
end

function logistica.signal_timer_get_off_seconds(pos)
  local v = minetest.get_meta(pos):get_float(META_OFF_SECONDS)
  return (v >= 0.5) and v or DEFAULT_OFF_SECONDS
end

local function get_phase(pos)
  local p = minetest.get_meta(pos):get_string(META_PHASE)
  return (p == "on" or p == "off") and p or "on"
end

local function set_visual(pos, isOn)
  local nodeName = minetest.get_node(pos).name
  local curOn = nodeName:sub(-#ON_SUFFIX) == ON_SUFFIX
  if curOn == isOn then return end
  local newName = isOn and (nodeName .. ON_SUFFIX) or nodeName:sub(1, -#ON_SUFFIX - 1)
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end

function logistica.signal_timer_update_infotext(pos)
  local sigName = logistica.signal_timer_get_signal_name(pos)
  local onSec   = logistica.signal_timer_get_on_seconds(pos)
  local offSec  = logistica.signal_timer_get_off_seconds(pos)
  local runStr
  if logistica.is_machine_on(pos) then
    local phase = get_phase(pos)
    runStr = "Running | Phase: " .. (phase == "on" and "ON" or "OFF")
  else
    runStr = "Paused"
  end
  minetest.get_meta(pos):set_string("infotext",
    "Signal Timer: " .. sigName .. "\n" ..
    "ON: " .. onSec .. "s  OFF: " .. offSec .. "s\n" ..
    runStr
  )
end

-- Sends signal for `phase`, updates visual, starts timer for that phase's duration.
local function start_phase(pos, phase)
  minetest.get_meta(pos):set_string(META_PHASE, phase)
  set_visual(pos, phase == "on")
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then
    logistica.signal_send(pos, logistica.signal_timer_get_signal_name(pos), phase == "on")
  end
  local duration = (phase == "on")
    and logistica.signal_timer_get_on_seconds(pos)
    or  logistica.signal_timer_get_off_seconds(pos)
  minetest.get_node_timer(pos):start(duration)
  logistica.signal_timer_update_infotext(pos)
end

function logistica.signal_timer_on_timer(pos)
  if not logistica.is_machine_on(pos) then return false end
  local newPhase = (get_phase(pos) == "on") and "off" or "on"
  start_phase(pos, newPhase)
  return false
end

function logistica.signal_timer_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    local phase = get_phase(pos)
    logistica.signal_send(pos, logistica.signal_timer_get_signal_name(pos), phase == "on")
  end
  logistica.signal_timer_update_infotext(pos)
end

function logistica.signal_timer_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
  logistica.signal_timer_update_infotext(pos)
end

function logistica.signal_timer_on_power(pos, isOn)
  if isOn then
    start_phase(pos, "on")
  else
    minetest.get_node_timer(pos):stop()
    set_visual(pos, false)
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then logistica.signal_remove_sender(pos, networkId) end
  end
  logistica.signal_timer_update_infotext(pos)
end

-- Called on formspec save to apply new settings immediately.
function logistica.signal_timer_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then logistica.signal_remove_sender(pos, networkId) end
  if logistica.is_machine_on(pos) then
    start_phase(pos, "on")
  else
    set_visual(pos, false)
    logistica.signal_timer_update_infotext(pos)
  end
end

