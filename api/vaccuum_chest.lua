local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logistica_vaccuum_chest"
local ON_OFF_BUTTON = "on_off_btn"
local META_RADIUS = "pickup_radius"
local MIN_RADIUS = 1
local MAX_RADIUS = logistica.settings.vaccuum_chest_max_radius
local FILTER_LIST = "filter"
local NUM_FILTER_SLOTS = 8

local function get_radius(pos)
  local r = minetest.get_meta(pos):get_int(META_RADIUS)
  if r < 1 then return MAX_RADIUS end
  return r
end

local forms = {}

local function get_vaccuum_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)
  local radius = get_radius(pos)

  return "formspec_version[4]" ..
    "size["..logistica.inv_size(10.5, 12.25).."]" ..
    logistica.ui.background..
    logistica.ui.button_only_style..
    logistica.ui.on_off_btn(isOn, 6.0, 5.05, ON_OFF_BUTTON, FS("Enable"))..
    "label[0.6,0.6;"..FS("Supplies collected items to the network.").."]"..
    "list["..posForm..";main;0.4,1.2;8,2;0]"..
    "label[0.4,3.65;"..FS("Only pick up these types of items (if empty, then vacuum all):").."]"..
    "list["..posForm..";filter;0.4,3.85;8,1;0]"..
    "label[0.6,5.4;"..FS("Vacuum Range:").."]"..
    "button[3.1,5.1;0.65,0.65;range_dec;-]"..
    "label[3.95,5.4;"..tostring(radius).."]"..
    "button[4.3,5.1;0.65,0.65;range_inc;+]"..
    logistica.player_inv_formspec(0.4,6.05)..
    "listring[current_player;main]"..
    "listring["..posForm..";main]"
end

local function show_vaccuum_formspec(playerName, pos)
  forms[playerName] = {position = pos}
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:get_size(FILTER_LIST) < NUM_FILTER_SLOTS then
    inv:set_size(FILTER_LIST, NUM_FILTER_SLOTS)
  end
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_vaccuum_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return false end
  local pos = forms[playerName].position
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_vaccuum_formspec(player:get_player_name(), pos)
  elseif fields.range_inc or fields.range_dec then
    local delta = fields.range_inc and 1 or -1
    local new_radius = logistica.clamp(get_radius(pos) + delta, MIN_RADIUS, MAX_RADIUS)
    minetest.get_meta(pos):set_int(META_RADIUS, new_radius)
    show_vaccuum_formspec(player:get_player_name(), pos)
  end
  return true
end

local function on_vaccuum_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  show_vaccuum_formspec(clicker:get_player_name(), pos)
end

local function after_place_vaccuum(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size("main", logistica.get_supplier_inv_size(pos))
  inv:set_size(FILTER_LIST, NUM_FILTER_SLOTS)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function allow_vaccuum_storage_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == FILTER_LIST then
    local inv = minetest.get_meta(pos):get_inventory()
    local copyStack = ItemStack(stack:get_name())
    copyStack:set_count(1)
    inv:set_stack(FILTER_LIST, index, copyStack)
    return 0
  end
  return stack:get_count()
end

local function allow_vaccuum_inv_take(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == FILTER_LIST then
    local inv = minetest.get_meta(pos):get_inventory()
    inv:set_stack(FILTER_LIST, index, ItemStack(""))
    return 0
  end
  return stack:get_count()
end

local function allow_vaccuum_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if from_list == FILTER_LIST or to_list == FILTER_LIST then return 0 end
  return count
end

local function on_vaccuum_inventory_put(pos, _, _, _, _)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function on_vaccuum_inventory_take(pos, _, _, _, _)
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function can_dig_vaccuum(pos, _)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty("main")
end

local function on_vaccuum_power(pos, power)
  logistica.vaccuum_chest_on_power(pos, power)
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

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
-- `inventorySize` should be 16 at max
function logistica.register_vaccuum_chest(desc, name, inventorySize, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local vaccuum_name = "logistica:"..lname
  logistica.GROUPS.vaccuum_suppliers.register(vaccuum_name)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = vaccuum_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_vaccuum,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_vaccuum_rightclick,
    allow_metadata_inventory_put = allow_vaccuum_storage_inv_put,
    allow_metadata_inventory_take = allow_vaccuum_inv_take,
    allow_metadata_inventory_move = allow_vaccuum_inv_move,
    on_metadata_inventory_put = on_vaccuum_inventory_put,
    on_metadata_inventory_take = on_vaccuum_inventory_take,
    on_timer = logistica.vaccuum_chest_on_timer,
    can_dig = can_dig_vaccuum,
    logistica = {
      inventory_size = inventorySize,
      on_power = on_vaccuum_power,
      automatable = true,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(vaccuum_name, def)
  logistica.register_non_pushable(vaccuum_name)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, handy = 1, pickaxey = 1, axey = 1, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(vaccuum_name.."_disabled", def_disabled)

end
