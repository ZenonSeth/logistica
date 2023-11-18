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

-- returns {item = ItemStack, extras = {ItemStack, ItemStack...}}
-- item is an empty Itemstack if not successful
local function get_combined_crafting_ouputs(stacklist3x3)
  local res, decr = minetest.get_craft_result({
    method = "normal",
    width = 3,
    items = stacklist3x3
  })
  local item = res.item
  local extraMap = {}
  count_items(res.replacements or {}, extraMap)
  count_items(decr.items or {}, extraMap)
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
function logistica.autocrafting_produce_single_item(inv, recipeList3x3Name, sourceListName, outputListName)
  local recipeList = inv:get_list(recipeList3x3Name) or {}

  local craftRes = get_combined_crafting_ouputs(recipeList)
  if craftRes.item:is_empty() then return false end

  -- check if there's room for all the outputs
  if not inv:room_for_item(outputListName, craftRes.item) then return false end
  for _, st in ipairs(craftRes.extras) do
    if not inv:room_for_item(outputListName, st) then return false end
  end
  -- check if source has enough materials
  local recCounts = count_items(recipeList)
  local srcCounts = count_items(inv:get_list(sourceListName) or {})
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
      inv:remove_item(sourceListName, stack)
    until (count == 0)
  end

  -- add the output
  inv:add_item(outputListName, craftRes.item)
  for _, st in ipairs(craftRes.extras) do
    inv:add_item(outputListName, st)
  end

  return true
end
