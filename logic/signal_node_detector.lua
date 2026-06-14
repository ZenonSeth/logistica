
local META_SIGNAL_NAME = "signal_name"
local META_DISTANCE    = "distance"
local MIN_DISTANCE     = 1
local MAX_DISTANCE     = logistica.settings.node_detector_max_distance
local POLL_INTERVAL    = 1.0
local ON_SUFFIX        = "_on"

function logistica.node_detector_get_signal_name(pos)
  local v = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  return (v and v ~= "") and v or ""
end

function logistica.node_detector_get_distance(pos)
  local v = minetest.get_meta(pos):get_int(META_DISTANCE)
  return (v >= MIN_DISTANCE and v <= MAX_DISTANCE) and v or MIN_DISTANCE
end

function logistica.node_detector_set_distance(pos, d)
  minetest.get_meta(pos):set_int(META_DISTANCE, logistica.clamp(d, MIN_DISTANCE, MAX_DISTANCE))
end

function logistica.node_detector_get_filter(pos)
  local stack = minetest.get_meta(pos):get_inventory():get_stack("filter", 1)
  return stack:get_name()
end

local function get_target_pos(pos, newParam2)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local dist = logistica.node_detector_get_distance(pos)
  local dir  = logistica.get_rot_directions(newParam2 or node.param2).backward
  return vector.add(pos, vector.multiply(dir, dist))
end

function logistica.node_detector_get_target_pos(pos)
  return get_target_pos(pos)
end

function logistica.node_detector_show_target(pos, newParam2)
  local targetPos = get_target_pos(pos, newParam2)
  if not targetPos then return end
  logistica.show_input_at(targetPos, tostring(minetest.hash_node_position(pos)))
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

function logistica.node_detector_update_infotext(pos)
  local filterName = logistica.node_detector_get_filter(pos)
  local dist       = logistica.node_detector_get_distance(pos)
  local sigName    = logistica.node_detector_get_signal_name(pos)
  local filterStr  = (filterName ~= "") and ItemStack(filterName):get_short_description() or "(any)"
  local runStr
  if logistica.is_machine_on(pos) then
    local signalState = node_is_on(pos) and "On" or "Off"
    runStr = "Running | Sending signal: " .. signalState
  else
    runStr = "Paused"
  end
  minetest.get_meta(pos):set_string("infotext",
    "Node Detector: " .. filterStr .. " at dist " .. dist .. "\n" ..
    "-> " .. sigName .. "\n" ..
    runStr
  )
end

local function do_evaluate(pos, networkId)
  local sigName    = logistica.node_detector_get_signal_name(pos)
  local filterName = logistica.node_detector_get_filter(pos)
  local targetPos  = get_target_pos(pos)
  local conditionMet = false

  if sigName ~= "" and targetPos then
    local targetNode = minetest.get_node_or_nil(targetPos)
    if targetNode and targetNode.name ~= "air" and targetNode.name ~= "ignore" then
      if filterName == "" then
        conditionMet = true
      else
        conditionMet = (targetNode.name == filterName)
      end
    end
  end

  if sigName ~= "" then
    logistica.signal_send(pos, sigName, conditionMet)
  else
    logistica.signal_remove_sender(pos, networkId)
  end
  set_visual(pos, conditionMet)
  logistica.node_detector_update_infotext(pos)
end

function logistica.node_detector_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  do_evaluate(pos, networkId)
  return true
end

function logistica.node_detector_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    minetest.get_node_timer(pos):start(POLL_INTERVAL + math.random(1, 4) * 0.1)
  end
  logistica.node_detector_update_infotext(pos)
end

function logistica.node_detector_on_disconnect(pos, networkId)
  minetest.get_node_timer(pos):stop()
  logistica.signal_remove_sender(pos, networkId)
  set_visual(pos, false)
  logistica.node_detector_update_infotext(pos)
end

function logistica.node_detector_on_power(pos, isOn)
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
  logistica.node_detector_update_infotext(pos)
end

function logistica.node_detector_reconfigure(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    logistica.node_detector_update_infotext(pos)
    return
  end
  logistica.signal_remove_sender(pos, networkId)
  if logistica.is_machine_on(pos) then
    do_evaluate(pos, networkId)
  else
    set_visual(pos, false)
    logistica.node_detector_update_infotext(pos)
  end
end
