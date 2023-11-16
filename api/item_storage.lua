
local FORMSPEC_NAME = "logistica_itemstor"
local ON_OFF_BUTTON = "on_off_btn"
local ITEM_STORAGE_SIZE_PER_PAGE = 128
local SORT_PICKER = "sortby"
local SORT_BUTTON = "sortBtn"

local itemStorageForms = {}

local function get_item_storage_formspec(pos)
  local meta = minetest.get_meta(pos)
  local posForm = "nodemeta:"..pos.x..","..pos.y..","..pos.z
  local isOn = logistica.is_machine_on(pos)
  local sortValues = logistica.get_item_storage_sort_list_str()
  local selectedSortIdx = logistica.get_item_storage_selected_sort_index(meta)

  return "formspec_version[4]" ..
    "size[20.5,16]" ..
    logistica.ui.background..
    "label[5.3,10.6;Tool Box: Accepts only tools, no stackable items]"..
    logistica.ui.on_off_btn(isOn, 16.0, 11.0, ON_OFF_BUTTON, "Allow Storing from Network")..
    "dropdown[16,12;2,0.8;"..SORT_PICKER..";"..sortValues..";"..selectedSortIdx..";false]"..
    "button[18.5,12;1,0.8;"..SORT_BUTTON..";Sort]"..
    "list["..posForm..";main;0.4,0.5;16,8;0]"..
    "list[current_player;main;5.35,11.0;8,4;0]"..
    "listring[]"
end

local function show_item_storage_formspec(playerName, pos)
  itemStorageForms[playerName] = {position = pos}
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_item_storage_formspec(pos))
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not itemStorageForms[playerName] then return false end
  local pos = itemStorageForms[playerName].position
  if minetest.is_protected(pos, playerName) then return true end
  local meta = minetest.get_meta(pos)

  if fields.quit then
    itemStorageForms[playerName] = nil
  elseif fields[SORT_BUTTON] then
    logistica.sort_item_storage_list(meta)
  elseif fields[ON_OFF_BUTTON] then
    logistica.toggle_machine_on_off(pos)
    show_item_storage_formspec(player:get_player_name(), pos)
  elseif fields[SORT_PICKER] then
    logistica.set_item_storage_selected_sort_value(meta, fields[SORT_PICKER])
  end
  return true
end

local function on_item_storage_rightclick(pos, _, clicker, _, _)
  if not clicker or not clicker:is_player() then return end
  if minetest.is_protected(pos, clicker:get_player_name()) then return end
  show_item_storage_formspec(clicker:get_player_name(), pos)
end

local function after_place_item_storage(pos, _, _)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size("main", ITEM_STORAGE_SIZE_PER_PAGE)
  logistica.set_node_tooltip_from_state(pos)
  logistica.on_item_storage_change(pos)
end

local function allow_item_storage_storage_inv_put(pos, _, _, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if stack:get_stack_max() > 1 then return 0 end
  return stack:get_count()
end

local function allow_item_storage_inv_take(pos, _, _, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_item_storage_inv_move(pos, _, _, _, _, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return count
end

local function can_dig_item_storage(pos, _)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty("main")
end

----------------------------------------------------------------
-- Minetest registration
----------------------------------------------------------------

minetest.register_on_player_receive_fields(on_player_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    itemStorageForms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
function logistica.register_item_storage(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local item_storage_name = "logistica:"..lname
  logistica.item_storage[item_storage_name] = true
  local grps = {oddly_breakable_by_hand = 3, cracky = 3 }
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = item_storage_name,
    sounds = logistica.node_sound_metallic(),
    after_place_node = after_place_item_storage,
    after_destruct = logistica.on_item_storage_change,
    on_rightclick = on_item_storage_rightclick,
    allow_metadata_inventory_put = allow_item_storage_storage_inv_put,
    allow_metadata_inventory_take = allow_item_storage_inv_take,
    allow_metadata_inventory_move = allow_item_storage_inv_move,
    can_dig = can_dig_item_storage,
    logistica = {
      on_power = function(pos, power) logistica.set_node_tooltip_from_state(pos, nil, power) end
    }
  }

  minetest.register_node(item_storage_name, def)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1 }
  def_disabled.on_construct = nil
  def_disabled.after_destruct = nil
  def_disabled.on_punch = nil
  def_disabled.on_rightclick = nil
  def_disabled.on_timer = nil
  def_disabled.logistica = nil

  minetest.register_node(item_storage_name.."_disabled", def_disabled)

end
