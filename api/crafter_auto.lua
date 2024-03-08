
local S = logistica.TRANSLATOR

local INV_SRC = "src"
local INV_DST = "dst"
local INV_CRAFT = "crf"
local INV_CRAFT_RES = "crfres"

local ON_OFF_BTN = "onffbtn"

local TIMER_SHORT = 1.0
local TIMER_LONG = 3.0


local function update_craft_output(inv)
  local inputList = inv:get_list(INV_CRAFT)
  local out, _ = minetest.get_craft_result({
    method = "normal",
    width = 3,
    items = inputList
  })
  inv:set_stack(INV_CRAFT_RES, 1, out.item)
end

--------------------------------
-- Formspec
--------------------------------

local function get_formspec(pos, _isOn)
  local isOn = _isOn
  if isOn == nil then isOn = logistica.is_machine_on(pos) end
  return "formspec_version[4]"..
    "size[10.5,13]"..
    logistica.ui.background_lava_furnace..
    "listring[context;INV_MAIN]"..
    "list[context;src;0.4,5;8,2;0]"..
    "list[current_player;main;0.4,7.8;8,4;0]"..
    "list[context;dst;5.5,0.6;4,3;0]"..
    "list[context;crf;0.2,0.6;3,3;0]"..
    "list[context;crfres;3.9,1.85;1,1;0]"..
    "listring[current_player;main]"..
    "listring[context;src]"..
    "listring[context;dst]"..
    "listring[current_player;main]"..
    "label[1.4,0.3;Recipe]"..
    "label[7.3,0.3;Output]"..
    "label[4.9,4.7;Input]"..
    logistica.ui.on_off_btn(isOn, 4, 3.3, ON_OFF_BTN, S("Enable"))
end

--------------------------------
-- Callbacks
--------------------------------

local function autocrafter_timer(pos, elapsed)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local success = logistica.autocrafting_produce_single_item(inv, INV_CRAFT, INV_SRC, INV_DST)
  if success then logistica.start_node_timer(pos, TIMER_SHORT)
  else logistica.start_node_timer(pos, TIMER_LONG) end
  return false
end

local function autocrafter_on_construct(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size(INV_SRC, 16)
		inv:set_size(INV_DST, 12)
		inv:set_size(INV_CRAFT, 9)
    inv:set_width(INV_CRAFT, 3)
		inv:set_size(INV_CRAFT_RES, 1)
    meta:set_string("formspec", get_formspec(pos))
end

local function autocrafter_on_destruct(pos)
end

local function autocrafter_can_dig(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty(INV_SRC) and inv:is_empty(INV_DST)
end

local function autocrafter_allow_metadata_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_CRAFT_RES then return 0 end
  if listname == INV_CRAFT then
    local inv = minetest.get_meta(pos):get_inventory()
    local st = inv:get_stack(listname, index)
    st:add_item(stack)
    inv:set_stack(listname, index, st)
    update_craft_output(inv)
    return 0
  end
  return stack:get_count()
end

local function autocrafter_allow_metadata_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_CRAFT_RES then return 0 end
  if listname == INV_CRAFT then
    local inv = minetest.get_meta(pos):get_inventory()
    local st = inv:get_stack(listname, index)
    st:take_item(stack:get_count())
    inv:set_stack(listname, index, st)
    update_craft_output(inv)
    return 0
  end
  return stack:get_count()
end

local function autocrafter_allow_metadata_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if from_list == INV_DST and to_list == INV_SRC then return count end
  return 0
end

local function autocrafter_on_inv_change(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  logistica.start_node_timer(pos, TIMER_SHORT)
end

local function autocrafter_receive_fields(pos, formname, fields, sender)
  if not sender:is_player() then return end
  if minetest.is_protected(pos, sender:get_player_name()) then return end
  if fields[ON_OFF_BTN] then
    logistica.toggle_machine_on_off(pos)
  end
end

local function autocrafter_on_power(pos, power)
  if power then
    logistica.start_node_timer(pos, TIMER_SHORT)
  end
  local meta = minetest.get_meta(pos)
  meta:set_string("formspec", get_formspec(pos, power))
  logistica.set_node_tooltip_from_state(pos, nil, power)
end

--------------------------------
-- Public API
--------------------------------

--[[
The Autocrafter does not connect to networks, but it can be tnteracted with using network Requesters and Importers
]]
function logistica.register_autocrafter(desc, name, tiles)
  local lname = name:gsub("%s", "_"):lower()
  local def = {
    description = S(desc),
    tiles = tiles,
    paramtype2 = "facedir",
    groups = { cracky= 2 },
    is_ground_content = false,
    sounds = logistica.sound_mod.node_sound_stone_defaults(),
    can_dig = autocrafter_can_dig,
    on_timer = logistica.on_timer_powered(autocrafter_timer),
    on_construct = autocrafter_on_construct,
    on_destruct = autocrafter_on_destruct,
    on_metadata_inventory_move = autocrafter_on_inv_change,
    on_metadata_inventory_put = autocrafter_on_inv_change,
    on_metadata_inventory_take = autocrafter_on_inv_change,
    allow_metadata_inventory_put = autocrafter_allow_metadata_inv_put,
    allow_metadata_inventory_move = autocrafter_allow_metadata_inv_move,
    allow_metadata_inventory_take = autocrafter_allow_metadata_inv_take,
    on_receive_fields = autocrafter_receive_fields,
    logistica = {
      on_power = autocrafter_on_power,
    }
  }

  minetest.register_node("logistica:"..lname, def)

end
