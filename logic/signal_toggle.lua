
local META_INPUT      = "toggle_input"
local META_OUTPUT     = "toggle_output"
local META_STATE      = "toggle_state"
local META_LAST_INPUT = "toggle_last_input"

local DEFAULT_INPUT  = ""
local DEFAULT_OUTPUT = "signal_out"
local ON_SUFFIX = "_on"

local function set_visual(pos, isOn)
  local nodeName = minetest.get_node(pos).name
  local curOn = nodeName:sub(-#ON_SUFFIX) == ON_SUFFIX
  if curOn == isOn then return end
  local newName = isOn
    and (nodeName .. ON_SUFFIX)
    or  nodeName:sub(1, -#ON_SUFFIX - 1)
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end

function logistica.signal_toggle_get_input(pos)
  local v = minetest.get_meta(pos):get_string(META_INPUT)
  if not v or v == "" then return DEFAULT_INPUT end
  return v
end

function logistica.signal_toggle_get_output(pos)
  local v = minetest.get_meta(pos):get_string(META_OUTPUT)
  if not v or v == "" then return DEFAULT_OUTPUT end
  return v
end

function logistica.signal_toggle_get_state(pos)
  return minetest.get_meta(pos):get_int(META_STATE) == 1
end

local function set_state(pos, isOn)
  minetest.get_meta(pos):set_int(META_STATE, isOn and 1 or 0)
end

local function update_infotext(pos, outputIsOn)
  local input  = logistica.signal_toggle_get_input(pos)
  local output = logistica.signal_toggle_get_output(pos)
  minetest.get_meta(pos):set_string("infotext",
    "Input: "  .. (input  ~= "" and input  or "(none)") .. "\n" ..
    "Output: " .. output .. " - " .. (outputIsOn and "On" or "Off"))
end

-- Returns true if the signal matched and was processed, false otherwise.
function logistica.signal_toggle_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.signal_toggle_get_input(pos) then return false end
  local meta = minetest.get_meta(pos)
  local lastInput = meta:get_int(META_LAST_INPUT) == 1
  meta:set_int(META_LAST_INPUT, sigIsOn and 1 or 0)
  if not sigIsOn then return false end  -- falling edge: update stored state, no flip
  if lastInput then return false end    -- was already ON: not a rising edge, no flip
  local newState = not logistica.signal_toggle_get_state(pos)
  set_state(pos, newState)
  set_visual(pos, newState)
  logistica.signal_send(pos, logistica.signal_toggle_get_output(pos), newState)
  update_infotext(pos, newState)
  return true
end

function logistica.signal_toggle_on_connect(pos, _networkId)
  minetest.get_node_timer(pos):start(0.1)
end

function logistica.signal_toggle_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  local outputIsOn = logistica.signal_toggle_get_state(pos)
  set_visual(pos, outputIsOn)
  logistica.signal_send(pos, logistica.signal_toggle_get_output(pos), outputIsOn)
  update_infotext(pos, outputIsOn)
  return false
end

function logistica.signal_toggle_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
  set_visual(pos, false)
  update_infotext(pos, false)
  minetest.get_meta(pos):set_int(META_LAST_INPUT, 0)
end

-- Manually flip the output state and broadcast it on the network.
function logistica.signal_toggle_flip(pos)
  local newState = not logistica.signal_toggle_get_state(pos)
  set_state(pos, newState)
  set_visual(pos, newState)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then
    logistica.signal_send(pos, logistica.signal_toggle_get_output(pos), newState)
  end
  update_infotext(pos, newState)
  return newState
end
