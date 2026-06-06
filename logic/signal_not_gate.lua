
local META_INPUT  = "signal_input"
local META_OUTPUT = "signal_output"
local DEFAULT_INPUT  = ""
local DEFAULT_OUTPUT = "signal_out"

function logistica.signal_not_gate_get_input(pos)
  local v = minetest.get_meta(pos):get_string(META_INPUT)
  if not v or v == "" then return DEFAULT_INPUT end
  return v
end

function logistica.signal_not_gate_get_output(pos)
  local v = minetest.get_meta(pos):get_string(META_OUTPUT)
  if not v or v == "" then return DEFAULT_OUTPUT end
  return v
end

local function update_infotext(pos, outputIsOn)
  local input = logistica.signal_not_gate_get_input(pos)
  local text = "NOT: " .. input .. "\nOutput: " .. (outputIsOn and "On" or "Off")
  minetest.get_meta(pos):set_string("infotext", text)
end

-- Returns true if the signal matched and was processed, false otherwise.
-- The BFS uses this return value for cycle detection.
function logistica.signal_not_gate_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.signal_not_gate_get_input(pos) then return false end
  local outputName = logistica.signal_not_gate_get_output(pos)
  local outputIsOn = not sigIsOn
  logistica.signal_send(pos, outputName, outputIsOn)
  update_infotext(pos, outputIsOn)
  return true
end

function logistica.signal_not_gate_on_connect(pos, _networkId)
  minetest.get_node_timer(pos):start(0.1)
end

function logistica.signal_not_gate_timer(pos)
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  local inputIsOn = logistica.signal_get_state(networkId, logistica.signal_not_gate_get_input(pos))
  local outputName = logistica.signal_not_gate_get_output(pos)
  local outputIsOn = not inputIsOn
  logistica.signal_send(pos, outputName, outputIsOn)
  update_infotext(pos, outputIsOn)
  return false
end

function logistica.signal_not_gate_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
  update_infotext(pos, false)
end
