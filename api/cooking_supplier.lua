local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logistica_cooksup"
local ON_OFF_BUTTON = "on_off_btn"
local INV_MAIN   = "main"
local INV_CONFIG = "config"
local INV_HOUT   = "hout"

local TIMER_INTERVAL = 1

local forms = {}



local function get_lava_img(currLava, lavaCap)
  local lavaPercent = logistica.round(currLava / lavaCap * 100)
  local img = ""
  if lavaPercent > 0 then
    img = "image[0.4,1.4;1,3;logistica_lava_furnace_tank_bg.png^[lowpart:"..
      lavaPercent..":logistica_lava_furnace_tank.png]"
  else
    img = "image[0.4,1.4;1,3;logistica_lava_furnace_tank_bg.png]"
  end
  return img.."tooltip[0.4,1.4;1,3;"..FS("Remaining: ")..(currLava/1000)..FS(" Buckets").."]"
end

local function get_cooksup_formspec(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)
  local currLava = logistica.cooking_supplier_get_lava(pos)
  local lavaCap = logistica.cooking_supplier_get_lava_capacity()
  local chargeSeconds = logistica.cooking_supplier_get_charge_seconds(pos)
  local chargeCapSeconds = logistica.cooking_supplier_get_charge_capacity_seconds()
  local errorText = logistica.cooking_supplier_get_error(pos)
  local cookTime = logistica.cooking_supplier_get_configured_cook_time(pos)

  local cookTimeLabel = ""
  if errorText ~= "" then
    cookTimeLabel = "label[3.5,3.6;"..minetest.colorize("#FF5555", minetest.formspec_escape(errorText)).."]"
  elseif cookTime then
    cookTimeLabel = "label[3.5,3.6;"..FS("Cooking time: ")..string.format("%.1f", cookTime).."]"
  end

  return "formspec_version[4]" ..
    "size["..logistica.inv_size(10.5, 13.25).."]" ..
    logistica.ui.background..
    get_lava_img(currLava, lavaCap)..
    "label[0.5,1.1;"..FS("Lava").."]"..
    "label[1.5,4.9;"..FS("Accumulated Time: ")..string.format("%.1f / %.1f", chargeSeconds, chargeCapSeconds).."]"..
    logistica.ui.on_off_btn(isOn, 1.5, 2.6, ON_OFF_BUTTON, FS("Enable"), 0.8, 0.8)..
    "label[0.4,0.5;"..FS("Cooks configured item when requested by Network. Excess stored below.").."]"..
    "label[3.5,2.0;"..FS("Configure").."]"..
    "list["..posForm..";"..INV_CONFIG..";3.5,2.3;1,1;0]"..
    "label[5.8,2.0;"..FS("Output").."]"..
    "list["..posForm..";"..INV_MAIN..";5.8,2.3;1,1;0]"..
    cookTimeLabel..
    "label[0.5,5.6;"..FS("Excess items, provided as supply. If full, excess will be thrown out.").."]"..
    "list["..posForm..";"..INV_MAIN..";0.4,5.9;8,1;1]"..
    logistica.player_inv_formspec(0.4,7.8)..
    "listring["..posForm..";"..INV_MAIN.."]"..
    "listring[current_player;main]"
end

local function show_cooksup_formspec(playerName, pos)
  -- make sure we update the output item
  logistica.cooking_supplier_update_output(pos)
  forms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_cooksup_formspec(pos))
end

-- re-renders and re-sends the formspec as-is, without recomputing output/error state
-- (unlike show_cooksup_formspec) so it doesn't clobber a just-set transient message
local function reshow_cooksup_formspec_for_pos(pos)
  local formspec = get_cooksup_formspec(pos)
  for playerName, data in pairs(forms) do
    if data.position and vector.equals(data.position, pos) then
      minetest.show_formspec(playerName, FORMSPEC_NAME, formspec)
    end
  end
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
    show_cooksup_formspec(player:get_player_name(), pos)
  end
  return true
end

local function on_cooksup_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  show_cooksup_formspec(clicker:get_player_name(), pos)
end

local function after_place_cooksup(pos, placer, itemstack)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_MAIN, 9)
  inv:set_size(INV_CONFIG, 1)
  inv:set_size(INV_HOUT, 9)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_supplier_change(pos)
end

local function allow_cooksup_storage_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == INV_CONFIG then
    local check = logistica.cooking_supplier_check_configure(stack:get_name())
    if not check.accepted then
      logistica.cooking_supplier_set_reject_message(pos, stack, check.recipe)
      reshow_cooksup_formspec_for_pos(pos)
      return 0
    end
    local inv = minetest.get_meta(pos):get_inventory()
    local single = ItemStack(stack) ; single:set_count(1)
    inv:set_stack(listname, index, single)
    logistica.cooking_supplier_update_output(pos)
    reshow_cooksup_formspec_for_pos(pos)
  end
  return 0
end

local function allow_cooksup_inv_take(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == INV_CONFIG then
    local inv = minetest.get_meta(pos):get_inventory()
    inv:set_stack(listname, index, ItemStack(""))
    logistica.cooking_supplier_update_output(pos)
    reshow_cooksup_formspec_for_pos(pos)
    return 0
  elseif listname == INV_MAIN then
    if index == 1 then return 0
    else return stack:get_count() end
  end
  return 0
end

local function allow_cooksup_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end

local function on_cooksup_inventory_put(pos, listname, index, stack, player)
  logistica.cooking_supplier_update_output(pos)
end

local function on_cooksup_inventory_take(pos, listname, index, stack, player)
  logistica.cooking_supplier_update_output(pos)
end

local function can_dig_cooksup(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  local main = logistica.get_list(inv, INV_MAIN)
  for i = 2, #main do
    if not main[i]:is_empty() then return false end
  end
  return true
end

local function on_cooksup_power(pos, power)
  logistica.set_node_tooltip_from_state(pos, nil, power)
  logistica.cooking_supplier_update_output(pos)
  if power then
    logistica.start_node_timer(pos, TIMER_INTERVAL)
  end
end

local function on_cooksup_timer(pos, elapsed)
  if logistica.cooking_supplier_charge_tick(pos) then
    reshow_cooksup_formspec_for_pos(pos)
  end
  logistica.start_node_timer(pos, TIMER_INTERVAL)
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
function logistica.register_cooking_supplier(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local supplier_name = "logistica:"..lname
  logistica.GROUPS.cooking_suppliers.register(supplier_name)
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
    after_place_node = after_place_cooksup,
    after_dig_node = logistica.on_supplier_change,
    on_rightclick = on_cooksup_rightclick,
    allow_metadata_inventory_put = allow_cooksup_storage_inv_put,
    allow_metadata_inventory_take = allow_cooksup_inv_take,
    allow_metadata_inventory_move = allow_cooksup_inv_move,
    on_metadata_inventory_put = on_cooksup_inventory_put,
    on_metadata_inventory_take = on_cooksup_inventory_take,
    on_timer = logistica.on_timer_powered(on_cooksup_timer),
    can_dig = can_dig_cooksup,
    logistica = {
      on_power = on_cooksup_power,
      get_cache_list = logistica.cooking_supplier_get_main_list
    },
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(supplier_name, def)
  logistica.register_non_pushable(supplier_name)

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
