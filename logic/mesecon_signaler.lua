
local META_SIGNAL_NAME = "signal_name"
local META_SIGNAL_NOT  = "signal_not"
local META_MESECON_ON  = "mesecon_on"
local ON_SUFFIX = "_on"

function logistica.mesecon_signaler_get_name(pos)
  return minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
end

function logistica.mesecon_signaler_get_not(pos)
  return minetest.get_meta(pos):get_string(META_SIGNAL_NOT) == "1"
end

local function get_base_name(pos)
  local name = minetest.get_node(pos).name
  if name:sub(-#ON_SUFFIX) == ON_SUFFIX then
    return name:sub(1, -#ON_SUFFIX - 1)
  end
  return name
end

local function set_visual_state(pos, meseconIsOn)
  local base = get_base_name(pos)
  local newName = meseconIsOn and (base .. ON_SUFFIX) or base
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end

-- Sends or removes this node's signal contribution based on current meta state.
local function apply_signal(pos)
  local sigName = logistica.mesecon_signaler_get_name(pos)
  if not sigName or sigName == "" then return end
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return end
  local meseconOn = minetest.get_meta(pos):get_string(META_MESECON_ON) == "1"
  local notFlag   = logistica.mesecon_signaler_get_not(pos)
  logistica.signal_send(pos, sigName, notFlag ~= meseconOn)
end

function logistica.mesecon_signaler_action_on(pos)
  minetest.get_meta(pos):set_string(META_MESECON_ON, "1")
  set_visual_state(pos, true)
  apply_signal(pos)
end

function logistica.mesecon_signaler_action_off(pos)
  minetest.get_meta(pos):set_string(META_MESECON_ON, "0")
  set_visual_state(pos, false)
  apply_signal(pos)
end

function logistica.mesecon_signaler_on_connect(pos, networkId)
  apply_signal(pos)
end

function logistica.mesecon_signaler_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
end
