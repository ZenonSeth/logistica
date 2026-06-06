local FS = logistica.FTRANSLATOR

local INV_SRC = "src"
local INV_DST = "dst"
local DST_SIZE = 16

local DISASSEMBLE_BTN = "dis"
local ARROW_IMG = "logistica_lava_furnace_arrow_bg.png^[transformFYR90"

local PREV_X    = 3.75
local PREV_Y    = 0.5
local PREV_STEP = 1.05

local function get_preview_formspec(itemName)
  if not itemName or itemName == "" then return "" end
  local recipes = logistica.get_disassemble_recipes(itemName)
  if not recipes or #recipes == 0 then return "" end
  local recipe = recipes[1]
  local output_count = recipe.output_count

  local items = {}
  for name, count in pairs(recipe.ingredients) do
    local per_item = math.floor(count / output_count)
    if per_item > 0 then
      items[#items + 1] = { name = name, count = per_item }
    end
  end
  table.sort(items, function(a, b) return a.name < b.name end)

  local result = ""
  for i = 1, math.min(#items, 9) do
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    local x = PREV_X + col * PREV_STEP
    local y = PREV_Y + row * PREV_STEP
    local item = items[i]
    local desc = minetest.formspec_escape(ItemStack(item.name):get_description())
    result = result ..
      "item_image[" .. x .. "," .. y .. ";1,1;" .. item.name .. " " .. item.count .. "]" ..
      "tooltip[" .. x .. "," .. y .. ";1,1;" .. desc .. " x" .. item.count .. "]"
  end
  return result
end

local function get_formspec(pos, inv)
  local src_stack = inv and inv:get_stack(INV_SRC, 1) or ItemStack("")
  return "formspec_version[4]" ..
    "size[" .. logistica.inv_size(11.0, 12.5) .. "]" ..
    logistica.ui.background_lava_furnace..
    -- "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
    "label[0.4,0.35;" .. FS("Put a Logistica machine here to disassemble it") .. "]" ..
    "list[context;" .. INV_SRC .. ";0.75,1.5;1,1;0]" ..
    "image[2.05,1.625;1.4,0.75;" .. ARROW_IMG .. "]" ..
    get_preview_formspec(src_stack:get_name()) ..
    "button[3.75,3.75;3.15,0.8;" .. DISASSEMBLE_BTN .. ";" .. FS("Disassemble") .. "]" ..
    "list[context;" .. INV_DST .. ";0.75,4.75;8,2;0]" ..
    "listring[context;" .. INV_DST .. "]" ..
    "listring[current_player;main]" ..
    "listring[context;" .. INV_SRC .. "]" ..
    "listring[current_player;main]" ..
    logistica.player_inv_formspec(0.75, 7.5)
end

local function disassembler_on_construct(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_SRC, 1)
  inv:set_size(INV_DST, DST_SIZE)
  inv:set_width(INV_DST, 8)
  meta:set_string("formspec", get_formspec(pos, inv))
end

local function disassembler_can_dig(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty(INV_SRC) and inv:is_empty(INV_DST)
end

local function disassembler_allow_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_DST then return 0 end
  if listname == INV_SRC then
    local recipes = logistica.get_disassemble_recipes(stack:get_name())
    if not recipes or #recipes == 0 then return 0 end
    return 1
  end
  return 0
end

local function disassembler_allow_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function disassembler_allow_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if from_list == INV_DST and to_list == INV_DST then return count end
  return 0
end

local function disassembler_on_inv_change(pos)
  local meta = minetest.get_meta(pos)
  meta:set_string("formspec", get_formspec(pos, meta:get_inventory()))
end

local function do_disassemble(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local src_stack = inv:get_stack(INV_SRC, 1)
  if src_stack:is_empty() then return end

  local recipes = logistica.get_disassemble_recipes(src_stack:get_name())
  if not recipes or #recipes == 0 then return end

  local recipe = recipes[1]
  local output_count = recipe.output_count
  local machine_count = src_stack:get_count()

  local to_add = {}
  for name, count in pairs(recipe.ingredients) do
    local per_item = math.floor(count / output_count) * machine_count
    if per_item > 0 then
      to_add[#to_add + 1] = ItemStack(name .. " " .. per_item)
    end
  end

  for _, stack in ipairs(to_add) do
    if not inv:room_for_item(INV_DST, stack) then return end
  end

  inv:set_stack(INV_SRC, 1, ItemStack(""))
  for _, stack in ipairs(to_add) do
    inv:add_item(INV_DST, stack)
  end

  meta:set_string("formspec", get_formspec(pos, inv))
end

local function disassembler_on_timer(pos, elapsed)
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:is_empty(INV_SRC) then return false end
  do_disassemble(pos)
  return false
end

local function disassembler_receive_fields(pos, formname, fields, sender)
  if not sender or not sender:is_player() then return end
  if minetest.is_protected(pos, sender:get_player_name()) then return end
  if fields[DISASSEMBLE_BTN] then do_disassemble(pos) end
end

--------------------------------
-- Public API
--------------------------------

--[[
The Disassembler does not connect to networks, but its output inventory is
accessible by network Requesters and Importers (same pattern as Autocrafter).
Only items registered via logistica.register_craft are accepted in the input slot.
]]
function logistica.register_disassembler(desc, name, tiles)
  local lname = name:gsub("%s", "_"):lower()
  local def = {
    description = desc,
    tiles = tiles,
    paramtype2 = "facedir",
    groups = { cracky = 2, pickaxey = 2 },
    is_ground_content = false,
    sounds = logistica.sound_mod.node_sound_stone_defaults(),
    can_dig = disassembler_can_dig,
    on_timer = disassembler_on_timer,
    on_construct = disassembler_on_construct,
    on_metadata_inventory_put = disassembler_on_inv_change,
    on_metadata_inventory_take = disassembler_on_inv_change,
    on_metadata_inventory_move = disassembler_on_inv_change,
    allow_metadata_inventory_put = disassembler_allow_inv_put,
    allow_metadata_inventory_take = disassembler_allow_inv_take,
    allow_metadata_inventory_move = disassembler_allow_inv_move,
    on_receive_fields = disassembler_receive_fields,
    _mcl_hardness = 3,
    _mcl_blast_resistance = 15,
  }
  local node_name = "logistica:" .. lname
  minetest.register_node(node_name, def)
  logistica.register_non_pushable(node_name)
end
