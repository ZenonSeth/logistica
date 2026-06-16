
local META_SIGNAL_NAME = "signal_name"
local META_THRESHOLD = "threshold"
local META_COMPARISON = "comparison"
local META_RESPECT_RESERVE = "respect_reserve"
local DEFAULT_SIGNAL_NAME = ""
local POLL_INTERVAL = 1.0
local ON_SUFFIX = "_on"

function logistica.signal_item_counter_get_signal_name(pos)
  local name = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not name or name == "" then return DEFAULT_SIGNAL_NAME end
  return name
end

function logistica.signal_item_counter_get_threshold(pos)
  local t = minetest.get_meta(pos):get_int(META_THRESHOLD)
  return (t > 0) and t or 1
end

function logistica.signal_item_counter_get_comparison(pos)
  local c = minetest.get_meta(pos):get_string(META_COMPARISON)
  if c == ">=" or c == "<=" then return c end
  return ">="
end

function logistica.signal_item_counter_get_respect_reserve(pos)
  return minetest.get_meta(pos):get_string(META_RESPECT_RESERVE) == "1"
end

function logistica.signal_item_counter_get_item(pos)
  local stack = minetest.get_meta(pos):get_inventory():get_stack("filter", 1)
  return stack:get_name()
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

function logistica.signal_item_counter_update_infotext(pos)
  local itemName = logistica.signal_item_counter_get_item(pos)
  local comparison = logistica.signal_item_counter_get_comparison(pos)
  local threshold = logistica.signal_item_counter_get_threshold(pos)
  local sigName = logistica.signal_item_counter_get_signal_name(pos)
  local itemStr = (itemName ~= "") and itemName and ItemStack(itemName):get_short_description() or "(none)"
  local runStr
  if logistica.is_machine_on(pos) then
    local signalState = node_is_on(pos) and "On" or "Off"
    runStr = "Running | Sending signal: " .. signalState
  else
    runStr = "Paused"
  end
  minetest.get_meta(pos):set_string("infotext",
    "Item Count Sender: " .. itemStr .. "\n" ..
    comparison .. " " .. threshold .. " -> " .. sigName .. "\n" ..
    runStr
  )
end

local function do_evaluate(pos, networkId)
  local itemName = logistica.signal_item_counter_get_item(pos)
  if not itemName or itemName == "" then
    logistica.signal_remove_sender(pos, networkId)
    set_visual(pos, false)
    logistica.signal_item_counter_update_infotext(pos)
    return
  end
  local network = logistica.get_network_by_id_or_nil(networkId)
  if not network then return end
  local respectReserve = logistica.signal_item_counter_get_respect_reserve(pos)
  local threshold = logistica.signal_item_counter_get_threshold(pos)
  local comparison = logistica.signal_item_counter_get_comparison(pos)
  local sigName = logistica.signal_item_counter_get_signal_name(pos)
  if sigName == "" then
    logistica.signal_remove_sender(pos, networkId)
    set_visual(pos, false)
    logistica.signal_item_counter_update_infotext(pos)
    return
  end
  local conditionMet
  if comparison == ">=" then
    conditionMet = logistica.network_has_at_least(itemName, network, threshold, respectReserve)
  else
    conditionMet = logistica.network_has_at_most(itemName, network, threshold, respectReserve)
  end
  logistica.signal_send(pos, sigName, conditionMet)
  set_visual(pos, conditionMet)
  logistica.signal_item_counter_update_infotext(pos)
end

function logistica.signal_item_counter_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  do_evaluate(pos, networkId)
  return true
end

function logistica.signal_item_counter_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    minetest.get_node_timer(pos):start(POLL_INTERVAL + math.random(1, 4) * 0.1)
  end
  logistica.signal_item_counter_update_infotext(pos)
end

function logistica.signal_item_counter_on_disconnect(pos, networkId)
  minetest.get_node_timer(pos):stop()
  logistica.signal_remove_sender(pos, networkId)
  set_visual(pos, false)
  logistica.signal_item_counter_update_infotext(pos)
end

function logistica.signal_item_counter_on_power(pos, isOn)
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
  logistica.signal_item_counter_update_infotext(pos)
end

-- Called from formspec save and filter slot changes to re-evaluate immediately.
function logistica.signal_item_counter_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    logistica.signal_item_counter_update_infotext(pos)
    return
  end
  logistica.signal_remove_sender(pos, networkId)
  if logistica.is_machine_on(pos) then
    do_evaluate(pos, networkId)
  else
    set_visual(pos, false)
    logistica.signal_item_counter_update_infotext(pos)
  end
end
