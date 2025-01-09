local FS = logistica.FTRANSLATOR

local CONNECT_BUTTON = "logconbtn"
local FORMSPEC_NAME = "logwifirc"
local TR_DROP_PICKER = "trdpdwn"
local forms = {}

local CLR_RED = "#FF3333"
local CLR_GRN = "#33FF11"

local function get_dropdown_list_and_index_str(pos, playerName)
  local items = logistica.wifi_network_get_available_transmitters_for_player(playerName)
  -- save the table since it may change while the formspec is open
  local formData = forms[playerName] or {}
  formData.items = {}
  forms[playerName] = formData
  local selPos = logistica.wifi_network_get_connected_transmitter_for_receiver(pos)
  local selIdx = 0
  local itemList = logistica.table_to_list_indexed(items, function(key, trTbl, index)
    local trPos = trTbl.pos
    if selIdx == 0 and selPos and vector.equals(selPos, trPos) then selIdx = index end
    formData.items[index] = trTbl
    logistica.load_position(trPos)
    local networkName = logistica.get_network_name_or_nil(trPos)
    if not networkName then return 0
    else return minetest.formspec_escape(networkName) end
  end)
  itemList = logistica.list_filter(itemList, function(v) return type(v) == "string" end)
  forms[playerName] = formData
  return table.concat(itemList,",")..";"..tostring(selIdx)
end

local function get_formspec(pos, playerName, msg)
  local dropdownItems = get_dropdown_list_and_index_str(pos, playerName)
  return "formspec_version[4]" ..
    "size[10.0,3.5]" ..
    logistica.ui.background..
    "label[0.2,0.4;"..FS("Wireless Receiver").."]"..
    "label[2.5,0.9;"..FS("Choose a network to connect to.").."]"..
    "dropdown[2.5,1.1;3,0.8;"..TR_DROP_PICKER..";"..dropdownItems..";true]" ..
    "button[5.6,1.1;3,0.8;"..CONNECT_BUTTON..";"..FS("Connect").."]"..
    "label[2.5,2.1;"..(msg or "").."]"..
    "label[0.2,2.5;"..FS("Only your networks with a Wireless Transmitter can be connected to.").."]"..
    "label[0.2,2.9;"..FS("If a network isn't showing up, go near its controller to reactivate it.").."]"
end

local function show_formspec(pos, playerName, msg)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName, msg))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[CONNECT_BUTTON] then
    local formData = forms[playerName]
    if not fields[TR_DROP_PICKER] or not formData.items then return true end
    local selItem = formData.items[tonumber(fields[TR_DROP_PICKER])]
    if not selItem or not selItem.pos then return true end

    logistica.wifi_network_disconect_receiver_from_current_transmitter(pos)
    logistica.remove_receiver_from_network(pos)
    local addSuccess = logistica.wifi_network_connect_receiver_to_transmitter(selItem.pos, pos)
    local msg = nil
    if addSuccess then
      local trNet = logistica.get_network_or_nil(selItem.pos)
      if trNet then
        local scanSuccess = logistica.add_receiver_to_network(trNet, pos)
        if not scanSuccess then
          logistica.wifi_network_disconect_receiver_from_current_transmitter(pos)
          minetest.close_formspec(playerName, formname)
          return true
        end
        msg = minetest.colorize(CLR_GRN, FS("Connected!"))
      end
    end
    if not msg then msg = minetest.colorize(CLR_RED, FS("Failed to connect!")) end
    show_formspec(pos, playerName, msg)
  elseif fields[TR_DROP_PICKER] then -- this check should be below the CONNECT_BUTTON
    -- hmmm
  end
  return true
end

local function after_place(pos, placer, itemstack, pointed_thing)
  local playerName = ""
  if placer:is_player() then
    playerName = placer:get_player_name()
  end
  logistica.on_wifi_receiver_change(pos, nil, nil, placer)
  logistica.wifi_network_after_place_receiver(pos, playerName)
end

local function after_dig(pos, oldNode, oldMeta, digger)
  logistica.wifi_network_after_destroy_receiver(pos, oldMeta)
  logistica.on_wifi_receiver_change(pos, oldNode, oldMeta, digger)
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
]]
function logistica.register_wireless_receiver(name, def)
  local group = logistica.TIER_ALL
  local receiverName = "logistica:" .. string.lower(name:gsub(" ", "_"))
  logistica.GROUPS.wireless_receivers.register(receiverName)

  if not def.groups then
    def.groups = {}
  end
  def.groups[group] = 1
  def.after_dig_node = after_dig
  def.after_place_node = after_place
  def.drop = receiverName
  def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if clicker and clicker:is_player() then
      logistica.try_to_wake_up_network(pos) -- as to not erase data
      show_formspec(pos, clicker:get_player_name())
    end
  end
  def._mcl_hardness = 1.5
  def._mcl_blast_resistance = 10

  minetest.register_node(receiverName, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = def.tiles_disabled or logistica.table_map(def.tiles, function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_timer = nil
  def_disabled.on_rightclick = nil

  minetest.register_node(receiverName.."_disabled", def_disabled)
end

minetest.register_on_mods_loaded(function()
  local nodeNames = logistica.group_get_all_nodes_for_group(logistica.GROUPS.wireless_receivers.name)
  if #nodeNames == 0 then return end
  minetest.register_abm({
    label = "receiver_rescanning",
    nodenames = nodeNames,
    interval = 15.2,
    chance = 1,
    catch_up = false,
    action = function(pos, node, active_object_count, active_object_count_wider)
      logistica.try_to_wake_up_network(pos)
    end
  })
end)
