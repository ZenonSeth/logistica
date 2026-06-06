
local META_MODE      = "gate_mode"
local META_THRESHOLD = "gate_threshold"
local META_INPUTS    = "gate_inputs"
local META_OUTPUT    = "gate_output"

local DEFAULT_MODE      = "and"
local DEFAULT_THRESHOLD = 1
local DEFAULT_INPUTS    = ""
local DEFAULT_OUTPUT    = "signal_out"
local MAX_THRESHOLD     = 100000

function logistica.signal_logic_gate_get_mode(pos)
  local v = minetest.get_meta(pos):get_string(META_MODE)
  if v ~= "and" and v ~= "or" and v ~= "adder" then return DEFAULT_MODE end
  return v
end

function logistica.signal_logic_gate_get_threshold(pos)
  local v = minetest.get_meta(pos):get_int(META_THRESHOLD)
  if v < 1 then return DEFAULT_THRESHOLD end
  return v
end

function logistica.signal_logic_gate_get_inputs(pos)
  local v = minetest.get_meta(pos):get_string(META_INPUTS)
  if not v or v == "" then return DEFAULT_INPUTS end
  return v
end

function logistica.signal_logic_gate_get_output(pos)
  local v = minetest.get_meta(pos):get_string(META_OUTPUT)
  if not v or v == "" then return DEFAULT_OUTPUT end
  return v
end

local function parse_signal_list(inputsStr)
  local signals = {}
  for token in inputsStr:gmatch("[^%s,]+") do
    local s = logistica.sanitize_signal_name(token)
    if s ~= "" then signals[#signals + 1] = s end
  end
  return signals
end

local function evaluate_gate(networkId, inputList, mode, threshold)
  if #inputList == 0 then return false end
  if mode == "and" then
    for _, name in ipairs(inputList) do
      if not logistica.signal_get_state(networkId, name) then return false end
    end
    return true
  elseif mode == "or" then
    for _, name in ipairs(inputList) do
      if logistica.signal_get_state(networkId, name) then return true end
    end
    return false
  else -- adder
    local count = 0
    for _, name in ipairs(inputList) do
      if logistica.signal_get_state(networkId, name) then count = count + 1 end
    end
    return count >= threshold
  end
end

local function update_infotext(pos, outputIsOn)
  local mode = logistica.signal_logic_gate_get_mode(pos)
  local inputs = logistica.signal_logic_gate_get_inputs(pos)
  local inputList = parse_signal_list(inputs)
  local label
  if mode == "adder" then
    local threshold = logistica.signal_logic_gate_get_threshold(pos)
    label = "ADD " .. threshold
  elseif mode == "or" then
    label = "OR"
  else
    label = "AND"
  end
  local signalStr = table.concat(inputList, ", ")
  local text = label .. ": " .. signalStr .. "\nOutput: " .. (outputIsOn and "On" or "Off")
  minetest.get_meta(pos):set_string("infotext", text)
end

-- Returns true if the signal matched and was processed, false otherwise.
function logistica.signal_logic_gate_on_signal_received(pos, sigName, sigIsOn)
  local inputList = parse_signal_list(logistica.signal_logic_gate_get_inputs(pos))
  local found = false
  for _, name in ipairs(inputList) do
    if name == sigName then found = true ; break end
  end
  if not found then return false end
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  local outputIsOn = evaluate_gate(
    networkId, inputList,
    logistica.signal_logic_gate_get_mode(pos),
    logistica.signal_logic_gate_get_threshold(pos)
  )
  logistica.signal_send(pos, logistica.signal_logic_gate_get_output(pos), outputIsOn)
  update_infotext(pos, outputIsOn)
  return true
end

function logistica.signal_logic_gate_on_connect(pos, _networkId)
  minetest.get_node_timer(pos):start(0.1)
end

function logistica.signal_logic_gate_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  local inputList = parse_signal_list(logistica.signal_logic_gate_get_inputs(pos))
  local outputIsOn = evaluate_gate(
    networkId, inputList,
    logistica.signal_logic_gate_get_mode(pos),
    logistica.signal_logic_gate_get_threshold(pos)
  )
  logistica.signal_send(pos, logistica.signal_logic_gate_get_output(pos), outputIsOn)
  update_infotext(pos, outputIsOn)
  return false
end

function logistica.signal_logic_gate_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
  update_infotext(pos, false)
end
