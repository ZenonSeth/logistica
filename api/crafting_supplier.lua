
local S = logistica.TRANSLATOR

local FORMSPEC_NAME = "logistica_craftsup"
local ON_OFF_BUTTON = "on_off_btn"
local INV_MAIN = "main"
local INV_CRAFT = "crf"
local INV_HOUT = "hout"

local forms = {}

local function update_craft_output(inv)
  local inputList = inv:get_list(INV_CRAFT)
  local out, _ = minetest.get_craft_result({
    method = "normal",
    width = 3,
    items = inputList
  })
  inv:set_stack(INV_MAIN, 1, out.item)
end

local function get_craftsup_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)

  return "formspec_version[4]" ..
    "size["..(logistica.inv_width + 2.5)..",13.25]" ..
    logistica.ui.background..
    logistica.ui.on_off_btn(isOn, 1.1, 2.6, ON_OFF_BUTTON, S("Enable"))..
    "label[0.4,0.5;"..S("Crafts items when requested by Network. Excess stored below.").."]"..
    "list["..posForm..";"..INV_CRAFT..";3.4,1.5;3,3;0]"..
    "list["..posForm..";"..INV_MAIN..";7.1,2.75;1,1;0]"..
    "label[4.6,1.2;Recipe]"..
    "label[0.5,5.6;"..S("Excess items, provided as supply. If full\\, excess will be thrown out.").."]"..
    "list["..posForm..";"..INV_MAIN..";0.4,5.9;8,1;1]"..
    logistica.inventory_formspec(0.4,7.8)..
    "listring["..posForm..";"..INV_MAIN.."]"..
    "listring[current_player;main]"
end

local function show_craftsup_formspec(playerName, pos)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_craftsup_formspec(pos))
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
    show_craftsup_formspec(player:get_player_name(), pos)
  end
  return true
end

local function on_craftsup_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_craftsup_formspec(clicker:get_player_name(), pos)
end

local function after_place_craftsup(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_MAIN, 9)
  inv:set_size(INV_CRAFT, 9)
  inv:set_width(INV_CRAFT, 3)
  inv:set_size(INV_HOUT, 9)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function allow_craftsup_storage_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_CRAFT then
    local inv = minetest.get_meta(pos):get_inventory()
    local st = inv:get_stack(listname, index)
    st:add_item(stack)
    inv:set_stack(listname, index, st)
    update_craft_output(minetest.get_meta(pos):get_inventory())
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
  end
  return 0
end

local function allow_craftsup_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_CRAFT then
    local inv = minetest.get_meta(pos):get_inventory()
    local st = inv:get_stack(listname, index)
    st:take_item(stack:get_count())
    inv:set_stack(listname, index, st)
    update_craft_output(minetest.get_meta(pos):get_inventory())
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
    return 0
  elseif listname == INV_MAIN then
    if index == 1 then return 0
    else return stack:get_count() end
  end
  return 0
end

local function allow_craftsup_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

local function on_craftsup_inventory_put(pos, listname, index, stack, player)
  update_craft_output(minetest.get_meta(pos):get_inventory())
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function on_craftsup_inventory_take(pos, listname, index, stack, player)
  update_craft_output(minetest.get_meta(pos):get_inventory())
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end

local function can_dig_craftsup(pos, player)
  local main = minetest.get_meta(pos):get_inventory():get_list(INV_MAIN) or {}
  for i = 2, #main do
    if not main[i]:is_empty() then return false end
  end
  return true
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
function logistica.register_crafting_supplier(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local supplier_name = "logistica:"..lname
  logistica.craftsups[supplier_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1, }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = supplier_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_craftsup,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_craftsup_rightclick,
    allow_metadata_inventory_put = allow_craftsup_storage_inv_put,
    allow_metadata_inventory_take = allow_craftsup_inv_take,
    allow_metadata_inventory_move = allow_craftsup_inv_move,
    on_metadata_inventory_put = on_craftsup_inventory_put,
    on_metadata_inventory_take = on_craftsup_inventory_take,
    can_dig = can_dig_craftsup,
    logistica = {
      on_power = function(pos, power) logistica.set_node_tooltip_from_state(pos, nil, power) end
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(supplier_name, def)

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

  minetest.register_node(supplier_name.."_disabled", def_disabled)

end
