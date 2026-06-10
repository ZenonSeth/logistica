
local META_SIGNAL_NAME  = "signal_name"
local META_THRESHOLD    = "threshold"
local META_COMPARISON   = "comparison"
local META_LIQUID_NAME  = "liquid_name"
local DEFAULT_SIGNAL_NAME = ""
local POLL_INTERVAL = 1.0
local ON_SUFFIX = "_on"

function logistica.signal_liquid_counter_get_signal_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_liquid_counter_get_threshold(pos)
  local t = minetest.get_meta(pos):get_int(META_THRESHOLD)
  return (t > 0) and t or 1
end

function logistica.signal_liquid_counter_get_comparison(pos)
  local c = minetest.get_meta(pos):get_string(META_COMPARISON)
  if c == ">=" or c == "<=" then return c end
  return ">="
end

function logistica.signal_liquid_counter_get_liquid_name(pos)
  return minetest.get_meta(pos):get_string(META_LIQUID_NAME) or ""
end

local function node_is_on(pos)
  return minetest.get_node(pos).name:sub(-#ON_SUFFIX) == ON_SUFFIX
end

local function set_visual(pos, shouldBeOn)
  local nodeName = minetest.get_node(pos).name
  local curOn = nodeName:sub(-#ON_SUFFIX) == ON_SUFFIX
  if curOn == shouldBeOn then return end
  local newName = shouldBeOn
    and (nodeName .. ON_SUFFIX)
    or  nodeName:sub(1, -#ON_SUFFIX - 1)
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end

function logistica.signal_liquid_counter_update_infotext(pos)
  local liquidName = logistica.signal_liquid_counter_get_liquid_name(pos)
  local comparison = logistica.signal_liquid_counter_get_comparison(pos)
  local threshold  = logistica.signal_liquid_counter_get_threshold(pos)
  local sigName    = logistica.signal_liquid_counter_get_signal_name(pos)
  local liquidStr  = (liquidName ~= "") and logistica.reservoir_get_description_of_liquid(liquidName) or "(none)"
  local runStr
  if logistica.is_machine_on(pos) then
    local signalState = node_is_on(pos) and "On" or "Off"
    runStr = "Running | Sending signal: " .. signalState
  else
    runStr = "Paused"
  end
  minetest.get_meta(pos):set_string("infotext",
    "Liquid Count Sender: " .. liquidStr .. "\n" ..
    comparison .. " " .. threshold .. " -> " .. sigName .. "\n" ..
    runStr
  )
end

local function do_evaluate(pos, networkId)
  local liquidName = logistica.signal_liquid_counter_get_liquid_name(pos)
  if not liquidName or liquidName == "" then
    logistica.signal_remove_sender(pos, networkId)
    set_visual(pos, false)
    logistica.signal_liquid_counter_update_infotext(pos)
    return
  end
  local sigName = logistica.signal_liquid_counter_get_signal_name(pos)
  if sigName == "" then
    logistica.signal_remove_sender(pos, networkId)
    set_visual(pos, false)
    logistica.signal_liquid_counter_update_infotext(pos)
    return
  end
  local info = logistica.get_liquid_info_in_network(pos, liquidName)
  local count = info and info.curr or 0
  local threshold  = logistica.signal_liquid_counter_get_threshold(pos)
  local comparison = logistica.signal_liquid_counter_get_comparison(pos)
  local conditionMet = (comparison == ">=") and (count >= threshold)
                    or (comparison == "<=") and (count <= threshold)
  logistica.signal_send(pos, sigName, conditionMet)
  set_visual(pos, conditionMet)
  logistica.signal_liquid_counter_update_infotext(pos)
end

function logistica.signal_liquid_counter_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  do_evaluate(pos, networkId)
  return true
end

function logistica.signal_liquid_counter_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    minetest.get_node_timer(pos):start(POLL_INTERVAL + math.random(1, 4) * 0.1)
  end
  logistica.signal_liquid_counter_update_infotext(pos)
end

function logistica.signal_liquid_counter_on_disconnect(pos, networkId)
  minetest.get_node_timer(pos):stop()
  logistica.signal_remove_sender(pos, networkId)
  set_visual(pos, false)
  logistica.signal_liquid_counter_update_infotext(pos)
end

function logistica.signal_liquid_counter_on_power(pos, isOn)
  if isOn then
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then
      minetest.get_node_timer(pos):start(POLL_INTERVAL + math.random(1, 4) * 0.1)
    end
  else
    minetest.get_node_timer(pos):stop()
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then logistica.signal_remove_sender(pos, networkId) end
    set_visual(pos, false)
  end
  logistica.signal_liquid_counter_update_infotext(pos)
end

function logistica.signal_liquid_counter_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    logistica.signal_liquid_counter_update_infotext(pos)
    return
  end
  logistica.signal_remove_sender(pos, networkId)
  if logistica.is_machine_on(pos) then
    do_evaluate(pos, networkId)
  else
    set_visual(pos, false)
    logistica.signal_liquid_counter_update_infotext(pos)
  end
end
