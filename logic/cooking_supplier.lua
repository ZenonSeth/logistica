local S = logistica.TRANSLATOR

local INV_MAIN   = "main"
local INV_CONFIG = "config"
local INV_HOUT   = "hout"

local META_ERROR = "cook_err"

local MIN_COOK_TIME       = 0.1 -- seconds
local QC_COST_PER_SEC     = 10  -- 1 Quantum Cycle per 0.1s of cook time

local function ret(remaining, optError)
  return { remaining = remaining, error = optError and S(optError) or nil }
end

-- returns {input_count = 1, output = "item_name N", time = #}/nil for the given input item name<br>
-- only plain cooking recipes are supported here (no additives/byproducts) - those still need a Lava Furnace
local function get_valid_recipe(configItemName)
  local output, decrOut = minetest.get_craft_result({
    method = "cooking", width = 1, items = { ItemStack(configItemName) }
  })
  if output.time <= 0 or not decrOut.items[1]:is_empty() then return nil end
  return {
    input_count = 1,
    output = output.item:to_string(),
    time = math.max(MIN_COOK_TIME, output.time),
  }
end

local function get_cook_qc_cost(recipe)
  return math.ceil(recipe.time * QC_COST_PER_SEC)
end

-- a recipe is only cookable here if its full cost can ever fit in the network's Quantum Cycle bank
local function is_recipe_cookable(recipe)
  return recipe ~= nil and get_cook_qc_cost(recipe) <= logistica.network_get_quantum_cycles_max()
end

-- returns table { newList = listWithoutStack, takenStack = stackOfHowManyRemoved }
local function list_without_stack(invList, takeStack)
  local newList = {}
  local countedItems = logistica.count_items_to_stack(invList)
  local takenStack = ItemStack(takeStack) ; takenStack:set_count(1)
  for _, v in pairs(countedItems) do
    if takeStack:get_count() > 0 and v:get_name() == takeStack:get_name() then
      local countLeftoverAfterRemoved = math.max(0, v:get_count() - takeStack:get_count())
      local modifiedV = ItemStack(v) ; modifiedV:set_count(countLeftoverAfterRemoved)
      takenStack:set_count(takenStack:get_count() + v:get_count() - countLeftoverAfterRemoved)
      if countLeftoverAfterRemoved > 0 then
        table.insert(newList, modifiedV)
      end
    elseif v:get_count() > 0 then
      table.insert(newList, v)
    end
  end
  takenStack:set_count(takenStack:get_count() - 1)
  return { newList = newList, takenStack = takenStack }
end

local function consume_from_network(craftItems, times, network, depth)
  if times <= 0 then return end
  local acceptItem = function (_) return 0 end
  for _, itemStack in ipairs(craftItems) do
    local consumeStack = ItemStack(itemStack) ; consumeStack:set_count(itemStack:get_count() * times)
    logistica.take_stack_from_network(consumeStack, network, acceptItem, true, false, false, depth + 1)
  end
end

-- returns table {countCanCraft = # (0 or 1), newExtrasList = extrasMadeByCrafting - removed items}
local function consume_for_cook(craftItems, craftItemsMult, extrasMadeByCooking, network, depth, dryRun)
  local itemTaken = ItemStack("")
  local acceptItem = function(st) itemTaken:add_item(st) ; return 0 end
  local extrasCopy = table.copy(extrasMadeByCooking)
  local toConsumeFromNetwork = {}
  for _, _itemStack in ipairs(craftItems) do
    itemTaken:clear()
    local itemStack = ItemStack(_itemStack)
    if dryRun then
      -- when doing a dryRun the actual items are not removed from the network, so we need to make sure
      -- we have enough in the network by accounting for how many have been "cooked" so far
      itemStack:set_count(itemStack:get_count() * craftItemsMult)
    end

    -- first check if we can take it from the extrasCopy
    local takenFromExtras = 0
    for _, v in ipairs(extrasCopy) do
      if v:get_name() == itemStack:get_name() then
        takenFromExtras = math.min(v:get_count(), itemStack:get_count())
        itemStack:set_count(itemStack:get_count() - takenFromExtras)
        if not dryRun then -- if not dry run, actually use up items in the extras copy list
          v:set_count(math.max(0, v:get_count() - takenFromExtras))
        end
      end
    end

    -- then if any still needed, take from network
    if itemStack:get_count() > 0 then
      logistica.take_stack_from_network(itemStack, network, acceptItem, true, false, true, depth + 1)
      if not dryRun and itemTaken:get_count() > 0 then
        table.insert(toConsumeFromNetwork, ItemStack(itemTaken))
      end
    end

    -- if there aren't enough combined items, we just can't cook this
    if (takenFromExtras + itemTaken:get_count()) < itemStack:get_count() then
      return { countCanCraft = 0, newExtrasList = extrasMadeByCooking }
    end
  end
  -- if we got here, it means we CAN cook this. remove the items as needed
  if not dryRun then
    consume_from_network(toConsumeFromNetwork, 1, network, depth)
  end
  return { countCanCraft = 1, newExtrasList = extrasCopy }
end

local function update_cook_output(pos, meta, inv)
  local configStack = inv:get_stack(INV_CONFIG, 1)
  local recipe = (not configStack:is_empty()) and get_valid_recipe(configStack:get_name()) or nil
  local item = ItemStack("")
  local errorText = ""
  if recipe and is_recipe_cookable(recipe) then
    item = ItemStack(recipe.output)
  elseif recipe then
    errorText = configStack:get_short_description().." "..S("requires too many Quantum Cycles to instantly cook!")
  end
  inv:set_stack(INV_MAIN, 1, item)
  meta:set_string(META_ERROR, errorText)
  logistica.append_makes_infotext(pos, item)
end

-- public functions

-- returns a list of ItemStacks to be used for caching, which may be a sublist of INV_MAIN if the machine is off
function logistica.cooking_supplier_get_main_list(pos)
  local isOn = logistica.is_machine_on(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  local mainList = logistica.get_list(inv, INV_MAIN)
  if isOn then return mainList
  else
    local sublist = {}
    for i, stack in ipairs(mainList) do
      if i ~= 1 then
        table.insert(sublist, stack)
      end
    end
    return sublist
  end
end

function logistica.cooking_supplier_get_error(pos)
  return minetest.get_meta(pos):get_string(META_ERROR)
end

-- returns table {remaining = # How many items remain to fulfil, 0 if successful, errorMsg = "error description here"/nil}
function logistica.take_item_from_cooking_supplier(pos, _takeStack, network, collectorFunc, useMetadata, dryRun, _depth)
  local depth = _depth or 0
  local takeStack = ItemStack(_takeStack)
  local remaining = takeStack:get_count()
  local takeStackName = takeStack:get_name()
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()

  -- make sure we update the output item
  logistica.cooking_supplier_update_output(pos)

  -- first try to take from supply, ignore the 1st slot (which is for the cooked item)
  local supplierResult = logistica.take_item_from_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun, 1)
  remaining = supplierResult.remaining
  if remaining <= 0 then return ret(0) end -- everything was taken from existing supply, we're done

  -- only cook if machine is on
  if not logistica.is_machine_on(pos) then return ret(remaining) end

  -- if we still have a number of requested items to fulfil, try cooking them
  takeStack:set_count(remaining)
  local outputStack = inv:get_stack(INV_MAIN, 1)
  local configStack = inv:get_stack(INV_CONFIG, 1)

  -- if names are different, or nothing configured, we can't cook this request
  if configStack:is_empty() or outputStack:get_name() ~= takeStack:get_name() then
    return ret(remaining)
  end

  local recipe = get_valid_recipe(configStack:get_name())
  if not is_recipe_cookable(recipe) then return ret(remaining) end

  local qcCost = get_cook_qc_cost(recipe)

  inv:set_list(INV_HOUT, {})
  local numCooked = 0
  local isEnough = false

  local cookOutputCount = outputStack:get_count()
  local craftItemMult = 0
  local trackedQc = logistica.network_get_quantum_cycles(network)
  repeat
    craftItemMult = craftItemMult + 1

    -- use the output of any previous loop iterations to make it available to take from - except for the item we have to send to requester
    local extrasListsMinusTarget = list_without_stack(logistica.get_list(inv, INV_HOUT), takeStack)
    local extrasMadeByCooking = extrasListsMinusTarget.newList -- extra items output by the previous cook loops (aka substitutes)

    local numCanCook = 0
    if trackedQc >= qcCost then
      local inputStack = ItemStack(configStack:get_name()) ; inputStack:set_count(recipe.input_count)
      -- consume items required to cook the item from the extras and network if needed
      local consumeResult = consume_for_cook({ inputStack }, craftItemMult, extrasMadeByCooking, network, depth, dryRun)
      numCanCook = consumeResult.countCanCraft -- how many we can cook, really the function returns 0 or 1
      -- if not a dry run, we might have taken some items from the extras, so override the HOUT list with our used-up list
      if not dryRun then
        if extrasListsMinusTarget.takenStack:get_count() > 0 then
          table.insert(consumeResult.newExtrasList, extrasListsMinusTarget.takenStack)
        end
        inv:set_list(INV_HOUT, consumeResult.newExtrasList)
      end
    end

    numCooked = numCooked + numCanCook
    if numCanCook > 0 then -- now "cook" the item
      trackedQc = trackedQc - qcCost
      logistica.network_take_quantum_cycles(network, qcCost, dryRun)
      inv:add_item(INV_HOUT, ItemStack(recipe.output))
    end

    if dryRun then
      isEnough = (numCooked * cookOutputCount >= remaining) or numCanCook == 0 or numCooked >= 99
    else
      isEnough = inv:contains_item(INV_HOUT, takeStack) or numCanCook == 0 or numCooked >= 99
    end
  until (isEnough)

  if numCooked == 0 then return ret(remaining, "Not enough Quantum Cycles/mats to cook item in Cooking Supplier") end -- nothing could be cooked

  -- give the item to the collector (dry run conjures items into HOUT without consuming network, for the AP allow_take flow)
  local taken = inv:remove_item(INV_HOUT, takeStack)
  local leftover = collectorFunc(taken)
  remaining = math.max(0, remaining - (taken:get_count() - leftover))

  -- now move any extras from the hidden to the main inventory - deleting extras (TODO: maybe drop them)
  if not dryRun then
    local extraNotTaken = 0
    local toInsert = {}
    for _, st in ipairs(logistica.get_list(inv, INV_HOUT)) do
      if st:get_name() == takeStackName then
        extraNotTaken = extraNotTaken + st:get_count()
      else
        table.insert(toInsert, st)
      end
    end
    taken:set_count(leftover + extraNotTaken)

    if not taken:is_empty() then
      local main = logistica.get_list(inv, INV_MAIN) or {}
      for i = 2, #main do
        taken = main[i]:add_item(taken)
      end
      inv:set_list(INV_MAIN, main)
    end

    for _, insertStack in ipairs(toInsert) do
      inv:add_item(INV_MAIN, insertStack)
    end
    logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER, network)
  end

  return ret(remaining)
end

function logistica.cooking_supplier_update_output(pos)
  local meta = minetest.get_meta(pos)
  update_cook_output(pos, meta, meta:get_inventory())
  logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER)
end
