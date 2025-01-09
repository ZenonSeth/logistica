local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logwifitr"
local forms = {}

local INAVLID_PLACEMENT_MSG = minetest.colorize("#FF4444", FS("Invalid Placement!"))
local INVALID_PLACEMENT_MSG2 = FS("Transmitter must be placed on top of a Network Controller")

local function color_node(pos, isValid)
  local node = minetest.get_node(pos)
  node.param2 = isValid and 0 or 128
  minetest.swap_node(pos, node)
end

local function get_formspec(pos, playerName)
  local networkName = logistica.get_network_name_or_nil(pos) or ""

  local nodeUnder = minetest.get_node(vector.add(pos, vector.new(0,-1,0)))
  local content = ""
  if not logistica.GROUPS.controllers.is(nodeUnder.name) then
    content = "label[0.2,1.0;"..INAVLID_PLACEMENT_MSG.."\n"..INVALID_PLACEMENT_MSG2.."]"
    -- color_node(pos, false)
  else
    local receivers = logistica.wifi_network_get_connected_receivers_for_transmitter(pos) or {}
    local numConnected = #receivers
    local maxReceivers = logistica.settings.max_receivers_per_transmitter
    content = "label[0.2,1.0;"..FS("Transmitting Network: ")..networkName.."]"..
    "label[0.2,1.6;"..FS("Receivers connected: ")..numConnected..FS(" out of max: ")..maxReceivers.."]"
    -- color_node(pos, true)
  end
  return "formspec_version[4]" ..
    "size[8.5,2.2]" ..
    "label[0.2,0.4;"..FS("Wireless Transmitter").."]"..
    logistica.ui.background..
    content
end

local function show_formspec(pos, playerName)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  local pos = forms[playerName].position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit and not fields.key_enter_field then
    forms[playerName] = nil
  end
  return true
end

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
  logistica.wifi_network_register_transmitter_for_player(pos) -- clicker may not be owner
  if clicker and clicker:is_player() then
    show_formspec(pos, clicker:get_player_name())
  end
end

local function after_place(pos, placer, itemstack, pointed_thing)
  local playerName = ""
  if placer:is_player() then
    playerName = placer:get_player_name()
  end
  local posBelow = vector.add(pos, vector.new(0,-1,0))
  local nodeUnder = minetest.get_node(posBelow)
  local networkName = logistica.get_network_name_or_nil(posBelow)
  local meta = minetest.get_meta(pos)
  if not networkName or not logistica.GROUPS.controllers.is(nodeUnder.name) then
    logistica.show_popup(playerName, INAVLID_PLACEMENT_MSG)
    color_node(pos, false)
  else
    logistica.wifi_transmitter_set_infotext(pos, networkName)
    logistica.on_wifi_transmitter_change(pos, nil, nil, playerName)
    logistica.wifi_network_after_place_transmitter(pos, playerName)
    end
end

local function after_dig(pos, oldNode, oldMeta, digger)
  local playerName = ""
  if digger:is_player() then
    playerName = digger:get_player_name()
  end
  logistica.wifi_network_after_destroy_transmitter(pos, oldMeta)
  logistica.on_wifi_transmitter_change(pos, oldNode, oldMeta, playerName)
end

----------------------------------------------------------------
-- registration stuff
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

--[[
  The definition table will get the fololwing fields overriden (and currently originals are not called):
  - on_construct
  - after_dig_node
  - after_place_node
  - drop
  - on_rightclick
  - logistica table
]]
function logistica.register_wireless_transmitter(name, def)
  --local group = logistica.TIER_ALL
  local transmitterName = "logistica:" .. string.lower(name:gsub(" ", "_"))
  logistica.GROUPS.wireless_transmitters.register(transmitterName)

  if not def.groups then def.groups = {} end
  --def.groups[group] = 1
  def.after_dig_node = after_dig
  def.after_place_node = after_place
  def.drop = transmitterName
  def.on_rightclick = on_rightclick
  if not def.logistica then def.logistica = {} end
  def.logistica.on_connect_to_network = function(pos, networkId)
    logistica.wifi_network_register_transmitter_for_player(pos)
    local netName = logistica.get_network_by_id_or_nil(networkId).name
    logistica.wifi_transmitter_set_infotext(pos, netName)
  end

  def._mcl_hardness = 1.5
  def._mcl_blast_resistance = 10

  minetest.register_node(transmitterName, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = def.tiles_disabled or logistica.table_map(def.tiles, function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_timer = nil
  def_disabled.on_rightclick = nil
  def_disabled.logistica = {}

  minetest.register_node(transmitterName.."_disabled", def_disabled)
end
