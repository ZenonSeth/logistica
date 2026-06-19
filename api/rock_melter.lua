local S = logistica.TRANSLATOR
local FS = logistica.FTRANSLATOR
local get_meta = minetest.get_meta

local META_FUEL_TIME       = "fuel_time"
local META_FUEL_TOTALTIME  = "fuel_totaltime"
local META_SRC_TIME        = "src_time"
local META_LAVA_STORED     = "liquidLevel"  -- matches reservoir meta key so network can read it

local LAVA_CAP         = 16  -- 16 buckets
local LAVA_PER_COBBLE  = 1   -- 1 bucket per cobble

local INV_FUEL   = "fuel"
local INV_SRC    = "src"
local INV_DST    = "dst"
local INV_BUCKET = "bucket"

local LAVA_UNIT = "logistica:lava_unit"

local UPDATE_INTERVAL = 1.0

-- Determined after all mods load so fuel recipes are registered
local PRODUCTION_TIME = 60
minetest.after(0, function()
  local result = minetest.get_craft_result({
    method = "fuel", width = 1,
    items = { ItemStack(logistica.itemstrings.lava_bucket) }
  })
  if result.time > 0 then PRODUCTION_TIME = result.time end
end)

local function is_valid_stone(itemname)
  if minetest.get_item_group(itemname, "stone") == 0 then return false end
  local def = minetest.registered_nodes[itemname]
  if not def then return false end
  local dt = def.drawtype
  return dt == nil or dt == "" or dt == "normal"
end

--------------------------------
-- Formspec
--------------------------------

local function get_tank_img(lava_stored)
  local pct = logistica.round(lava_stored / LAVA_CAP * 100)
  local img
  if pct > 0 then
    img = "image[8.7,1.2;1,3;logistica_lava_furnace_tank_bg.png^[lowpart:"..
      pct..":logistica_lava_furnace_tank.png]"
  else
    img = "image[8.7,1.2;1,3;logistica_lava_furnace_tank_bg.png]"
  end
  return img.."tooltip[8.7,1.2;1,3;"..FS("Stored: ")..lava_stored..FS(" / 16 Buckets").."]"
end

local function common_formspec(meta)
  local lava_stored = meta:get_int(META_LAVA_STORED)
  local fuel_remaining = math.max(0,
    meta:get_float(META_FUEL_TOTALTIME) - meta:get_float(META_FUEL_TIME))
  local display_secs = fuel_remaining > 0 and math.max(1, logistica.round(fuel_remaining)) or 0
  local burn_label = FS("Burn Time: ")..display_secs..FS("s")
  return "formspec_version[4]"..
    "size["..logistica.inv_size(10.5, 11.25).."]"..
    logistica.ui.background_lava_furnace..
    "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]"..
    logistica.player_inv_formspec(0.5, 5.9)..
    "list[context;"..INV_FUEL..";1.6,2.1;1,1;0]"..
    "list[context;"..INV_SRC..";3.4,2.1;1,1;0]"..
    "list[context;"..INV_DST..";7.0,1.2;1,3;0]"..
    "list[context;"..INV_BUCKET..";8.7,4.6;1,1;0]"..
    "label[1.6,1.6;"..FS("Fuel").."]"..
    "label[1.6,1.1;"..burn_label.."]"..
    "label[3.3,1.6;"..FS("Input").."]"..
    "label[6.9,0.7;"..FS("Output").."]"..
    "label[8.6,0.7;"..FS("Lava").."]"..
    "label[0.6,3.9;"..FS("Insert a full-block stone-type item\nand a fuel to melt it into lava.\nLava is provided to the network\nor put a bucket in the slot below lava tank.").."]"..
    "listring[context;"..INV_DST.."]"..
    "listring[current_player;main]"..
    "listring[context;"..INV_SRC.."]"..
    "listring[current_player;main]"..
    "listring[context;"..INV_FUEL.."]"..
    "listring[current_player;main]"..
    "listring[context;"..INV_BUCKET.."]"..
    "listring[current_player;main]"..
    get_tank_img(lava_stored)
