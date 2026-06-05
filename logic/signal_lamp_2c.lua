
local META_SIGNAL_NAME  = "signal_name"
local META_ACTIVE_COLOR = "active_color"
local SUFFIX_A = "_a"
local SUFFIX_B = "_b"

function logistica.signal_lamp_2c_get_name(pos)
  return minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
end

function logistica.signal_lamp_2c_get_active_color(pos)
  local v = minetest.get_meta(pos):get_string(META_ACTIVE_COLOR)
  if v ~= "a" and v ~= "b" then return "a" end
  return v
end

local function get_base_node_name(pos)
  local name = minetest.get_node(pos).name
  if name:sub(-2) == SUFFIX_A or name:sub(-2) == SUFFIX_B then
    return name:sub(1, -3)
  end
  return name
end

local function apply_state(pos, sigIsOn)
  local sigName = logistica.signal_lamp_2c_get_name(pos)
  local base = get_base_node_name(pos)
  local meta = minetest.get_meta(pos)
  if not sigName or sigName == "" then
    logistica.swap_node(pos, base)
    meta:set_string("infotext", "")
    return
  end
  local active = logistica.signal_lamp_2c_get_active_color(pos)
  local suffix, colorKey
  if sigIsOn then
    suffix   = (active == "a") and SUFFIX_A or SUFFIX_B
    colorKey = (active == "a") and "color_a_name" or "color_b_name"
  else
    suffix   = (active == "a") and SUFFIX_B or SUFFIX_A
    colorKey = (active == "a") and "color_b_name" or "color_a_name"
  end
  logistica.swap_node(pos, base .. suffix)
  meta:set_string("infotext", meta:get_string(colorKey))
end

function logistica.signal_lamp_2c_on_signal_received(pos, sigName, sigIsOn)
  if sigName ~= logistica.signal_lamp_2c_get_name(pos) then return end
  apply_state(pos, sigIsOn)
end

function logistica.signal_lamp_2c_on_connect(pos, networkId)
  local sigName = logistica.signal_lamp_2c_get_name(pos)
  if not sigName or sigName == "" then
    logistica.swap_node(pos, get_base_node_name(pos))
    return
  end
  apply_state(pos, logistica.signal_get_state(networkId, sigName))
end

function logistica.signal_lamp_2c_on_disconnect(pos, _networkId)
  logistica.swap_node(pos, get_base_node_name(pos))
  minetest.get_meta(pos):set_string("infotext", "")
end
