
-- returns a naturally numbered list of ItemStacks
function logistica.count_items_to_stack(list)
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

--[[
  returns a table (or empty table if not a valid recipe):
  {
    requiredItems = {ItemStack, ItemStack}, -- unique list of itemstacks needed for this craft
    output = ItemStack, -- the result of get_craft_result().output.item
    replacements = {ItemStack, ItemStack}, -- the result of get_craft_result().output.replacements
    remainingDecrInput = {ItemStack, ItemStack} -- the result of get_craft_result().decrementedInput, but only as if minimumItems was the input
    presenceOnlyItems = {ItemStack, ItemStack} -- only populated if isAutocrafter: items whose slot
      came back unchanged; must be present but are never consumed
  }

  `list`: the 3x3 list of ItemStacks
  `isAutocrafter`: optional, see presenceOnlyItems above
]]
function logistica.get_smart_craft_output_results(list, isAutocrafter)
  local output, decrInp = minetest.get_craft_result({
    method = "normal",
    width = 3,
    items = list,
  })
  if not output or not output.item or output.item:is_empty() then return {} end

  -- a same-item craft replacement comes back from the engine byte-identical to what was
  -- placed, indistinguishable from being untouched, so for the Autocrafter we just require
  -- such slots present in source without ever moving them
  local presenceOnlyMap = {}
  local skipSlot = {}
  if isAutocrafter then
    for i, origItem in ipairs(list) do
      local remainingItem = decrInp.items[i]
      if not origItem:is_empty() and remainingItem
          and remainingItem:get_name() == origItem:get_name()
          and remainingItem:get_count() == origItem:get_count() then
        presenceOnlyMap[origItem:get_name()] = (presenceOnlyMap[origItem:get_name()] or 0) + origItem:get_count()
        skipSlot[i] = true
      end
    end
  end

  local rawRequired = {}
  for _, item in ipairs(logistica.count_items_to_stack(list)) do
    if not presenceOnlyMap[item:get_name()] then
      table.insert(rawRequired, item)
    end
  end

  local remainingDecrInput = {}
  for i, remainingItem in ipairs(decrInp.items) do
    if not skipSlot[i] then
      local isExtra = true
      for _, rawItem in ipairs(rawRequired) do
        if rawItem:get_name() == remainingItem:get_name() then
          local requiredCount = rawItem:get_count() - remainingItem:get_count()
          rawItem:set_count(math.max(0, requiredCount))
          isExtra = false
        end
      end
      if isExtra then
        table.insert(remainingDecrInput, remainingItem)
      end
    end
  end

  local presenceOnlyItems = {}
  for name, count in pairs(presenceOnlyMap) do
    local item = ItemStack(name) ; item:set_count(count)
    table.insert(presenceOnlyItems, item)
  end

  return {
    requiredItems = rawRequired,
    output = output.item,
    replacements = output.replacements,
    remainingDecrInput = remainingDecrInput,
    presenceOnlyItems = presenceOnlyItems,
  }
end
