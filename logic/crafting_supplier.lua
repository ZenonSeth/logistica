local INV_MAIN = "main"
local INV_CRAFT = "crf"
local INV_HOUT = "hout"

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

local function consume_from_network(craftItems, times, network)
  if times <= 0 then return end
  local acceptItem = function (_) return 0 end
  for _, itemStack in ipairs(craftItems) do
    local consumeStack = ItemStack(itemStack) ; consumeStack:set_count(itemStack:get_count() * times)
    logistica.take_stack_from_network(consumeStack, network, acceptItem, true, false, false)
  end
end

-- returns 0 if craftItems could not be taken from network, returns 1 if they could
local function consume_for_craft(craftItems, network)
  local itemTaken = ItemStack("")
  local acceptItem = function(st) itemTaken:add_item(st) ; return 0 end
  for _, itemStack in ipairs(craftItems) do
    itemTaken:clear()
    logistica.take_stack_from_network(itemStack, network, acceptItem, true, false, true)
    if itemTaken:get_count() < itemStack:get_count() then
      return 0
    end
  end
  consume_from_network(craftItems, 1, network)
  return 1
end

function logistica.take_item_from_crafting_supplier(pos, _takeStack, network, collectorFunc, useMetadata, dryRun)
  local takeStack = ItemStack(_takeStack)
  local remaining = takeStack:get_count()
  local takeStackName = takeStack:get_name()

  -- first check existing supply, ignore the 1st slot (which is for the crafted item)
  remaining = logistica.take_item_from_supplier(pos, takeStack, network, collectorFunc, useMetadata, dryRun, 1)
  if remaining <= 0 then return 0 end -- we're done

  -- only craft if machine is on
  if not logistica.is_machine_on(pos) then return _takeStack:get_count() end

  -- if we still have a number of requested itsm to fulfil, try crafting them
  takeStack:set_count(remaining)
  local inv = minetest.get_meta(pos):get_inventory()
  local craftStack = inv:get_stack(INV_MAIN, 1)

  -- if names are different, we can't craft this request
  if inv:is_empty(INV_CRAFT) or  craftStack:get_name() ~= takeStack:get_name() then
    return remaining
  end

  inv:set_list(INV_HOUT, {})
  local numCrafted = 0
  local isEnough = false
  repeat
    logistica.autocrafting_produce_single_item(inv, INV_CRAFT, nil, INV_HOUT)
    -- if we can craft from network
    local items = count_items_to_stack(inv:get_list(INV_CRAFT))
    local numCanCraft = consume_for_craft(items, network)
    numCrafted = numCrafted + numCanCraft

    isEnough = inv:contains_item(INV_HOUT, takeStack) or numCanCraft == 0 or numCrafted >= 99
  until (isEnough)

  if numCrafted == 0 then return remaining end -- nothing could be crafted
  remaining = math.max(0, remaining - numCrafted)

  -- give the item to the collector
  local taken = inv:remove_item(INV_HOUT, takeStack)
  local leftover = collectorFunc(taken)

  -- now move any extras from the hidden to the main inventory - deleting extras (TODO: maybe drop them)
  local extraNotTaken = 0
  local toInsert = {}
  for i, st in ipairs(inv:get_list(INV_HOUT)) do
    if st:get_name() == takeStackName then
      extraNotTaken = extraNotTaken + st:get_count()
    else
      table.insert(toInsert, st)
    end
  end
  taken:set_count(leftover + extraNotTaken)

  if not taken:is_empty() then
    local main = inv:get_list(INV_MAIN) or {}
    for i = 2, #main do
      taken = main[i]:add_item(taken)
    end
    inv:set_list(INV_MAIN, main)
  end

  for _, insertStack in ipairs(toInsert) do
    inv:add_item(INV_MAIN, insertStack)
  end

  return remaining
end
