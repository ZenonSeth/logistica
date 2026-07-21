
local FS = logistica.FTRANSLATOR
local FORMSPEC_NAME = "logistica:requester_programmer"
local NUM_SIGNAL_ROWS = 4
local NUM_ROWS = NUM_SIGNAL_ROWS + 1
local DEFAULT_ROW = NUM_ROWS
local NUM_SLOTS = 8
local ROW_HEIGHT = 3.0
local DEFAULT_ROW_HEIGHT = 2.8
local FORM_TOP = 1.0

local forms = {}

local function get_amount_fields(pos, row, x, y)
  local fields = {}
  for i = 1, NUM_SLOTS do
    local fx = x + (i - 1) * 1.24
    local amount = logistica.requester_programmer_get_amount(pos, row, i)
    fields[i] = "field["..fx..","..y..";1.1,0.6;amt"..row.."_"..i..";;"..amount.."]"
  end
  return table.concat(fields)
end

local function row_y(row)
  return FORM_TOP + (row - 1) * ROW_HEIGHT
end

local function get_row_formspec(pos, row)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local y = row_y(row)
  local listName = logistica.requester_programmer_row_list_name(row)
  if row <= NUM_SIGNAL_ROWS then
    local sigName = logistica.requester_programmer_get_signal_name(pos, row)
    return
      "label[0.5,"..(y + 0.1)..";"..FS("Signal Name:").."]"..
      "field[3.3,"..(y - 0.3)..";3.0,0.75;signal_name"..row..";;"..minetest.formspec_escape(sigName).."]"..
      "list["..posForm..";"..listName..";0.5,"..(y + 0.55)..";8,1;0]"..
      get_amount_fields(pos, row, 0.5, y + 1.75)
  else
    return
      "label[0.5,"..y..";"..FS("When no signal is active:").."]"..
      "list["..posForm..";"..listName..";0.5,"..(y + 0.4)..";8,1;0]"..
      get_amount_fields(pos, row, 0.5, y + 1.6)
  end
end

local function get_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local rowsHeight = ROW_HEIGHT * NUM_SIGNAL_ROWS + DEFAULT_ROW_HEIGHT
  local saveY = FORM_TOP + rowsHeight + 0.3
  local invY = saveY + 1.0
  local parts = {
    "formspec_version[4]",
    "size["..logistica.inv_size(10.6, invY + 5.0).."]",
    logistica.ui.background,
    logistica.ui.button_only_style,
    "label[0.5,0.4;"..FS("Requester Programmer").."]",
    "label[5.5,0.4;"..FS("Highest matching row wins").."]",
  }
  for row = 1, NUM_ROWS do
    parts[#parts + 1] = get_row_formspec(pos, row)
  end
  parts[#parts + 1] = "button[7.6,"..saveY..";2.5,0.75;save;"..FS("Save").."]"
  parts[#parts + 1] = logistica.player_inv_formspec(0.5, invY)
  parts[#parts + 1] = "listring[current_player;main]"
  return table.concat(parts)
end

local function show_formspec(pos, playerName)
  forms[playerName] = { position = pos }
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos))
end

local function save_fields(pos, fields)
  for row = 1, NUM_SIGNAL_ROWS do
    local fieldName = "signal_name"..row
    if fields[fieldName] ~= nil then
      logistica.requester_programmer_set_signal_name(pos, row, fields[fieldName])
    end
  end
  for row = 1, NUM_ROWS do
    for slot = 1, NUM_SLOTS do
      local fieldName = "amt"..row.."_"..slot
      if fields[fieldName] ~= nil then
        logistica.requester_programmer_set_amount(pos, row, slot, fields[fieldName])
      end
    end
  end
end

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  local pos = (forms[playerName] or {}).position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  save_fields(pos, fields)

  if fields.quit then
    forms[playerName] = nil
  end
  if fields.save then
    logistica.requester_programmer_apply(pos)
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

function logistica.register_requester_programmer(desc, name, tiles)
  local lname = "logistica:"..name.."_on"

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local function is_row_list(listname)
    for row = 1, NUM_ROWS do
      if listname == logistica.requester_programmer_row_list_name(row) then return true end
    end
    return false
  end

  local function allow_inv_put(pos, listname, index, stack, player)
    if not is_row_list(listname) then return 0 end
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    local inv = minetest.get_meta(pos):get_inventory()
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    inv:set_stack(listname, index, copyStack)
    return 0
  end

  local function allow_inv_take(pos, listname, index, _, player)
    if not is_row_list(listname) then return 0 end
    if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
    minetest.get_meta(pos):get_inventory():set_stack(listname, index, ItemStack(""))
    return 0
  end

  local function allow_inv_move(_, _, _, _, _, _, _) return 0 end

  local function after_place(pos, placer, _, _)
    local inv = minetest.get_meta(pos):get_inventory()
    for row = 1, NUM_ROWS do
      inv:set_size(logistica.requester_programmer_row_list_name(row), NUM_SLOTS)
    end
    logistica.on_signal_toggler_change(pos, nil, nil)
    logistica.requester_programmer_update_infotext(pos)
    logistica.show_output_at(logistica.requester_programmer_get_target(pos), tostring(minetest.hash_node_position(pos)))
  end

  local function after_dig(pos, oldNode, oldMeta, _)
    logistica.on_signal_toggler_change(pos, oldNode, oldMeta)
  end

  local function on_rightclick(pos, _, player, _, _)
    if logistica.should_hide_from_player(pos, player:get_player_name()) then return end
    show_formspec(pos, player:get_player_name())
  end

  local function on_punch(pos, _, puncher, _)
    if not puncher or not puncher:is_player() then return end
    if puncher:get_player_control().sneak then
      logistica.show_output_at(logistica.requester_programmer_get_target(pos), tostring(minetest.hash_node_position(pos)))
    end
  end

  local function on_rotate(pos, node, player, mode, newParam2)
    local target = vector.add(pos, logistica.get_rot_directions(newParam2).backward)
    logistica.show_output_at(target, tostring(minetest.hash_node_position(pos)))
  end

  local logistica_callbacks = {
    on_connect_to_network = logistica.requester_programmer_on_connect,
    on_signal_received    = logistica.requester_programmer_on_signal_received,
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
    after_dig_node = after_dig,
    on_rightclick = on_rightclick,
    on_punch = on_punch,
    on_rotate = on_rotate,
    allow_metadata_inventory_put = allow_inv_put,
    allow_metadata_inventory_take = allow_inv_take,
    allow_metadata_inventory_move = allow_inv_move,
    logistica = logistica_callbacks,
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  local def_disabled = table.copy(def)
  local tiles_disabled = logistica.table_map(def.tiles, function(s) return s.."^logistica_disabled.png" end)
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3,
    not_in_creative_inventory = 1, pickaxey = 1, handy = 1, axey = 1 }
  def_disabled.after_place_node = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_punch = nil
  def_disabled.logistica = nil

  logistica.GROUPS.signal_togglers.register(lname)

  minetest.register_node(lname, def)
  minetest.register_node(lname.."_disabled", def_disabled)
end
