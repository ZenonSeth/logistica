local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "logistica_bktempt"
local INV_INPUT = "input"
local INV_MAIN = "main"

local ON_OFF_BTN = "onffbtn"

local forms = {}

--------------------------------
-- Formspec
--------------------------------

local function get_emptier_formspec(pos, _isOn)
  local isOn = _isOn
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  if isOn == nil then isOn = logistica.is_machine_on(pos) end
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.5, 12.0).."]" ..
    logistica.ui.background..
    "label[0.4,0.4;"..S("Provided with filled buckets, empties them into any network reservoirs").."]"..
    "label[0.4,0.8;"..S("Resulting empty buckets are provided as passive supply to network").."]"..
    "list["..posForm..";"..INV_INPUT..";0.3,1.3;6,4;0]"..
    "list["..posForm..";"..INV_MAIN..";9.1,1.3;1,4;0]"..
    "image[7.8,3.1;1,1;logistica_icon_next.png]"..
    "label[1.4,6.4;"..S("Input: Filled Buckets to be emptied").."]"..
    logistica.ui.on_off_btn(isOn, 7.7, 2.2, ON_OFF_BTN, S("Enable"))..
    logistica.player_inv_formspec(0.4, 7.0)..
    "listring["..posForm..";"..INV_INPUT.."]"..
    "listring[current_player;main]"..
    "listring["..posForm..";"..INV_INPUT.."]"..
    "listring["..posForm..";"..INV_MAIN.."]"..
    "listring[current_player;main]"
end

local function show_emptier_formspec(playerName, pos)
  if not forms[playerName] then forms[playerName] = {position = pos} end
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_emptier_formspec(pos))
end

--------------------------------
-- Callbacks
--------------------------------

local function emptier_after_place(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_INPUT, 24)
  inv:set_size(INV_MAIN, 4)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function emptier_can_dig(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty(INV_INPUT) and inv:is_empty(INV_MAIN)
end

local function emptier_allow_metadata_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_MAIN then return 0 end
  if listname == INV_INPUT then
    if logistica.reservoir_is_full_bucket(stack:get_name()) then return stack:get_count()
    else return 0 end
  end
  return stack:get_count()
end

local function emptier_allow_metadata_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function emptier_allow_metadata_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if to_list == INV_MAIN then return 0 end
  return count
end

local function emptier_on_inv_change(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  logistica.start_node_timer(pos, 1)
end

local function on_emptier_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_emptier_formspec(clicker:get_player_name(), pos)
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[ON_OFF_BTN] then
    logistica.toggle_machine_on_off(pos)
    show_emptier_formspec(playerName, pos)
  end
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

--------------------------------
-- Public API
--------------------------------

function logistica.register_bucket_emptier(desc, name, tiles)
  local lname = name:gsub("%s", "_"):lower()
  local emptier_name = "logistica:"..lname

  logistica.GROUPS.bucket_emptiers.register(emptier_name)
  local def = {
    description = S(desc),
    tiles = tiles,
    paramtype2 = "facedir",
    groups = { cracky= 2, pickaxey = 2, [logistica.TIER_ALL] = 1 },
    is_ground_content = false,
    sounds = logistica.node_sound_metallic(),
    can_dig = emptier_can_dig,
    drop = emptier_name,
    on_timer = logistica.on_timer_powered(logistica.emptier_timer),
    after_place_node = emptier_after_place,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_emptier_rightclick,
    on_metadata_inventory_move = emptier_on_inv_change,
    on_metadata_inventory_put = emptier_on_inv_change,
    on_metadata_inventory_take = emptier_on_inv_change,
    allow_metadata_inventory_put = emptier_allow_metadata_inv_put,
    allow_metadata_inventory_move = emptier_allow_metadata_inv_move,
    allow_metadata_inventory_take = emptier_allow_metadata_inv_take,
    logistica = {
      on_power = logistica.emptier_on_power,
      on_connect_to_network = function(pos, networkId)
        logistica.start_node_timer(pos, 1)
      end,
    },
    _mcl_hardness = 3,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(emptier_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, axey = 1, handy = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(emptier_name.."_disabled", def_disabled)
end
