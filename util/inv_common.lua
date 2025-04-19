
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
  }

  `list`: the 3x3 list of ItemStacks
]]
function logistica.get_smart_craft_output_results(list)
  local output, decrInp = minetest.get_craft_result({
    method = "normal",
    width = 3,
    items = list,
  })
  if not output or not output.item or output.item:is_empty() then return {} end

  local rawRequired = logistica.count_items_to_stack(list)
  local remainingDecrInput = {}
  for _, remainingItem in ipairs(decrInp.items) do
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

  return {
    requiredItems = rawRequired,
    output = output.item,
    replacements = output.replacements,
    remainingDecrInput = remainingDecrInput,
  }
end
