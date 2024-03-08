local S = logistica.TRANSLATOR

local META_LAVA_IN_TANK = "lavam"
local META_RUNNING_TIME = "cktm"
local META_LAST_ITEM = "lstitm"
local META_LAVA_USED = "ufuel"

local get_meta = minetest.get_meta

local i = logistica.itemstrings

local BUCKET_LAVA = i.lava_bucket
local BUCKET_EMPTY = i.empty_bucket
local LAVA_UNIT = "logistica:lava_unit"

local INV_FUEL = "fuel"
local INV_INPT = "src"
local INV_OUTP = "dst"
local INV_ADDI = "input"

local GUIDE_BTN = "guide"

local UPDATE_INTERVAL = 1.0

local function fill_lava_tank_from_fuel(pos, meta, inv)
  local itemstackName = inv:get_stack(INV_FUEL, 1):get_name()
  if itemstackName ~= BUCKET_LAVA and itemstackName ~= LAVA_UNIT then return end

  local returnStack = ItemStack("")
  if itemstackName == BUCKET_LAVA then
    returnStack = ItemStack(BUCKET_EMPTY)
  end
  local currLevel = meta:get_int(META_LAVA_IN_TANK)
  local cap = logistica.lava_furnace_get_lava_capacity(pos)
  if cap - currLevel < 1000 then return end
  currLevel = currLevel + 1000
  meta:set_int(META_LAVA_IN_TANK, currLevel)
  inv:set_stack(INV_FUEL, 1, returnStack)
end

-- returns running time in secs
local function load_running_time(meta)
  return meta:get_int(META_RUNNING_TIME) / 1000.0
end

-- newTime is in seconds
local function save_running_time(meta, newTime)
  meta:set_int(META_RUNNING_TIME, math.floor(newTime * 1000))
end

local function is_new_item(meta, currItemStack)
  local currStackName = currItemStack:get_name()
  local lastItem = meta:get_string(META_LAST_ITEM)
  meta:set_string(META_LAST_ITEM, currStackName)
  return currStackName ~= lastItem
end

local function get_running_time(meta, isNewItem)
  if isNewItem then
    save_running_time(meta, 0)
    return  0
  else
    return load_running_time(meta)
  end
end

-- returns nil if recipe for `currItemStack` cannot be fulfilled<br>
-- otherwise returns a table:
-- `{input = ItemStack, output = ItemStack, lava = #, additive = ItemStack, additive_use_chance = #, time = #}`
local function get_valid_config(meta, currItemStack)
  local inv = meta:get_inventory()
  local outputDefs = logistica.get_lava_furnace_recipes_for(currItemStack:get_name())
  if not outputDefs then return nil end
  for _, outputDef in ipairs(outputDefs) do
    local inputStack = ItemStack(currItemStack) ; inputStack:set_count(outputDef.input_count)
    local outputStack = ItemStack(outputDef.output)
    local additiveStack = ItemStack(outputDef.additive or "")
    if inv:contains_item(INV_INPT, inputStack)
      and inv:contains_item(INV_ADDI, additiveStack)
      and inv:room_for_item(INV_OUTP, outputStack) then
      return {
        input = inputStack,
        output = outputStack,
        lava = outputDef.lava,
        additive = additiveStack,
        additive_use_chance = outputDef.additive_use_chance,
        time = outputDef.time
      }
    end
  end
  return nil
end

local function save_lava_used(meta, amount)
  meta:set_int(META_LAVA_USED, amount)
end

local function get_lava_used_so_far(meta, isNewItem)
  if isNewItem then
    save_lava_used(meta, 0)
    return 0
  else
    return meta:get_int(META_LAVA_USED)
  end
end

-- returns nil if there isn't enough lava (and it won't use it)
-- otherwise uses the lava and returns the time left to completion (which may < 0 if we overshot)
local function useLava(meta, totalLavaUse, totalTime, runningTime, elapsed, isNewItem)
  local lavaUsedSoFar = get_lava_used_so_far(meta, isNewItem)
  local currAmount = meta:get_int(META_LAVA_IN_TANK)
  local lavaUse = 0
  local remainigTime = totalTime - runningTime - elapsed
  if remainigTime <= 0 then
    lavaUse = math.max(0, totalLavaUse - lavaUsedSoFar) -- use up all that's left
  else
    lavaUse = logistica.round(totalLavaUse * elapsed / totalTime)
  end
  if currAmount - lavaUse < 0 then
    return nil -- not enough lava in tank
  end
  meta:set_int(META_LAVA_IN_TANK, currAmount - lavaUse)
  save_lava_used(meta, lavaUsedSoFar + lavaUse)
  return remainigTime
