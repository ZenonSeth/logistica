
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME  = "logistica:signal_ext_reader"
local ON_OFF_BUTTON  = "on_off_btn"
local LIST_PICKER    = "target_list"
local NUM_SLOTS      = 4

local forms = {}

-- Vertical center of slot i within a list starting at list_y, slot height 1.25
local function slot_field_y(list_y, i)
  return list_y + (i - 1) * 1.25 + 0.25
end

local function get_formspec(pos)
  local posForm    = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn       = logistica.is_machine_on(pos)
  local targetPos  = logistica.ext_reader_get_target_pos(pos)
  local node       = targetPos and minetest.get_node_or_nil(targetPos)
  local targetName = (node and node.name ~= "air" and node.name ~= "ignore") and node.name or nil
  local def        = targetName and minetest.registered_nodes[targetName]
  local targetDesc = (def and type(def.description) == "string" and def.description ~= "")
                     and def.description or targetName or "nothing"
  local selectedList = logistica.ext_reader_get_target_list(pos)

  local LIST_Y = 2.1
  local fs = "formspec_version[4]"..
    "size["..logistica.inv_size(10.6, 12.5).."]"..
    logistica.ui.background..
    logistica.ui.button_only_style..
    "label[0.5,0.4;"..FS("External Content Reader").."]"..
    "label[0.5,1.0;"..FS("Reading from: ")..minetest.formspec_escape(targetDesc).."]"..
    logistica.ui.readable_list_picker(LIST_PICKER, 4.5, 0.7, targetPos, selectedList, FS("Inventory:"))..
    logistica.ui.on_off_btn(isOn, 7.5, 0.65, ON_OFF_BUTTON, FS("Enable"))..
    "button[7.5,1.55;2.5,0.75;save;"..FS("Save").."]"..
    "label[1.75,1.75;"..FS("Cond.").."]"..
    "label[3.35,1.75;"..FS("Amount").."]"..
    "label[5.1,1.75;"..FS("Signal Name").."]"..
    "list["..posForm..";filter;0.5,"..LIST_Y..";1,"..NUM_SLOTS..";0]"

  for i = 1, NUM_SLOTS do
    local fy        = slot_field_y(LIST_Y, i)
    local sigName   = logistica.ext_reader_get_signal_name(pos, i)
    local threshold = logistica.ext_reader_get_threshold(pos, i)
    local cmp       = logistica.ext_reader_get_comparison(pos, i)
    local cmpIdx    = cmp == ">=" and 1 or 2
    fs = fs..
      "dropdown[1.75,"..fy..";1.4,0.75;comparison_"..i..";>=,<=;"..cmpIdx.."]"..
      "field[3.35,"..fy..";1.6,0.75;threshold_"..i..";;"..(threshold).."]"..
      "field[5.1,"..fy..";5.0,0.75;signal_name_"..i..";;"..(minetest.formspec_escape(sigName)).."]"
  end

  local inv_y = LIST_Y + NUM_SLOTS * 1.25 + 0.4
  fs = fs..
    logistica.player_inv_formspec(0.5, inv_y)..
    "listring[current_player;main]"..
    "listring["..posForm..";filter]"

  return fs
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function save_fields(pos, fields)
  local meta = minetest.get_meta(pos)
  for i = 1, NUM_SLOTS do
    local sn = fields["signal_name_"..i]
    if sn then meta:set_string("signal_name_"..i, logistica.sanitize_signal_name(sn)) end
    local th = fields["threshold_"..i]
    if th then
      local v = math.floor(tonumber(th) or 1)
      meta:set_int("threshold_"..i, math.max(1, v))
    end
    local cmp = fields["comparison_"..i]
    if cmp == ">=" or cmp == "<=" then meta:set_string("comparison_"..i, cmp) end
  end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.save then
    save_fields(pos, fields)
    logistica.ext_reader_reconfigure(pos)
    forms[playerName] = nil
    show_formspec(pos, playerName)
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_formspec(pos, playerName)
  elseif fields.key_enter_field then
    save_fields(pos, fields)
    logistica.ext_reader_reconfigure(pos)
    forms[playerName] = nil
    minetest.show_formspec(playerName, FORMSPEC_NAME, "")
  elseif fields.quit then
    forms[playerName] = nil
  elseif fields[LIST_PICKER] then -- always sent; must be last
    logistica.ext_reader_set_target_list(pos, fields[LIST_PICKER])
    show_formspec(pos, playerName)
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

function logistica.register_signal_ext_reader(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function allow_inv_put(pos, listname, index, stack, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname ~= "filter" then return 0 end
    if stack:get_stack_max() == 1 then return 0 end
    local copy = ItemStack(stack:get_name())
    copy:set_count(1)
    minetest.get_meta(pos):get_inventory():set_stack("filter", index, copy)
    logistica.ext_reader_reconfigure(pos)
    return 0
  end

  local function allow_inv_take(pos, listname, index, _, player)
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    if listname ~= "filter" then return 0 end
    minetest.get_meta(pos):get_inventory():set_stack("filter", index, ItemStack(""))
    logistica.ext_reader_reconfigure(pos)
    return 0
  end

  local function allow_inv_move(_, _, _, _, _, _, _) return 0 end

  local function after_place(pos, placer, _, _)
    local meta = minetest.get_meta(pos)
    meta:get_inventory():set_size("filter", NUM_SLOTS)
    local targetPos = logistica.ext_reader_get_target_pos(pos)
    local readableLists = targetPos and logistica.get_readable_lists(targetPos) or {}
    logistica.ext_reader_set_target_list(pos, readableLists[1] or "")
    logistica.on_signal_sender_change(pos, nil, nil)
    logistica.ext_reader_update_infotext(pos)
    if targetPos then logistica.show_input_at(targetPos) end
    if placer and placer:is_player() then
      show_formspec(pos, placer:get_player_name())
    end
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_sender_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local function on_punch(pos, _, player, _)
    if not player or not player:is_player() then return end
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    if player:get_player_control().sneak then
      local targetPos = logistica.ext_reader_get_target_pos(pos)
      if targetPos then logistica.show_input_at(targetPos) end
    end
  end

  local logistica_callbacks = {
    on_connect_to_network      = logistica.ext_reader_on_connect,
    on_disconnect_from_network = logistica.ext_reader_on_disconnect,
    on_power                   = logistica.ext_reader_on_power,
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
    on_timer         = logistica.ext_reader_timer,
    allow_metadata_inventory_put  = allow_inv_put,
    allow_metadata_inventory_take = allow_inv_take,
    allow_metadata_inventory_move = allow_inv_move,
    logistica        = logistica_callbacks,
    _mcl_hardness      = 1.5,
    _mcl_blast_resistance = 10,
  }

  logistica.GROUPS.signal_senders.register(lname)

  minetest.register_node(lname, def)
end