end

local function get_inactive_formspec(meta)
  return common_formspec(meta)..
    "image[4.7,2.1;2,1;logistica_lava_furnace_arrow_bg.png^[transformR270]"
end

local function get_active_formspec(meta, src_time)
  local pct = logistica.round(src_time / PRODUCTION_TIME * 100)
  local arrow
  if pct > 0 then
    arrow = "image[4.7,2.1;2,1;logistica_lava_furnace_arrow_bg.png^[lowpart:"..
      pct..":logistica_lava_furnace_arrow.png^[transformR270]"
  else
    arrow = "image[4.7,2.1;2,1;logistica_lava_furnace_arrow_bg.png^[transformR270]"
  end
  return common_formspec(meta)..arrow
end

--------------------------------
-- Helpers
--------------------------------

local function update_infotext(meta)
  local units = meta:get_int(META_LAVA_STORED)
  meta:set_string("infotext", S("Has: ")..units.."/16 "..S("Units of Lava"))
end

local function set_active(pos, meta, src_time)
  update_infotext(meta)
  meta:set_string("formspec", get_active_formspec(meta, src_time))
  local name = minetest.get_node(pos).name:gsub("_active$", "")
  logistica.swap_node(pos, name.."_active")
end

local function set_inactive(pos, meta)
  update_infotext(meta)
  meta:set_string("formspec", get_inactive_formspec(meta))
  local name = minetest.get_node(pos).name:gsub("_active$", "")
  logistica.swap_node(pos, name)
end

local function try_fill_bucket(meta, inv)
  local lava_stored = meta:get_int(META_LAVA_STORED)
  if lava_stored < LAVA_PER_COBBLE then return end
  if inv:get_stack(INV_BUCKET, 1):get_name() ~= logistica.itemstrings.empty_bucket then return end
  inv:set_stack(INV_BUCKET, 1, ItemStack(logistica.itemstrings.lava_bucket))
  meta:set_int(META_LAVA_STORED, lava_stored - LAVA_PER_COBBLE)
  update_infotext(meta)
end

-- Returns burn_time, replacements_list. Consumes one unit of fuel from inv.
-- Returns 0, {} if no valid fuel present.
local function consume_fuel(inv)
  local fuel_stack = inv:get_stack(INV_FUEL, 1)
  if fuel_stack:get_name() == LAVA_UNIT then
    fuel_stack:take_item(1)
    inv:set_stack(INV_FUEL, 1, fuel_stack)
    return PRODUCTION_TIME, {}
  end
  local fuellist = inv:get_list(INV_FUEL)
  local fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
  if fuel.time == 0 then return 0, {} end
  local replacements = fuel.replacements
  local still_fuel = minetest.get_craft_result({
    method = "fuel", width = 1,
    items = { afterfuel.items[1]:to_string() }
  })
  if still_fuel.time == 0 then
    table.insert(replacements, afterfuel.items[1])
    inv:set_stack(INV_FUEL, 1, "")
  else
    inv:set_stack(INV_FUEL, 1, afterfuel.items[1])
  end
  return fuel.time, replacements
end

--------------------------------
-- Timer
--------------------------------

