
local function mass_storage_room_for_item(pos, meta, stack)
  local stackName = stack:get_name()
  local targetStackSize = stack:get_count()
  local maxNum = logistica.get_mass_storage_max_size(pos)
  local filterList = meta:get_inventory():get_list("filter")
  local storageList = meta:get_inventory():get_list("storage")
  local roomForItems = 0
  for i, storageStack in ipairs(filterList) do
    if storageStack:get_name() == stackName then
      roomForItems = roomForItems + maxNum - storageList[i]:get_count()
    end
  end
  return roomForItems
end

local function insert_item_into_mass_storage(pos, inv, inputStack, dryRun)
  if dryRun == nil then dryRun = false end
  local maxItems = logistica.get_mass_storage_max_size(pos)
  local numSlots = #(inv:get_list("filter"))
  local inputStackName = inputStack:get_name()
  local indices = {}
  for i = 1, numSlots do
    local v = inv:get_stack("filter", i)
    if v:get_name() == inputStackName then
      table.insert(indices, i)
    end
  end
  local remainingStack = ItemStack(inputStack)
  for _, index in ipairs(indices) do
    local storageStack = inv:get_stack("storage", index)
    local canInsert = logistica.clamp(maxItems - storageStack:get_count(), 0, remainingStack:get_count())
    if canInsert > 0 then
      local toInsert = ItemStack(inputStackName)
      toInsert:set_count(storageStack:get_count() + canInsert)
      if not dryRun then
        inv:set_stack("storage", index, toInsert)
      end
      if canInsert >= remainingStack:get_count() then
        remainingStack:set_count(0)
        return remainingStack -- nothing more to check, return early
      else
        remainingStack:set_count(remainingStack:get_count() - canInsert)
      end
    end
  end
  return remainingStack
end

--------------------------------
-- public functions
--------------------------------

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
  logistica.load_position(pos)
  local inv = minetest.get_meta(pos):get_inventory()
  if isMassStorage then
    local remainingStack = insert_item_into_mass_storage(pos, inv, inputStack, dryRun)
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
function logistica.inv_list_to_table(list)
  local itemstackTable = {}
  for k,v in ipairs(list) do
    itemstackTable[k] = v and v:to_string() or ""
  end
  return itemstackTable
end

function logistica.table_to_inv_list(table)
  local list = {}
  for k,v in ipairs(table) do
    if v == nil or v == "" then
      list[k] = ""
    else
      list[k] = ItemStack(v)
    end
  end
  return list
end


function logistica.pull_items_from_network_into_mass_storage(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return end
  local meta = minetest.get_meta(pos)
  local stackPos = logistica.get_next_filled_item_slot(meta, "filter")
  if stackPos <= 0 then return end

  local filterStack = meta:get_inventory():get_stack("filter", stackPos)
  local spaceForItems = mass_storage_room_for_item(pos, meta, filterStack)
    minetest.chat_send_all("trying to take: "..filterStack:get_name()..", space = "..spaceForItems)

  if spaceForItems == 0 then return end

  local requestStack = ItemStack(filterStack)
  requestStack:set_count(spaceForItems)

  local numTaken = 0
  for hash, _ in pairs(network.supplier_cache[requestStack:get_name()] or {}) do
    local taken = logistica.take_item_from_supplier(minetest.get_position_from_hash(hash), requestStack)
    numTaken = numTaken + taken:get_count()
    insert_item_into_mass_storage(pos, meta:get_inventory(), taken)
    if numTaken >= spaceForItems then return end -- everything isnerted, return
    requestStack:set_count(spaceForItems - numTaken)
  end
  -- todo: storage injectors
end

function logistica.start_mass_storage_timer(pos)
  logistica.start_node_timer(pos, 1)
end

function logistica.on_mass_storage_timer(pos, _)
  if not logistica.is_machine_on(pos) then return false end
  if not logistica.get_network_or_nil(pos) then return false end
  logistica.pull_items_from_network_into_mass_storage(pos)
  return true
end