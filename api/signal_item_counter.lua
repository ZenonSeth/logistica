
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:signal_item_counter"
local ON_OFF_BUTTON = "on_off_btn"

local RESERVE_TOOLTIP = FS("If checked, items reserved by Mass Storage slots are not counted.\nUncheck to count all items including reserved amounts.")

local forms = {}

local function get_formspec(pos)
  local sigName    = logistica.signal_item_counter_get_signal_name(pos)
  local threshold  = logistica.signal_item_counter_get_threshold(pos)
  local comparison = logistica.signal_item_counter_get_comparison(pos)
  local isOn       = logistica.is_machine_on(pos)
  local cmpIdx     = comparison == ">=" and 1 or 2
  local respectStr = logistica.signal_item_counter_get_respect_reserve(pos) and "true" or "false"
  local showStr    = logistica.signal_item_counter_get_show_item(pos) and "true" or "false"
  local posForm    = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.6, 11.5).."]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("Item Count Sender").."]"..
    "label[0.5,1.15;"..FS("Item to Monitor:").."]"..
    "list["..posForm..";filter;2.8,0.75;1,1;0]"..
    "checkbox[4.3,1.0;show_item;"..FS("Show Item")..";"..showStr.."]"..
    "label[0.5,2.15;"..FS("Condition:").."]"..
    "dropdown[2.8,1.8;1.5,0.75;comparison;>=,<=;"..cmpIdx.."]"..
    "label[4.45,2.15;"..FS("amount:").."]"..
    "field[5.7,1.8;2.1,0.75;threshold;;"..threshold.."]"..
    "label[0.5,3.05;"..FS("Signal Name:").."]"..
    "field[2.8,2.7;7.3,0.75;signal_name;;"..minetest.formspec_escape(sigName).."]"..
    "label[2.8,3.55;"..FS("a-z 0-9 _ only").."]"..
    "checkbox[0.5,4.1;respect_reserve;"..FS("Respect Mass Storage Reserve")..";"..respectStr.."]"..
    "tooltip[respect_reserve;"..minetest.formspec_escape(RESERVE_TOOLTIP).."]"..
    logistica.ui.on_off_btn(isOn, 5.6, 4.5, ON_OFF_BUTTON, FS("Enable"))..
    "button_exit[7.6,4.65;2.5,0.75;save;"..FS("Save").."]"..
    logistica.player_inv_formspec(0.5, 5.9)..
    "listring[current_player;main]"..
    "listring["..posForm..";filter]"
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.save
      or fields.key_enter_field == "signal_name"
      or fields.key_enter_field == "threshold" then
    local meta = minetest.get_meta(pos)
    if fields.signal_name then
      meta:set_string("signal_name", logistica.sanitize_signal_name(fields.signal_name))
    end
    if fields.threshold then
      local t = math.floor(tonumber(fields.threshold) or 1)
      meta:set_int("threshold", math.max(1, t))
    end
    if fields.comparison == ">=" or fields.comparison == "<=" then
      meta:set_string("comparison", fields.comparison)
    end
    logistica.signal_item_counter_reconfigure(pos)
    forms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_formspec(pos, playerName)
  elseif fields.quit then
    forms[playerName] = nil
  end
  if fields.respect_reserve then
    minetest.get_meta(pos):set_string("respect_reserve",
      fields.respect_reserve == "true" and "1" or "0")
  end
  if fields.show_item then
    logistica.signal_item_counter_set_show_item(pos, fields.show_item == "true")
    logistica.signal_item_counter_update_front_image(pos)
  end
  return true
end

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_signal_item_counter(desc, name, tiles_off, tiles_on)
  local lname    = "logistica:" .. name
  local lname_on = lname .. "_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function allow_inv_put(pos, listname, _, stack, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname ~= "filter" then return 0 end
    if stack:get_stack_max() == 1 then return 0 end
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    minetest.get_meta(pos):get_inventory():set_stack("filter", 1, copyStack)
    logistica.signal_item_counter_reconfigure(pos)
    return 0
  end

  local function allow_inv_take(pos, listname, _, _, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname ~= "filter" then return 0 end
    minetest.get_meta(pos):get_inventory():set_stack("filter", 1, ItemStack(""))
    logistica.signal_item_counter_reconfigure(pos)
    return 0
  end

  local function allow_inv_move(_, _, _, _, _, _, _)
    return 0
  end

  local function after_place(pos, placer, _, _)
    minetest.get_meta(pos):get_inventory():set_size("filter", 1)
    logistica.on_signal_sender_change(pos, nil, nil)
    logistica.signal_item_counter_update_infotext(pos)
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.remove_item_on_block_front(pos)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local function on_rotate(pos, _, _, _, newParam2)
    logistica.signal_item_counter_update_front_image(pos, newParam2)
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.signal_item_counter_on_connect,
    on_disconnect_from_network = logistica.signal_item_counter_on_disconnect,
    on_power                   = logistica.signal_item_counter_on_power,
  }

  local def = {
    description = desc,
    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    tiles = tiles_off,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place,
    after_dig_node   = after_dig,
    on_rightclick    = on_rightclick,
    on_rotate        = on_rotate,
    on_timer         = logistica.signal_item_counter_timer,
    allow_metadata_inventory_put  = allow_inv_put,
    allow_metadata_inventory_take = allow_inv_take,
    allow_metadata_inventory_move = allow_inv_move,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_on = table.copy(def)
  def_on.tiles = tiles_on
  def_on.groups = table.copy(grps)
  def_on.groups.not_in_creative_inventory = 1

  local def_disabled = table.copy(def)
  local tiles_disabled = logistica.table_map(def.tiles, function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles       = tiles_disabled
  def_disabled.groups      = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.on_construct  = nil
  def_disabled.after_dig_node = function(pos, _) logistica.remove_item_on_block_front(pos) end
  def_disabled.on_timer      = nil
  def_disabled.on_rightclick  = nil

  logistica.GROUPS.signal_senders.register(lname)
  logistica.GROUPS.signal_senders.register(lname_on)

  minetest.register_node(lname,              def)
  minetest.register_node(lname_on,           def_on)
  minetest.register_node(lname.."_disabled", def_disabled)
end