local function rock_melter_node_timer(pos, elapsed)
  local meta = get_meta(pos)
  local inv = meta:get_inventory()

  local fuel_time      = meta:get_float(META_FUEL_TIME)
  local fuel_totaltime = meta:get_float(META_FUEL_TOTALTIME)
  local src_time       = meta:get_float(META_SRC_TIME)

  local update = true
  while elapsed > 0 and update do
    update = false

    local src_name = inv:get_stack(INV_SRC, 1):get_name()
    local has_input = is_valid_stone(src_name)
    local lava_stored = meta:get_int(META_LAVA_STORED)
    local can_produce = has_input and lava_stored < LAVA_CAP

    if fuel_time < fuel_totaltime then
      local el = math.min(elapsed, fuel_totaltime - fuel_time)
      if can_produce then
        el = math.min(el, PRODUCTION_TIME - src_time)
      end

      fuel_time = fuel_time + el
      elapsed   = elapsed - el

      if can_produce then
        src_time = src_time + el
        if src_time >= PRODUCTION_TIME then
          inv:remove_item(INV_SRC, ItemStack(src_name))
          lava_stored = math.min(LAVA_CAP, lava_stored + LAVA_PER_COBBLE)
          meta:set_int(META_LAVA_STORED, lava_stored)
          src_time = src_time - PRODUCTION_TIME
          update = true
        end
      end

      -- fuel ran out mid-elapsed; loop again to try consuming new fuel if possible
      if fuel_time >= fuel_totaltime and can_produce then
        update = true
      end
    else
      -- only consume new fuel if there is something to process
      if not can_produce then break end

      local burn_time, replacements = consume_fuel(inv)

      if burn_time == 0 then
        fuel_time = 0
        fuel_totaltime = 0
        src_time = 0
      else
        for _, repl in ipairs(replacements) do
          if not repl:is_empty() then
            local leftover = inv:add_item(INV_DST, repl)
            if not leftover:is_empty() then
              local above = vector.new(pos.x, pos.y + 1, pos.z)
              local drop_pos = minetest.find_node_near(above, 1, {"air"}) or above
              minetest.item_drop(leftover, nil, drop_pos)
            end
          end
        end
        fuel_totaltime = burn_time + (fuel_totaltime - fuel_time)
        fuel_time = 0
        update = true
      end
    end
  end

  try_fill_bucket(meta, inv)

  meta:set_float(META_FUEL_TIME, fuel_time)
  meta:set_float(META_FUEL_TOTALTIME, fuel_totaltime)
  meta:set_float(META_SRC_TIME, src_time)

  if fuel_time < fuel_totaltime then
    set_active(pos, meta, src_time)
    return true
  else
    set_inactive(pos, meta)
    -- keep polling if fuel+input are waiting (e.g. tank was full, may free up)
    return not inv:is_empty(INV_FUEL) and not inv:is_empty(INV_SRC)
  end
end

--------------------------------
-- Callbacks
--------------------------------

local function on_construct(pos)
  local meta = get_meta(pos)
  local inv = meta:get_inventory()
  inv:set_size(INV_SRC, 1)
  inv:set_size(INV_FUEL, 1)
  inv:set_size(INV_DST, 3)
  inv:set_size(INV_BUCKET, 1)
  meta:set_string("formspec", get_inactive_formspec(meta))
end

local function can_dig(pos)
  local meta = get_meta(pos)
  local inv = meta:get_inventory()
  return inv:is_empty(INV_SRC) and inv:is_empty(INV_FUEL)
    and inv:is_empty(INV_DST) and inv:is_empty(INV_BUCKET)
end

local function on_destruct(pos)
  local buckets = get_meta(pos):get_int(META_LAVA_STORED)
  for i = 1, buckets do
    minetest.item_drop(
      ItemStack("logistica:lava_unit"), nil,
      vector.add(pos, vector.new(math.random() - 0.5, 0.2, math.random() - 0.5))
    )
  end
end

local function allow_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_SRC then
    return is_valid_stone(stack:get_name()) and stack:get_count() or 0
  elseif listname == INV_FUEL then
    if stack:get_name() == LAVA_UNIT then return stack:get_count() end
    return minetest.get_craft_result({method = "fuel", width = 1, items = {stack}}).time ~= 0
      and stack:get_count() or 0
  elseif listname == INV_BUCKET then
    return stack:get_name() == logistica.itemstrings.empty_bucket and 1 or 0
  end
  return 0
end

local function allow_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function allow_move(pos, from_list, from_index, to_list, to_index, count, player)
  local stack = get_meta(pos):get_inventory():get_stack(from_list, from_index)
  return allow_put(pos, to_list, to_index, stack, player)