end

--------------------------------
-- Formspec
--------------------------------

local function get_lava_img(currLava, lavaPercent)
  local img = ""
  if lavaPercent > 0 then
    img = "image[0.4,1.4;1,3;logistica_lava_furnace_tank_bg.png^[lowpart:"..
      lavaPercent..":logistica_lava_furnace_tank.png]"
  else
    img = "image[0.4,1.4;1,3;logistica_lava_furnace_tank_bg.png]"
  end
  return img.."tooltip[0.4,1.4;1,3;"..S("Remaining: ")..(currLava/1000)..S(" Buckets").."]"
end

local function common_formspec(pos, meta)
  local currLava = meta:get_int(META_LAVA_IN_TANK)
  local lavaCap = logistica.lava_furnace_get_lava_capacity(pos) or 1
  local lavaPercent = logistica.round(currLava / lavaCap * 100)
  return "formspec_version[4]"..
      "size[10.5,11]"..
      logistica.ui.background_lava_furnace..
      "list[current_player;main;0.4,5.9;8,4;0]"..
      "list[context;fuel;0.4,4.5;1,1;0]"..
      "list[context;src;2.2,2.3;1,1;0]"..
      "list[context;dst;7.8,2.3;2,2;0]"..
      "list[context;input;4.3,0.9;2,1;0]"..
      "label[0.5,1.1;Lava]"..
      "label[4.2,0.5;Additives]"..
      "listring[context;dst]"..
      "listring[current_player;main]"..
      "listring[context;src]"..
      "listring[current_player;main]"..
      "listring[context;fuel]"..
      "listring[current_player;main]"..
      "button[9.2,0.4;0.8,0.8;"..GUIDE_BTN..";?]"..
      "tooltip["..GUIDE_BTN..";"..S("Recipes").."]"..
      get_lava_img(currLava, lavaPercent)
end

local function get_inactive_formspec(pos, meta)
  return common_formspec(pos, meta)..
      "image[4,2.3;3,1;logistica_lava_furnace_arrow_bg.png^[transformR270]"
end

local function get_active_formspec(pos, meta, runningTime, totalTime)
  local timePercent = logistica.round(runningTime / totalTime * 100)
  local progressImg = ""
  if timePercent > 0 then
    progressImg = "image[4,2.3;3,1;logistica_lava_furnace_arrow_bg.png^[lowpart:"..timePercent..
      ":logistica_lava_furnace_arrow.png^[transformR270]"
  else
    progressImg = "image[4,2.3;3,1;logistica_lava_furnace_arrow_bg.png^[transformR270]"
  end
  return common_formspec(pos, meta)..progressImg
end

local function reset_furnace(pos, meta)
  save_running_time(meta, 0)
  save_lava_used(meta, 0)
  meta:set_string("formspec", get_inactive_formspec(pos, meta))
  local node = minetest.get_node(pos)
  local inactiveNodeName = string.gsub(node.name, "_active", "")
  logistica.swap_node(pos, inactiveNodeName)
end

local function set_furnace_active(pos, meta, runningTime, totalTime)
  meta:set_string("formspec", get_active_formspec(pos, meta, runningTime, totalTime))
  local node = minetest.get_node(pos)
  if not string.find(node.name, "_active") then
    local activeNodeName = node.name.."_active"
    logistica.swap_node(pos, activeNodeName)
  end
end

--------------------------------
-- Callbacks
--------------------------------

local function lava_furnace_node_timer(pos, elapsed)
  local meta = get_meta(pos)
  local inv = meta:get_inventory()
  fill_lava_tank_from_fuel(pos, meta, inv)

  repeat
    local currItemStack = inv:get_stack(INV_INPT, 1)
    local isNewItem = is_new_item(meta, currItemStack)
    local runningTime = get_running_time(meta, isNewItem)
    local config = get_valid_config(meta, currItemStack)

    if not config then -- invalid input, or not enough additives or space
      reset_furnace(pos, meta)
      return false
    end

    local timeLeft = useLava(meta, config.lava, config.time, runningTime, elapsed, isNewItem)
    if timeLeft == nil then --not enough lava left
      reset_furnace(pos, meta)
      return false
    end
    if timeLeft <= 0 then
      elapsed = -timeLeft -- becase we overshot the target time
    end

    fill_lava_tank_from_fuel(pos, meta, inv)
    if timeLeft <= 0 then
      -- cook is ready
      inv:remove_item(INV_INPT, config.input)
      inv:add_item(INV_OUTP, config.output)
      if config.additive
        and config.additive_use_chance
        and logistica.random_chance(config.additive_use_chance) then
        inv:remove_item(INV_ADDI, config.additive)
      end
      save_lava_used(meta, 0)
      save_running_time(meta, 0)
      set_furnace_active(pos, meta, 0, config.time)
    else -- we're still cooking, used entire elapsed time
      runningTime = runningTime + elapsed
      save_running_time(meta, runningTime)
      elapsed = 0
      set_furnace_active(pos, meta, runningTime, config.time)
    end
  until (elapsed <= 0)
  return true
