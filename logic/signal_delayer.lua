
local p2h = minetest.hash_node_position

local META_INPUT      = "delayer_input"
local META_OUTPUT     = "delayer_output"
local META_ON_DELAY   = "delayer_on_delay"
local META_OFF_DELAY  = "delayer_off_delay"

local DEFAULT_INPUT    = ""
local DEFAULT_OUTPUT   = "signal_out"
local DEFAULT_ON_DELAY  = 1.0
local DEFAULT_OFF_DELAY = 1.0
local DELAY_STEP = 0.5
local DELAY_MAX  = 600.0
local ON_SUFFIX  = "_on"

-- In-memory queue per node.
-- [hash] = { head = {isOn=bool}|nil, tail = {isOn=bool}|nil, output = bool }
local delayer_state = {}

local function get_or_init(hash)
  if not delayer_state[hash] then
    delayer_state[hash] = { head = nil, tail = nil, output = false }
  end
  return delayer_state[hash]
end

----------------------------------------------------------------
-- Meta accessors
----------------------------------------------------------------

function logistica.signal_delayer_get_input(pos)
  local v = minetest.get_meta(pos):get_string(META_INPUT)
  return (v and v ~= "") and v or DEFAULT_INPUT
end

function logistica.signal_delayer_get_output(pos)
  local v = minetest.get_meta(pos):get_string(META_OUTPUT)
  return (v and v ~= "") and v or DEFAULT_OUTPUT
end

function logistica.signal_delayer_get_on_delay(pos)
  local v = minetest.get_meta(pos):get_float(META_ON_DELAY)
  return (v >= 0) and v or DEFAULT_ON_DELAY
end

function logistica.signal_delayer_get_off_delay(pos)
  local v = minetest.get_meta(pos):get_float(META_OFF_DELAY)
  return (v >= 0) and v or DEFAULT_OFF_DELAY
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function set_visual(pos, isOn)
  local nodeName = minetest.get_node(pos).name
  local curOn = nodeName:sub(-#ON_SUFFIX) == ON_SUFFIX
  if curOn == isOn then return end
  local newName = isOn and (nodeName .. ON_SUFFIX) or nodeName:sub(1, -#ON_SUFFIX - 1)
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end

local function send_output(pos, isOn)
  logistica.signal_send(pos, logistica.signal_delayer_get_output(pos), isOn)
end

local function start_head_timer(pos, state)
  if not state.head then return end
  local delay = state.head.isOn
    and logistica.signal_delayer_get_on_delay(pos)
    or  logistica.signal_delayer_get_off_delay(pos)
  if delay <= 0 then
    -- fire immediately via a very short timer
    minetest.get_node_timer(pos):start(0.05)
  else
    minetest.get_node_timer(pos):start(delay)
  end
end

local function update_infotext(pos, state)
  local input  = logistica.signal_delayer_get_input(pos)
  local output = logistica.signal_delayer_get_output(pos)
  local onDly  = logistica.signal_delayer_get_on_delay(pos)
  local offDly = logistica.signal_delayer_get_off_delay(pos)
  local outStr = state.output and "On" or "Off"
  local pendStr = ""
  if state.head then
    pendStr = "\nPending: " .. (state.head.isOn and "ON" or "OFF")
    if state.tail then
      pendStr = pendStr .. ", " .. (state.tail.isOn and "ON" or "OFF")
    end
  end
  minetest.get_meta(pos):set_string("infotext",
    "Signal Delayer\n" ..
    "In: "  .. (input  ~= "" and input  or "(any)") ..
    "  Out: " .. output .. " (" .. outStr .. ")\n" ..
    "ON delay: " .. string.format("%.1f", onDly) .. "s" ..
    "  OFF delay: " .. string.format("%.1f", offDly) .. "s" ..
    pendStr
  )
end

----------------------------------------------------------------
-- Signal received (state machine)
----------------------------------------------------------------

function logistica.signal_delayer_on_signal_received(pos, sigName, isOn)
  if logistica.signal_delayer_get_input(pos) ~= sigName then return false end
  local hash  = p2h(pos)
  local state = get_or_init(hash)

  if not state.head then
    -- Queue empty: enqueue as head and start timer.
    state.head = { isOn = isOn }
    start_head_timer(pos, state)
  elseif not state.tail then
    -- One event in queue.
    if state.head.isOn == isOn then
      -- Same type as head: restart head timer.
      start_head_timer(pos, state)
    else
      -- Different type: add tail (do not touch head timer).
      state.tail = { isOn = isOn }
    end
  else
    -- Two events in queue.
    if state.tail.isOn == isOn then
      -- No-op: tail already covers this transition.
    else
      -- Cancel tail, restart head timer.
      state.tail = nil
      start_head_timer(pos, state)
    end
  end

  update_infotext(pos, state)
  return true
end

----------------------------------------------------------------
-- Timer fires: pop head, emit signal, start tail if present
----------------------------------------------------------------

function logistica.signal_delayer_on_timer(pos)
  local hash  = p2h(pos)
  local state = delayer_state[hash]
  if not state or not state.head then return false end

  local fired = state.head
  state.head  = state.tail
  state.tail  = nil

  state.output = fired.isOn
  set_visual(pos, fired.isOn)
  local networkId = logistica.get_network_id_or_nil(pos)
  if networkId then
    send_output(pos, fired.isOn)
  end

  if state.head then
    start_head_timer(pos, state)
  end

  update_infotext(pos, state)
  return false
end

----------------------------------------------------------------
-- Network callbacks
----------------------------------------------------------------

function logistica.signal_delayer_on_connect(pos, _networkId)
  local hash  = p2h(pos)
  local state = get_or_init(hash)
  -- Broadcast current output so downstream sees the right state.
  send_output(pos, state.output)
  set_visual(pos, state.output)
  update_infotext(pos, state)
end

function logistica.signal_delayer_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
  local hash  = p2h(pos)
  local state = delayer_state[hash]
  if state then set_visual(pos, false) end
  minetest.get_meta(pos):set_string("infotext", "Signal Delayer: disconnected")
end

function logistica.signal_delayer_cleanup(pos)
  local hash = p2h(pos)
  minetest.get_node_timer(pos):stop()
  delayer_state[hash] = nil
end