end

local function on_inv_change(pos)
  minetest.get_node_timer(pos):start(UPDATE_INTERVAL)
end

local function on_inv_take(pos, listname, index, stack, player)
  if listname == INV_SRC then
    local remaining = get_meta(pos):get_inventory():get_stack(INV_SRC, 1)
    if remaining:is_empty() then
      get_meta(pos):set_float(META_SRC_TIME, 0)
    end
  end
  minetest.get_node_timer(pos):start(UPDATE_INTERVAL)
end

--------------------------------
-- Public API
--------------------------------

--[[
`desc`: item description
`name`: lower case no spaces unique name
`tiles`: table with `tiles.inactive` and `tiles.active` tile arrays
]]
function logistica.register_rock_melter(desc, name, tiles)
  local lname = "logistica:"..name:gsub("%s", "_"):lower()

  local def = {
    description = desc,
    tiles = tiles.inactive,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    node_box = {
      type = "fixed",
      fixed = {
        -- main body, inset 1/16 from each face
        {-7/16, -7/16, -7/16,  7/16,  7/16,  7/16},
        -- 4 edges parallel to X (top/bottom × front/back)
        {-8/16,  7/16, -8/16,  8/16,  8/16, -7/16},
        {-8/16,  7/16,  7/16,  8/16,  8/16,  8/16},
        {-8/16, -8/16, -8/16,  8/16, -7/16, -7/16},
        {-8/16, -8/16,  7/16,  8/16, -7/16,  8/16},
        -- 4 edges parallel to Y (left/right × front/back)
        {-8/16, -8/16, -8/16, -7/16,  8/16, -7/16},
        { 7/16, -8/16, -8/16,  8/16,  8/16, -7/16},
        {-8/16, -8/16,  7/16, -7/16,  8/16,  8/16},
        { 7/16, -8/16,  7/16,  8/16,  8/16,  8/16},
        -- 4 edges parallel to Z (top/bottom × left/right)
        {-8/16,  7/16, -8/16, -7/16,  8/16,  8/16},
        { 7/16,  7/16, -8/16,  8/16,  8/16,  8/16},
        {-8/16, -8/16, -8/16, -7/16, -7/16,  8/16},
        { 7/16, -8/16, -8/16,  8/16, -7/16,  8/16},
      },
    },
    selection_box = { type = "regular" },
    collision_box = { type = "regular" },
    groups = { cracky = 2, [logistica.TIER_ALL] = 1 },
    sounds = logistica.sound_mod.node_sound_stone_defaults(),
    stack_max = logistica.stack_max,
    _mcl_hardness = 3,
    _mcl_blast_resistance = 15,
    can_dig = can_dig,
    on_construct = on_construct,
    on_destruct = on_destruct,
    on_timer = rock_melter_node_timer,
    allow_metadata_inventory_put = allow_put,
    allow_metadata_inventory_take = allow_take,
    allow_metadata_inventory_move = allow_move,
    on_metadata_inventory_put = on_inv_change,
    on_metadata_inventory_take = on_inv_take,
    on_metadata_inventory_move = on_inv_change,
    after_place_node = function(pos) logistica.on_reservoir_change(pos) end,
    after_dig_node = logistica.on_reservoir_change,
    logistica = { liquidName = logistica.liquids.lava, maxBuckets = LAVA_CAP, automatable = true, liquid_source_only = true },
  }

  minetest.register_node(lname, def)
  logistica.GROUPS.reservoirs.register(lname)

  local def_active = table.copy(def)
  def_active.tiles = tiles.active
  def_active.on_construct = nil
  def_active.after_place_node = nil
  def_active.light_source = 9
  def_active.drop = lname
  def_active.groups = { cracky = 2, not_in_creative_inventory = 1, [logistica.TIER_ALL] = 1 }

  minetest.register_node(lname.."_active", def_active)
  logistica.GROUPS.reservoirs.register(lname.."_active")
end
