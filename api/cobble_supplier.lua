
local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "logistica_cobblegen"
local ON_OFF_BUTTON = "on_off_btn"
local INV_DST = "main"
local INV_UPG = "upgr"

local META_UPGRADE_COUNT = "logupg"
local ITEM_UPGRADE = "logistica:cobblegen_upgrade"
local DEFAULT_GEN_RATE = 1
local DEFAULT_MULT_PER_UPGRADE = 2
local COBBLESTONE = logistica.itemstrings.cobble

local UPGRADE_TOOLTIP = S("Upgrade slots: The 2 slots to the right are for placing cobble generator upgrades.")

local TIMER_SHORT = 2
local TIMER_LONG = 4

local forms = {}

local function update_upgrade_count(pos, optMeta)
    local meta = optMeta or minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local upgCount = 0
    for _, st in ipairs(inv:get_list(INV_UPG) or {}) do
      if not st:is_empty() then upgCount = upgCount + 1 end
    end
    meta:set_int(META_UPGRADE_COUNT, upgCount)
end

local function get_upgrade_count(pos, optMeta)
    local meta = optMeta or minetest.get_meta(pos)
    return meta:get_int(META_UPGRADE_COUNT)
end

local function get_cobblegen_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)

  return "formspec_version[4]" ..
    "size["..logistica.inv_size(10.5, 8.5).."]" ..
    logistica.ui.background..
    logistica.ui.on_off_btn(isOn, 0.4, 1.3, ON_OFF_BUTTON, S("Enable"))..
    logistica.player_inv_formspec(0.4, 2.9)..
    "list["..posForm..";"..INV_UPG..";7.8,1.1;2,1;0]"..
    "listring["..posForm..";"..INV_DST.."]"..
    "listring[current_player;main]"..
    "list["..posForm..";"..INV_DST..";2.9,1.1;2,1;0]"..
    "label[0.4,0.5;"..S("Generates Cobblestone and passively supplies it to Network").."]"..
    "image[6.6,1.1;1,1;logistica_icon_upgrade.png]"..
    "tooltip[6.6,1.1;1,1;"..UPGRADE_TOOLTIP.."]"
end

local function show_cobblegen_formspec(playerName, pos)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_cobblegen_formspec(pos))
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
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_cobblegen_formspec(player:get_player_name(), pos)
  end
  return true
end

local function on_cobblegen_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_cobblegen_formspec(clicker:get_player_name(), pos)
end

local function after_place_cobblegen(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_DST, 2)
  inv:set_size(INV_UPG, 2)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function allow_cobblegen_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_UPG and stack:get_name() == ITEM_UPGRADE then
    local inv = minetest.get_meta(pos):get_inventory()
    if inv:get_stack(listname, index):is_empty() then return 1
    else return 0 end
  end
  return 0
end

local function allow_cobblegen_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_cobblegen_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

local function on_cobblegen_inventory_put(pos, listname, index, stack, player)
  if listname == INV_DST then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  elseif listname == INV_UPG then
    update_upgrade_count(pos)
  end
end

local function on_cobblegen_inventory_take(pos, listname, index, stack, player)
  if listname == INV_DST then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  elseif listname == INV_UPG then
    update_upgrade_count(pos)
  end
end

local function can_dig_cobblegen(pos, player)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty(INV_DST) and inv:is_empty(INV_UPG)
end

local function on_cobblegen_power(pos, power)
  logistica.set_node_tooltip_from_state(pos, nil, power)
  if power then
    logistica.start_node_timer(pos, TIMER_SHORT)
  end
end

local function on_cobblegen_timer(pos, elapsed)
  local meta = minetest.get_meta(pos)
  local upgCount = get_upgrade_count(pos, meta)
  local inv = meta:get_inventory()
  local count = DEFAULT_GEN_RATE * DEFAULT_MULT_PER_UPGRADE ^ upgCount
  local stack = ItemStack(COBBLESTONE) ; stack:set_count(count)
  local needToUpdate = inv:is_empty(INV_DST)
  local leftover = inv:add_item(INV_DST, stack)
  if leftover:is_empty() then
    logistica.start_node_timer(pos, TIMER_SHORT)
  else
    logistica.start_node_timer(pos, TIMER_LONG)
  end
  if needToUpdate then
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end
  return false
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
function logistica.register_cobble_generator_supplier(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local supplier_name = "logistica:"..lname
  logistica.suppliers[supplier_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "none",
    paramtype2 = "facedir",
    is_ground_content = false,
    sunlight_propagates = false,
    groups = grps,
    drop = supplier_name,
    sounds = logistica.node_sound_metallic(),
    light_source = 8,
    after_place_node = after_place_cobblegen,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_cobblegen_rightclick,
    allow_metadata_inventory_put = allow_cobblegen_storage_inv_put,
    allow_metadata_inventory_take = allow_cobblegen_inv_take,
    allow_metadata_inventory_move = allow_cobblegen_inv_move,
    on_metadata_inventory_put = on_cobblegen_inventory_put,
    on_metadata_inventory_take = on_cobblegen_inventory_take,
    on_timer = logistica.on_timer_powered(on_cobblegen_timer),
    can_dig = can_dig_cobblegen,
    logistica = {
      on_power = on_cobblegen_power,
      supplierMayAccept = false,
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(supplier_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, handy = 1, pickaxey = 1, axey = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_dig_node = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(supplier_name.."_disabled", def_disabled)

end
