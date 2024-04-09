local S = logistica.TRANSLATOR

local INV_MAIN = "main"
local INV_CRAFT = "crf"
local INV_HOUT = "hout"

local function ret(remaining, optError)
  return { remaining = remaining, error = optError and S(optError) or nil }
end

local function count_items_to_stack(list)
	local map = {}
	for _, stack in ipairs(list) do
		if not stack:is_empty() then
			local stName = stack:get_name()
      if not map[stName] then map[stName] = 0 end
			map[stName] = map[stName] + stack:get_count()
		end
	end
  local items = {}
  local i = 0
	for name, count in pairs(map) do
    i = i + 1
    local item = ItemStack(name) ; item:set_count(count)
    items[i] = item
  end
  return items
end

-- returns table { newList = listWithoutStack, takenStack = stackOfHowManyRemoved }
local function list_without_stack(invList, takeStack)
  local newList = {}
  local countedItems = count_items_to_stack(invList)
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
local function consume_for_craft(craftItems, craftItemsMult, extrasMadeByCrafting, network, depth, dryRun)
  local itemTaken = ItemStack("")
  local acceptItem = function(st) itemTaken:add_item(st) ; return 0 end
  local extrasCopy = table.copy(extrasMadeByCrafting)
  local toConsumeFromNetwork = {}
  for _, _itemStack in ipairs(craftItems) do
    itemTaken:clear()
    local itemStack = ItemStack(_itemStack)
    if dryRun then
      -- when doing a dryRun the actual items are not removed from the network, so we need to make sure
      -- we have enough in the network by accounting for how many have been "crafted" so far
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

    -- if there aren't enough combined items, we just can't craft this
    if (takenFromExtras + itemTaken:get_count()) < itemStack:get_count() then
      return { countCanCraft = 0, newExtrasList = extrasMadeByCrafting }
    end
  end
  -- if we got here, it means we CAN craft this. remove the items as needed
  if not dryRun then
    consume_from_network(toConsumeFromNetwork, 1, network, depth)
  end
  return { countCanCraft = 1, newExtrasList = extrasCopy }
end

-- returns a list of ItemStacks to be used for caching, which may be a sublist of INV_MAIN if the machine is off
function logistica.crafting_supplier_get_main_list(pos)
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

-- returns table {remaining = # How many items remain to fulfil, 0 if successful, errorMsg = "error description here"/nil}
function logistica.take_item_from_crafting_supplier(pos, _takeStack, network, collectorFunc, useMetadata, dryRun, _depth)
  local depth = _depth or 0
  local takeStack = ItemStack(_takeStack)
  local remaining = takeStack:get_count()
  local takeStackName = takeStack:get_name()
  local inv = minetest.get_meta(pos):get_inventory()

  -- first try to take from supply, ignore the 1st slot (which is for the crafted item)
  local supplierResult = logistica.take_item_from_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun, 1)
  remaining = supplierResult.remaining
  if remaining <= 0 then return ret(0) end -- everything was taken from existing supply, we're done

  -- only craft if machine is on
  if not logistica.is_machine_on(pos) then return ret(_takeStack:get_count()) end

  -- if we still have a number of requested itsm to fulfil, try crafting them
  takeStack:set_count(remaining)
  local craftStack = inv:get_stack(INV_MAIN, 1)

  -- if names are different, we can't craft this request
  if inv:is_empty(INV_CRAFT) or  craftStack:get_name() ~= takeStack:get_name() then
    return ret(remaining)
  end

  inv:set_list(INV_HOUT, {})
  local numCrafted = 0
  local isEnough = false

  local craftItemMult = 0
  repeat
    craftItemMult = craftItemMult + 1
    --
    local recipeItems = count_items_to_stack(logistica.get_list(inv, INV_CRAFT))
    -- use the output of any previous loop iterations to make it available to take from - except for the item we have to send to requester
    local extrasListsMinusTarget = list_without_stack(logistica.get_list(inv, INV_HOUT), takeStack)
    local extrasMadeByCrafting = extrasListsMinusTarget.newList -- extra items output by the previous craft loops (aka substitutes)

    -- consume items required to craft the item from the extras and network if needed
    local consumeResult = consume_for_craft(recipeItems, craftItemMult, extrasMadeByCrafting, network, depth, dryRun)
    local numCanCraft = consumeResult.countCanCraft -- how many we can craft, really the function returns 0 or 1
    -- if not a dry run, we might have taken some items from the extras, so override the HOUT list with our used-up list
    if not dryRun then
      if extrasListsMinusTarget.takenStack:get_count() > 0 then
        table.insert(consumeResult.newExtrasList, extrasListsMinusTarget.takenStack)
      end
      inv:set_list(INV_HOUT, consumeResult.newExtrasList)
    end
    numCrafted = numCrafted + numCanCraft
    if numCanCraft > 0 then -- now "craft" the item
      logistica.autocrafting_produce_single_item(inv, INV_CRAFT, nil, INV_HOUT)
    end

    isEnough = inv:contains_item(INV_HOUT, takeStack) or numCanCraft == 0 or numCrafted >= 99
  until (isEnough)

  if numCrafted == 0 then return ret(remaining, "Not enough materials available to craft items from crafting supplier") end -- nothing could be crafted
  remaining = math.max(0, remaining - numCrafted)

  -- give the item to the collector
  local taken = inv:remove_item(INV_HOUT, takeStack)
  local leftover = collectorFunc(taken)

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
