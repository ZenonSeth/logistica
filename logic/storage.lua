
function logistica.get_mass_storage_max_size(pos)
  local node = minetest.get_node(pos)
  if not node then return 0 end
  local def = minetest.registered_nodes[node.name]
  if def and def.logistica and def.logistica.maxItems then
    -- TODO: account for upgrades
    return def.logistica.maxItems
  end
  return 0
end

function logistica.get_mass_storage_num_slots(pos)
  local node = minetest.get_node(pos)
  if not node then return 0 end
  local def = minetest.registered_nodes[node.name]
  if def and def.logistica and def.logistica.numSlots then
    -- TODO: account for upgrades
    return def.logistica.numSlots
  end
  return 0
end

-- try to insert the item into the storage, returning how many items were taken
function logistica.try_to_add_item_to_storage(pos, inputStack, dryRun)
  local node = minetest.get_node(pos)
  if not logistica.is_mass_storage(node.name) and not logistica.is_item_storage(node.name) then return 0 end
  local isMassStorage = string.find(node.name, "mass")
  local inv = minetest.get_meta(pos):get_inventory()
  if isMassStorage then
    local maxItems = logistica.get_mass_storage_max_size(pos)
    local numSlots = logistica.get_mass_storage_num_slots(pos)
    local indices = {}
    for i = 1, numSlots do
      local v = inv:get_stack("filter", i)
      if v:get_name() == inputStack:get_name() then
        table.insert(indices, i)
      end
    end
    local remainingStack = ItemStack(inputStack)
    for _, index in ipairs(indices) do
      local storageStack = inv:get_stack("storage", index)
      local canInsert = logistica.clamp(maxItems - storageStack:get_count(), 0, remainingStack:get_count())
      if canInsert > 0 then
        local toInsert = ItemStack(inputStack:get_name())
    		toInsert:set_count(storageStack:get_count() + canInsert)
        if not dryRun then
          inv:set_stack("storage", index, toInsert)
        end
        if canInsert >= remainingStack:get_count() then
          return inputStack:get_count() -- nothing more to check, return early
        else
          remainingStack:set_count(remainingStack:get_count() - canInsert)
        end
      end
    end
    return inputStack:get_count() - remainingStack:get_count()
  else -- it's not mass storage, must be tool storage
    if inputStack:get_stack_max() == 1 and inv:room_for_item("main", inputStack) then
      -- tool storage only takes individual items
      inv:add_item("main", inputStack)
      return 1
    end
  end
  return 0
end

-- takes a list of ItemStacks and returns a single string representation
function logistica.inv_to_table(list)
  local itemStackStrings = {}
  for _,v in pairs(list) do
    itemStackStrings:insert(v:to_string())
  end
end

function logistica.table_to_inv(string)

end

local LIST_SEPARATOR = "L|L"
-- takes a inventory and returns a single string represetation
function logistica.serliaze_inventory(list)
  
end

-- takes a inventory and returns a single string represetation
function logistica.deserliaze_inventory(list)
  
end
