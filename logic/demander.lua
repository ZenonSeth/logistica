
-- Returns a list of ItemStacks from the demandList that are missing in the storageList
function logistica.get_demand_based_on_list(demandList, storageList)
  local missing = {}
  local storageSize = #storageList
  for _, demanded in ipairs(demandList) do
    local remaining = demanded:get_count()
    local i = 1
    local checkNext = true
    while checkNext and i <= storageSize do
      local stored = storageList[i]
      if demanded:get_name() == stored:get_name() then
        remaining = remaining - stored:get_count()
      end
      if remaining <= 0 then checkNext = false end
    end
    if remaining > 0 then
      local missingStack = ItemStack(demanded)
      missingStack:set_count(remaining)
      table.insert(missing, missingStack)
    end
  end
  return missing
end
