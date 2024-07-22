-- returns a name-indexed count of items in the given list
-- adds to the existingMap if provided
local function count_items(list, existingMap)
	local map = existingMap or {}
	for _, stack in ipairs(list) do
		if not stack:is_empty() then
			local stName = stack:get_name()
      if not map[stName] then map[stName] = 0 end
			map[stName] = map[stName] + stack:get_count()
		end
	end
	return map
end

-- returns a name indexed map to count of items in the given list
local function count_only_required_items(list)
  local asList = logistica.get_smart_craft_output_results(list).requiredItems
  if not asList then return {} end
  local map = {}
  for _, stack in ipairs(asList) do
    map[stack:get_name()] = stack:get_count()
  end
  return map
end

-- returns {item = ItemStack, extras = {ItemStack, ItemStack...}}
-- item is an empty Itemstack if not successful
local function get_combined_crafting_ouputs(stacklist3x3)
  local smartResult = logistica.get_smart_craft_output_results(stacklist3x3)
  if not smartResult.output then return {item = ItemStack(), extras = {}} end
  local item = smartResult.output
  local extraMap = {}
  count_items(smartResult.replacements or {}, extraMap)
  count_items(smartResult.remainingDecrInput or {}, extraMap)
  local extras = {}
  local index = 0
  for stName, count in pairs(extraMap) do
    local stack = ItemStack(stName) ; stack:set_count(count)
    index = index + 1
    extras[index] = stack
  end
  return {item = item, extras = extras}
end

-- public functions

-- returns true if something was crafted, false if nothing was crafted
-- optSourceListName is optional: if nil, no checks will be made if enough materials exist
function logistica.autocrafting_produce_single_item(inv, recipeList3x3Name, optSourceListName, outputListName)
  local recipeList = logistica.get_list(inv, recipeList3x3Name)

  local craftRes = get_combined_crafting_ouputs(recipeList, true)
  if craftRes.item:is_empty() then return false end

  -- check if there's room for all the outputs
  if not inv:room_for_item(outputListName, craftRes.item) then return false end
  for _, st in ipairs(craftRes.extras) do
    if not inv:room_for_item(outputListName, st) then return false end
  end

  if optSourceListName ~= nil then
    -- check if source has enough materials
    local recCounts = count_only_required_items(recipeList)
    local srcCounts = count_items(logistica.get_list(inv, optSourceListName))
    for name, count in pairs(recCounts) do
      if srcCounts[name] == nil or srcCounts[name] < count then return false end
    end

    -- remove items from source
    for name, _count in pairs(recCounts) do
      local count = _count
      repeat
        local stack = ItemStack(name)
        local take = math.min(count, stack:get_stack_max())
        stack:set_count(take)
        count = count - take
        inv:remove_item(optSourceListName, stack)
      until (count == 0)
    end
  end

  -- add the output
  inv:add_item(outputListName, craftRes.item)
  for _, st in ipairs(craftRes.extras) do
    inv:add_item(outputListName, st)
  end

  return true
end
