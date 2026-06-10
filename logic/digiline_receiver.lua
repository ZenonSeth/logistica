
if not minetest.get_modpath("digilines") then return end

local META_CHANNEL     = "channel"
local META_SIGNAL_NAME = "signal_name"
local META_STATE       = "signal_state"
local ON_SUFFIX        = "_on"

local function interpret_msg(msg)
  if msg == true  then return true  end
  if msg == false or msg == nil then return false end
  if type(msg) == "number" then return msg > 0 end
  if type(msg) == "string" then
    local lower = msg:lower()
    return lower == "true" or lower == "on"
  end
  return false
end

local function get_base_name(pos)
  local name = minetest.get_node(pos).name
  if name:sub(-#ON_SUFFIX) == ON_SUFFIX then
    return name:sub(1, -#ON_SUFFIX - 1)
  end
  return name
end

local function set_visual_state(pos, state)
  local base    = get_base_name(pos)
  local newName = state and (base .. ON_SUFFIX) or base
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end

local function get_state(pos)
  return minetest.get_meta(pos):get_string(META_STATE) == "1"
end

local function update_infotext(pos)
  local meta    = minetest.get_meta(pos)
  local ch      = meta:get_string(META_CHANNEL)
  local sigName = meta:get_string(META_SIGNAL_NAME)
  local state   = get_state(pos) and "On" or "Off"
  meta:set_string("infotext",
    "Digiline to Signal Converter" ..
    "\nChannel: " .. (ch      ~= "" and ch      or "(none)") ..
    "\nSignal: "  .. (sigName ~= "" and sigName or "(none)") ..
    " [" .. state .. "]")
end

local function apply_signal(pos)
  local sigName = minetest.get_meta(pos):get_string(META_SIGNAL_NAME)
  if not sigName or sigName == "" then return end
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return end
  logistica.signal_send(pos, sigName, get_state(pos))
end

function logistica.digiline_receiver_effector(pos, _node, channel, msg)
  local meta   = minetest.get_meta(pos)
  local stored = meta:get_string(META_CHANNEL)
  if stored == "" or channel ~= stored then return end
  local newState = interpret_msg(msg)
  if newState == get_state(pos) then return end
  meta:set_string(META_STATE, newState and "1" or "0")
  set_visual_state(pos, newState)
  update_infotext(pos)
  apply_signal(pos)
end

function logistica.digiline_receiver_on_connect(pos, _networkId)
  apply_signal(pos)
end

function logistica.digiline_receiver_on_disconnect(pos, networkId)
  logistica.signal_remove_sender(pos, networkId)
end

function logistica.digiline_receiver_after_place(pos, placer, _itemstack, _pointed)
  update_infotext(pos)
  logistica.on_signal_sender_change(pos, nil, nil)
  if placer and placer:is_player() then
    logistica.digiline_receiver_show_formspec(placer:get_player_name(), pos)
  end
end

function logistica.digiline_receiver_after_dig(pos, oldNode, oldMeta, _digger)
  logistica.on_signal_sender_change(pos, oldNode, oldMeta)
end

function logistica.digiline_receiver_on_rightclick(pos, _node, player, _itemstack, _pointed)
  if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
  logistica.digiline_receiver_show_formspec(player:get_player_name(), pos)
end

function logistica.digiline_receiver_save(pos, newChannel, newSigName)
  newSigName = (newSigName == "") and "" or logistica.sanitize_signal_name(newSigName)
  local meta       = minetest.get_meta(pos)
  local oldSigName = meta:get_string(META_SIGNAL_NAME)
  if oldSigName ~= newSigName and oldSigName ~= "" then
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then logistica.signal_send(pos, oldSigName, false) end
  end
  meta:set_string(META_CHANNEL,     newChannel)
  meta:set_string(META_SIGNAL_NAME, newSigName)
  update_infotext(pos)
  apply_signal(pos)
end
