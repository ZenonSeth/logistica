
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_node_placer"

local forms = {}

local function get_formspec(pos, playerName)
  local posForm         = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local sigName         = logistica.node_placer_get_signal_name(pos)
  local dist            = logistica.node_placer_get_distance(pos)
  local ownerName       = logistica.node_placer_get_owner(pos)
  local isOwner         = (playerName == ownerName)
  local allowReplaceable = logistica.node_placer_get_allow_replaceable(pos)
  local filterInv  = minetest.get_meta(pos):get_inventory():get_stack("filter", 1)
  local filterDesc = (not filterInv:is_empty())
    and minetest.formspec_escape(filterInv:get_short_description())
    or FS("(none)")
  local lastError  = minetest.get_meta(pos):get_string("last_error")
  local statusText
  if lastError == "no_item" then
    statusText = minetest.colorize("#FF4444", FS("Can't find item to place/use in network"))
  elseif lastError == "target_blocked" then
    statusText = minetest.colorize("#FFCC00", FS("Target position is occupied, can't place"))
  else
    statusText = FS("Items will be drawn from network storage")
  end

  local invert      = logistica.node_placer_get_invert(pos)
  local ownerLabel = FS("Owner:") .. " " .. (ownerName ~= "" and ownerName or FS("(none)"))
  local ownerRow = "label[0.5,0.8;" .. ownerLabel .. "]"
  if not isOwner then
    ownerRow = ownerRow ..
      "button[6.5,2.4;2.5,0.55;take_ownership;" .. FS("Take Ownership") .. "]"
  end

  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.6, 11.5).."]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("Node Placer").."]"..
    "label[5.5,0.4;"..FS("Sneak-punch to see target").."]"..
    "label[5.5,0.8;"..FS("Places node on signal ON (rising edge)").."]"..
    ownerRow..
    "label[0.5,1.6;"..FS("Item to place/use:").."]"..
    "list["..posForm..";filter;2.8,1.25;1,1;0]"..
    "label[4.0,1.6;"..filterDesc.."]"..
    "label[0.5,2.65;"..FS("Place distance:").."]"..
    "button[3.1,2.4;0.65,0.65;dist_dec;-]"..
    "label[3.95,2.65;"..tostring(dist).."]"..
    "button[4.3,2.4;0.65,0.65;dist_inc;+]"..
    "label[0.5,3.6;"..FS("Signal Name:").."]"..
    "field[2.8,3.35;7.3,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[2.8,4.2;"..FS("a-z 0-9 _ only").."]"..
    "checkbox[0.5,4.6;allow_replaceable;"..FS("Allow placing on replaceable nodes (e.g. water, grass)")..";"
      ..(allowReplaceable and "true" or "false").."]"..
    "checkbox[0.5,5.1;invert_signal;"..FS("Not (act on signal OFF instead of ON)")..";"
      ..(invert and "true" or "false").."]"..
    "label[0.5,5.8;"..statusText.."]"..
    "button_exit[7.6,4.8;2.5,0.75;save;"..FS("Save").."]"..
    logistica.player_inv_formspec(0.5, 6.0)..
    "listring[current_player;main]"..
    "listring["..posForm..";filter]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
end

local function reshow_for_pos(pos)
  for playerName, data in pairs(forms) do
    if data.position and vector.equals(data.position, pos) then
      show_formspec(pos, playerName)
    end
  end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.allow_replaceable ~= nil then
    logistica.node_placer_set_allow_replaceable(pos, fields.allow_replaceable == "true")
    return true
  elseif fields.invert_signal ~= nil then
    logistica.node_placer_set_invert(pos, fields.invert_signal == "true")
    return true
  elseif fields.take_ownership then
    logistica.node_placer_set_owner(pos, playerName)
    minetest.get_meta(pos):set_string("last_error", "")
    logistica.node_placer_update_infotext(pos)
    reshow_for_pos(pos)
  elseif fields.save or fields.key_enter_field == "signal_name" then
    if fields.signal_name then
      minetest.get_meta(pos):set_string("signal_name",
        logistica.sanitize_signal_name(fields.signal_name))
    end
    logistica.node_placer_reconfigure(pos)
    forms[playerName] = nil
  elseif fields.dist_inc or fields.dist_dec then
    local delta = fields.dist_inc and 1 or -1
    logistica.node_placer_set_distance(pos, logistica.node_placer_get_distance(pos) + delta)
    logistica.node_placer_reconfigure(pos)
    logistica.node_placer_show_target(pos)
    show_formspec(pos, playerName)
  elseif fields.quit then
    forms[playerName] = nil
  end
  return true
end

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then forms[objRef:get_player_name()] = nil end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_signal_node_placer(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function allow_inv_put(pos, listname, _, stack, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname ~= "filter" then return 0 end
    local itemDef = minetest.registered_items[stack:get_name()]
    if not itemDef or not (minetest.registered_nodes[stack:get_name()] or itemDef.on_use) then return 0 end
    local copy = ItemStack(stack:get_name())
    copy:set_count(1)
    minetest.get_meta(pos):get_inventory():set_stack("filter", 1, copy)
    minetest.get_meta(pos):set_string("last_error", "")
    logistica.node_placer_reconfigure(pos)
    reshow_for_pos(pos)
    return 0
  end

  local function allow_inv_take(pos, listname, _, _, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname ~= "filter" then return 0 end
    minetest.get_meta(pos):get_inventory():set_stack("filter", 1, ItemStack(""))
    minetest.get_meta(pos):set_string("last_error", "")
    logistica.node_placer_reconfigure(pos)
    reshow_for_pos(pos)
    return 0
  end

  local function allow_inv_move(_, _, _, _, _, _, _) return 0 end

  local function after_place(pos, placer, _, _)
    local meta = minetest.get_meta(pos)
    meta:get_inventory():set_size("filter", 1)
    logistica.node_placer_set_distance(pos, 1)
    logistica.node_placer_set_allow_replaceable(pos, true)
    if placer and placer:is_player() then
      logistica.node_placer_set_owner(pos, placer:get_player_name())
    end
    logistica.on_signal_receiver_change(pos, nil, nil)
    logistica.node_placer_update_infotext(pos)
    logistica.node_placer_show_target(pos)
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.node_placer_clear_pcall_error(pos)
    logistica.on_signal_receiver_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local function on_punch(pos, _, player, _)
    if not player or not player:is_player() then return end
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    if player:get_player_control().sneak then
      logistica.node_placer_show_target(pos)
    end
  end

  local function on_rotate(pos, node, player, mode, newParam2)
    logistica.node_placer_show_target(pos, newParam2)
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.node_placer_on_connect,
    on_disconnect_from_network = logistica.node_placer_on_disconnect,
    on_signal_received         = logistica.node_placer_on_signal_received,
  }

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_punch         = on_punch,
    on_rotate        = on_rotate,
    allow_metadata_inventory_put  = allow_inv_put,
    allow_metadata_inventory_take = allow_inv_take,
    allow_metadata_inventory_move = allow_inv_move,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_disabled = table.copy(def)
  local tiles_disabled = logistica.table_map(def.tiles,
    function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles         = tiles_disabled
  def_disabled.groups        = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3,
                                  not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.after_dig_node = nil
  def_disabled.on_rightclick  = nil

  logistica.GROUPS.signal_receivers.register(lname)

  minetest.register_node(lname,              def)
  minetest.register_node(lname.."_disabled", def_disabled)
end
