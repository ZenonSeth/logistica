local FS = logistica.FTRANSLATOR

local INV_SRC = "src"
local INV_DST = "dst"
local INV_CRAFT = "crf"
local INV_CRAFT_RES = "crfres"

local ON_OFF_BTN = "onffbtn"
local META_SHOW_ITEM = "show_item"

local TIMER_SHORT = 1.0
local TIMER_LONG = 3.0


local function get_show_item(pos)
  return minetest.get_meta(pos):get_int(META_SHOW_ITEM) == 1
end

local function set_show_item(pos, shouldShow)
  minetest.get_meta(pos):set_int(META_SHOW_ITEM, shouldShow and 1 or 0)
end

-- `newParam2` is optional, will override the lookup of node.param2 for rotation
local function update_front_image(pos, newParam2)
  logistica.remove_item_on_block_front(pos)
  if not get_show_item(pos) then return end
  local item = minetest.get_meta(pos):get_inventory():get_stack(INV_CRAFT_RES, 1)
  logistica.display_item_on_block_front(pos, item:get_name(), newParam2)
end

local DISPLAY_UPDATE_DEBOUNCE_S = 0.2
local pendingDisplayUpdates = {}

local function update_craft_output(pos, inv)
  local inputList = logistica.get_list(inv, INV_CRAFT)
  local out, _ = minetest.get_craft_result({
    method = "normal",
    width = 3,
    items = inputList
  })
  local item = out and out.item or ItemStack("")
  inv:set_stack(INV_CRAFT_RES, 1, item)
  logistica.append_makes_infotext(pos, item)

  -- the front-image update involves an entity respawn (get_objects_inside_radius + add_entity),
  -- which is expensive if triggered on every single inventory click/timer tick, so debounce it
  local hash = minetest.hash_node_position(pos)
  if pendingDisplayUpdates[hash] then return end
  pendingDisplayUpdates[hash] = minetest.after(DISPLAY_UPDATE_DEBOUNCE_S, function()
    pendingDisplayUpdates[hash] = nil
    update_front_image(pos)
  end)
end

local function cancel_pending_display_update(pos)
  local hash = minetest.hash_node_position(pos)
  local job = pendingDisplayUpdates[hash]
  if job then
    job:cancel()
    pendingDisplayUpdates[hash] = nil
  end
end

--------------------------------
-- Formspec
--------------------------------

local SHOW_ITEM_TOOLTIP = FS("Show the crafted item on the front of this node")

local function get_formspec(pos, _isOn)
  local isOn = _isOn
  if isOn == nil then isOn = logistica.is_machine_on(pos) end
  local showStr = get_show_item(pos) and "true" or "false"
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.5, 13.25).."]" ..
    logistica.ui.background_lava_furnace..
    "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]"..
    "list[context;src;0.4,5;8,2;0]"..
    logistica.player_inv_formspec(0.4,7.8)..
    "list[context;dst;5.5,0.6;4,3;0]"..
    "list[context;crf;0.2,0.6;3,3;0]"..
    "list[context;crfres;3.9,1.85;1,1;0]"..
    "checkbox[3.8,1.45;show_item;"..FS("Show")..";"..showStr.."]"..
    "tooltip[show_item;"..SHOW_ITEM_TOOLTIP.."]"..
    "listring[context;dst]"..
    "listring[current_player;main]"..
    "listring[context;src]"..
    "listring[current_player;main]"..
    "label[1.4,0.3;"..FS("Recipe").."]"..
    "label[7.3,0.3;"..FS("Output").."]"..
    "label[4.9,4.7;"..FS("Input").."]"..
    logistica.ui.on_off_btn(isOn, 4, 3.3, ON_OFF_BTN, FS("Enable"))
end

--------------------------------
-- Callbacks
--------------------------------

local function autocrafter_timer(pos, elapsed)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local success = logistica.autocrafting_produce_single_item(inv, INV_CRAFT, INV_SRC, INV_DST, true)
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
    logistica.set_node_tooltip_from_state(pos)
end

local function autocrafter_on_destruct(pos)
  cancel_pending_display_update(pos)
  logistica.remove_item_on_block_front(pos)
end

local function autocrafter_on_rotate(pos, node, player, mode, newParam2)
  update_front_image(pos, newParam2)
end

local function autocrafter_can_dig(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty(INV_SRC) and inv:is_empty(INV_DST)
end

local function autocrafter_allow_metadata_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == INV_CRAFT_RES then return 0 end
  if listname == INV_CRAFT then
    local inv = minetest.get_meta(pos):get_inventory()
    local st = inv:get_stack(listname, index)
    if st:get_name() == stack:get_name() then
      st:add_item(stack)
      inv:set_stack(listname, index, st)
    else
      inv:set_stack(listname, index, stack)
    end
    update_craft_output(pos, inv)
    return 0
  end
  return stack:get_count()
end

local function autocrafter_allow_metadata_inv_take(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname == INV_CRAFT_RES then return 0 end
  if listname == INV_CRAFT then
    local inv = minetest.get_meta(pos):get_inventory()
    local st = inv:get_stack(listname, index)
    st:take_item(stack:get_count())
    inv:set_stack(listname, index, st)
    update_craft_output(pos, inv)
    return 0
  end
  return stack:get_count()
end

local function autocrafter_allow_metadata_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if from_list == INV_DST and to_list == INV_SRC then return count end
  if from_list == INV_CRAFT and to_list == INV_CRAFT then return count end
  return 0
end

local function autocrafter_on_inv_change(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  update_craft_output(pos, inv)
  logistica.start_node_timer(pos, TIMER_SHORT)
end

local function autocrafter_receive_fields(pos, formname, fields, sender)
  if not sender:is_player() then return end
  if not logistica.player_has_network_access(pos, sender:get_player_name()) then return end
  if fields[ON_OFF_BTN] then
    logistica.toggle_machine_on_off(pos)
  end
  if fields.show_item then
    set_show_item(pos, fields.show_item == "true")
    update_front_image(pos)
    minetest.get_meta(pos):set_string("formspec", get_formspec(pos))
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
    description = desc,
    tiles = tiles,
    paramtype2 = "facedir",
    groups = { cracky= 2, pickaxey = 2, logistica_autocrafter = 1 },
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
    on_rotate = autocrafter_on_rotate,
    logistica = {
      on_power = autocrafter_on_power,
      on_paste_state = autocrafter_on_inv_change,
    },
    _mcl_hardness = 3,
    _mcl_blast_resistance = 15
  }

  local autocrafterName = "logistica:"..lname
  minetest.register_node(autocrafterName, def)
  logistica.register_non_pushable(autocrafterName)

end
