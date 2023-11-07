
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

local function show_deposited_item_popup(player, numDeposited, name)
  logistica.show_popup(player:get_player_name(), "Stored "..numDeposited.." "..name, 1.5)
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

-- Returns a stack of how many items remain
function logistica.insert_item_into_mass_storage(pos, inv, inputStack, dryRun)
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

function logistica.pull_items_from_network_into_mass_storage(pos)
  local network = logistica.get_network_or_nil(pos)
  if not network then return end
  local meta = minetest.get_meta(pos)
  local stackPos = logistica.get_next_filled_item_slot(meta, "filter")
  if stackPos <= 0 then return end

  local filterStack = meta:get_inventory():get_stack("filter", stackPos)
  local spaceForItems = mass_storage_room_for_item(pos, meta, filterStack)

  if spaceForItems == 0 then return end

  local requestStack = ItemStack(filterStack)
  requestStack:set_count(spaceForItems)

  local numTaken = 0
  for hash, _ in pairs(network.supplier_cache[requestStack:get_name()] or {}) do
    local taken = logistica.take_item_from_supplier(minetest.get_position_from_hash(hash), requestStack)
    numTaken = numTaken + taken:get_count()
    logistica.insert_item_into_mass_storage(pos, meta:get_inventory(), taken)
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

function logistica.try_to_add_player_wield_item_to_mass_storage(pos, player)
  if not pos or not player or not player:is_player() then return end
  local wieldStack = player:get_wielded_item()
  if wieldStack:get_count() == 0 or wieldStack:get_stack_max() <= 1 then return end

  local numDesposited = 0
  local inv = minetest.get_meta(pos):get_inventory()
  local newStack = logistica.insert_item_into_mass_storage(pos, inv, wieldStack)
  if newStack:get_count() ~= wieldStack:get_count() then
    player:set_wielded_item(newStack)
    numDesposited = wieldStack:get_count() - newStack:get_count()
  end
  if newStack:get_count() > 0 or not player:get_player_control().sneak then 
    show_deposited_item_popup(player, numDesposited, wieldStack:get_short_description())
    return
  end

  -- else, storage potentially has more space, and player was holding sneak
  -- try to deposit as many items ouf of their inventory as possible

  local pInv = player:get_inventory()
  local pListName = player:get_wield_list()
  local pList = pInv:get_list(pListName)
  for i, pInvStack in ipairs(pList) do
    if pInvStack:get_name() == wieldStack:get_name() then
      newStack = logistica.insert_item_into_mass_storage(pos, inv, pInvStack)
      numDesposited = numDesposited + pInvStack:get_count() - newStack:get_count()
      pInv:set_stack(pListName, i, newStack)
      if newStack:get_count() > 0 then
        show_deposited_item_popup(player, numDesposited, wieldStack:get_short_description())
        return -- failed to deposit some
      end
    end
  end
  show_deposited_item_popup(player, numDesposited, wieldStack:get_short_description())
end