end

local function lava_furnace_on_construct(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size(INV_INPT, 1)
		inv:set_size(INV_FUEL, 1)
		inv:set_size(INV_OUTP, 4)
		inv:set_size(INV_ADDI, 1)
    meta:set_string("formspec", get_inactive_formspec(pos, meta))
		lava_furnace_node_timer(pos, 0)
end

local function lava_furnace_on_destruct(pos)
  local meta = get_meta(pos)
  local amount = meta:get_int(META_LAVA_IN_TANK)
  amount = math.floor(amount / 1000)
  if amount > 0 then
    for i = 1, amount do
      minetest.item_drop(
        ItemStack("logistica:lava_unit"),
        nil,
        vector.add(pos, vector.new(math.random() - 0.5, 0.2, math.random()  - 0.5))
      )
    end
  end
end

local function lava_furnace_can_dig(pos)
  local inv = get_meta(pos):get_inventory()
  return (inv:is_empty(INV_INPT) and inv:is_empty(INV_FUEL)
          and inv:is_empty(INV_OUTP) and inv:is_empty(INV_ADDI))
end

local function lava_furnace_allow_metadata_inv_put(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if listname == INV_INPT or listname == INV_ADDI then
    return stack:get_count()
  elseif listname == INV_FUEL
    and (stack:get_name() == BUCKET_LAVA or stack:get_name() == LAVA_UNIT) then
    return 1
  else
    return 0
  end
end

local function lava_furnace_allow_metadata_inv_take(pos, listname, index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  return stack:get_count()
end

local function lava_furnace_allow_metadata_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
  if minetest.is_protected(pos, player:get_player_name()) then return 0 end
  if to_list == INV_ADDI or to_list == INV_INPT then
    return count
  elseif to_list == INV_FUEL then
    if get_meta(pos):get_inventory():get_stack(from_list, from_index):get_name() == BUCKET_LAVA then
      return count
    else
      return 0
    end
  else
    return 0
  end
end

local function lava_furnace_on_inv_change(pos)
  logistica.start_node_timer(pos, UPDATE_INTERVAL)
end

local function lava_furnace_receive_fields(pos, formname, fields, sender)
  if fields[GUIDE_BTN] and sender and sender:is_player() then
    logistica.lava_furnace_show_guide(sender:get_player_name())
  end
end

--------------------------------
-- Public API
--------------------------------

--[[
The Lava Furnace does not require nor does it connect to any networks - but it can still be used via injector/
`desc`: item description<br>
`name`: lower case no spaces unique name<br>
`lavaCap`: Lava capacity, in buckets (min 1)<br>
`combinedTiles` - should have 2 entires: combinedTiles.inactive and combinedTiles.active<br>
]]
function logistica.register_lava_furnace(desc, name, lavaCapacity, combinedTiles)
  local lname = name:gsub("%s", "_"):lower()
  local def = {
    description = S(desc),
    tiles = combinedTiles.inactive,
    paramtype2 = "facedir",
    groups = { cracky= 2 },
    is_ground_content = false,
    sounds = logistica.sound_mod.node_sound_stone_defaults(),
    can_dig = lava_furnace_can_dig,
    on_timer = lava_furnace_node_timer,
    on_construct = lava_furnace_on_construct,
    on_destruct = lava_furnace_on_destruct,
    on_metadata_inventory_move = lava_furnace_on_inv_change,
    on_metadata_inventory_put = lava_furnace_on_inv_change,
    on_metadata_inventory_take = lava_furnace_on_inv_change,
    allow_metadata_inventory_put = lava_furnace_allow_metadata_inv_put,
    allow_metadata_inventory_move = lava_furnace_allow_metadata_inv_move,
    allow_metadata_inventory_take = lava_furnace_allow_metadata_inv_take,
    on_receive_fields = lava_furnace_receive_fields,
    logistica = {
      lava_capacity = lavaCapacity,
      lava_furnace = true,
    }
  }

  minetest.register_node("logistica:"..lname, def)

  local defActive = table.copy(def)

  defActive.tiles = combinedTiles.active
  defActive.groups.not_in_creative_inventory = 1
  defActive.light_source = 9

  minetest.register_node("logistica:"..lname.."_active", defActive)

end
