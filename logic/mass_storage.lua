local S = logistica.TRANSLATOR

local META_IMG_PIC = "logimgpick"
local META_RES_VAL = "logresval"
local META_DEMAND_VAL = "logdemandval"
local META_DEMAND_CRAFTING = "logdemandcraft"
local META_UPGRADE_ADD = "logstorupgr"
local META_UPGRADE_MULT = "logstorupgrmult"
local BASE_TRANSFER_RATE = 10

local function mass_storage_room_for_item(pos, meta, stack)
  local stackName = stack:get_name()
  local maxNum = logistica.get_mass_storage_max_size(pos)
  local filterList = logistica.get_list(meta:get_inventory(), "filter")
  local storageList = logistica.get_list(meta:get_inventory(), "storage")
  local roomForItems = 0
  for i, storageStack in ipairs(filterList) do
    if storageStack:get_name() == stackName then
      roomForItems = roomForItems + maxNum - storageList[i]:get_count()
    end
  end
  return roomForItems
end

local function show_deposited_item_popup(player, numDeposited, name)
  logistica.show_popup(player:get_player_name(), S("Stored ")..numDeposited.." "..name, 1.5)
end

-- returns an ItemStack of how many items were taken
local function take_item_from_supplier_for_mass_storage(pos, stack, allowCrafting)
  logistica.load_position(pos)
  local node = minetest.get_node(pos)
  local removed = ItemStack("")
  local network = logistica.get_network_or_nil(pos)
  local collectFunc = function(st) removed:add_item(st); return 0 end
  if logistica.GROUPS.crafting_suppliers.is(node.name) then
    if allowCrafting then
      logistica.take_item_from_crafting_supplier(pos, stack, network, collectFunc, false, false, 1)
    end
  else
    logistica.take_item_from_supplier(pos, stack, network, collectFunc, false, false)
  end
  return removed
end

--------------------------------
-- public functions
--------------------------------

function logistica.get_mass_storage_max_size(pos)
  local node = minetest.get_node(pos)
  if not node then return 0 end
  local def = minetest.registered_nodes[node.name]
  if def and def.logistica and def.logistica.maxItems then
    local meta = minetest.get_meta(pos)
    local storageUpgrade = meta:get_int(META_UPGRADE_ADD)
    local mult = meta:get_int(META_UPGRADE_MULT)
    if mult <= 0 then mult = 1 end
    return math.min((def.logistica.maxItems + storageUpgrade) * mult, 65535)
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

-- returns the transfer rate of given mass storage node
function logistica.get_supplier_transfer_rate(meta)
  -- TODO: account for speed upgrade
  return BASE_TRANSFER_RATE
end

-- Returns a stack of how many items remain
function logistica.insert_item_into_mass_storage(pos, inv, inputStack, dryRun)
  local maxItems = logistica.get_mass_storage_max_size(pos)
  local numSlots = #(logistica.get_list(inv, "filter"))
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
  if not network then return false end
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local maxSize = logistica.get_mass_storage_max_size(pos)
  local numSlots = logistica.get_mass_storage_num_slots(pos)
  local transferRate = logistica.get_supplier_transfer_rate(meta)
  for i = 1, numSlots do
    local demand = math.min(logistica.get_mass_storage_demand(meta, i), maxSize)
    if demand > 0 then
      local filterStack = inv:get_stack("filter", i)
      if not filterStack:is_empty() then
        local currentCount = inv:get_stack("storage", i):get_count()
        local needed = math.min(demand - currentCount, transferRate)
        if needed > 0 then
          local itemName = filterStack:get_name()
          local allowCrafting = logistica.get_mass_storage_demand_crafting(meta, i)
          local requestStack = ItemStack(itemName)
          requestStack:set_count(needed)
          for hash, _ in pairs(network.supplier_cache[itemName] or {}) do
            local taken = take_item_from_supplier_for_mass_storage(
              minetest.get_position_from_hash(hash), requestStack, allowCrafting)
            local takenCount = taken:get_count()
            if takenCount > 0 then
              local remainder = logistica.insert_item_into_mass_storage(pos, inv, taken)
              local inserted = takenCount - remainder:get_count()
              requestStack:set_count(requestStack:get_count() - inserted)
              if requestStack:get_count() <= 0 then break end
            end
          end
        end
      end
    end
  end
  return true
end

function logistica.start_mass_storage_timer(pos, optAddRandomOffset)
  logistica.start_node_timer(pos, 1, optAddRandomOffset)
end

function logistica.on_mass_storage_timer(pos, _)
  return logistica.pull_items_from_network_into_mass_storage(pos)
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
  local pList = logistica.get_list(pInv, pListName)
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

function logistica.mass_storage_deposit_from_player(pos, playerName)
  local player = minetest.get_player_by_name(playerName)
  if not player then return end
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local filterList = logistica.get_list(inv, "filter")
  local allowedItems = {}
  for _, fStack in ipairs(filterList) do
    if not fStack:is_empty() then
      allowedItems[fStack:get_name()] = true
    end
  end
  if not next(allowedItems) then return end
  local playerInv = player:get_inventory()
  for i = 1, playerInv:get_size("main") do
    local pStack = playerInv:get_stack("main", i)
    if not pStack:is_empty() and allowedItems[pStack:get_name()] then
      local leftover = logistica.insert_item_into_mass_storage(pos, inv, pStack)
      if leftover:get_count() < pStack:get_count() then
        playerInv:set_stack("main", i, leftover)
      end
    end
  end
end

function logistica.set_mass_storage_reserve(meta, i, value)
  meta:set_int(META_RES_VAL..tostring(i), value)
end

function logistica.get_mass_storage_demand(meta, i)
  return meta:get_int(META_DEMAND_VAL..tostring(i))
end

function logistica.set_mass_storage_demand(meta, i, value)
  meta:set_int(META_DEMAND_VAL..tostring(i), value)
end

function logistica.get_mass_storage_demand_crafting(meta, i)
  return meta:get_string(META_DEMAND_CRAFTING..tostring(i)) == "1"
end

function logistica.set_mass_storage_demand_crafting(meta, i, value)
  meta:set_string(META_DEMAND_CRAFTING..tostring(i), value and "1" or "0")
end

function logistica.get_mass_storage_demand_as_string(name, meta)
  local numSlots = minetest.registered_nodes[name].logistica.numSlots
  local parts = {}
  for i = 1, numSlots do
    parts[i] = logistica.get_mass_storage_demand(meta, i)..","..
               (logistica.get_mass_storage_demand_crafting(meta, i) and "1" or "0")
  end
  return table.concat(parts, ";")
end

function logistica.set_mass_storage_demand_from_string(name, str, meta)
  if not str or str == "" then return end
  local numSlots = minetest.registered_nodes[name].logistica.numSlots
  local slots = string.split(str, ";", false)
  for i = 1, numSlots do
    if slots[i] then
      local parts = string.split(slots[i], ",", false)
      logistica.set_mass_storage_demand(meta, i, tonumber(parts[1]) or 0)
      logistica.set_mass_storage_demand_crafting(meta, i, parts[2] == "1")
    end
  end
end

function logistica.on_mass_storage_image_select_change(pos, i)
  local meta = minetest.get_meta(pos)
  local prev = meta:get_int(META_IMG_PIC)
  if prev == i then meta:set_int(META_IMG_PIC, 0)
  else meta:set_int(META_IMG_PIC, i) end
end

function logistica.set_mass_storage_image_slot(meta, index)
  return meta:set_int(META_IMG_PIC, index)
end

-- returns an index of which slot is picked to be the front image, or 0 if there isn't one
function logistica.get_mass_storage_image_slot(meta)
  return meta:get_int(META_IMG_PIC)
end

-- returns the picked reserve for the given index
function logistica.get_mass_storage_reserve(meta, index)
  return meta:get_int(META_RES_VAL..tostring(index))
end

-- `newParam2` is optional, will override the lookup of node.param2 for rotation
function logistica.update_mass_storage_front_image(origPos, newParam2)
  local pos = vector.new(origPos)
  logistica.remove_item_on_block_front(pos)
  local meta = minetest.get_meta(pos)
  local slot = logistica.get_mass_storage_image_slot(meta)
  if slot > 0 then
    local inv = meta:get_inventory()
    local item = logistica.get_list(inv, "filter")[slot] or ItemStack("")
    logistica.display_item_on_block_front(pos, item:get_name(), newParam2)
  end
end

function logistica.get_mass_storage_imgname_or_first_item(meta)
  local inv = meta:get_inventory()
  if inv:is_empty("filter") then return S("\n(Empty)") end
  local index = meta:get_int(META_IMG_PIC)
  local itemStack = inv:get_stack("filter", index)
  if not itemStack:is_empty() then return S("\n(Has: ")..itemStack:get_description()..")" end
  for _, v in ipairs(logistica.get_list(inv, "filter")) do
    if not v:is_empty() then return S("\n(Has: ")..v:get_description()..")" end
  end
  return S("\n(Empty)")
end

function logistica.is_valid_storage_upgrade(stackName)
  return logistica.craftitem.storage_upgrade[stackName] ~= nil
end

function logistica.update_mass_storage_cap(pos, optMeta)
  local meta = optMeta or minetest.get_meta(pos)
  local storageUpgrade = 0
  local storageMult = 1
  local list = logistica.get_list(meta:get_inventory(), "upgrade")
  for _, item in ipairs(list) do
    local upgradeDef = logistica.craftitem.storage_upgrade[item:get_name()]
    if upgradeDef then
      if upgradeDef.storage_upgrade then
        storageUpgrade = storageUpgrade + upgradeDef.storage_upgrade
      end
      if upgradeDef.storage_multiplier then
        storageMult = upgradeDef.storage_multiplier
      end
    end
  end
  meta:set_int(META_UPGRADE_ADD, storageUpgrade)
  meta:set_int(META_UPGRADE_MULT, storageMult)
end

function logistica.on_mass_storage_upgrade_change(pos, upgradeName, wasAdded)
  local upgradeDef = logistica.craftitem.storage_upgrade[upgradeName]
  if not upgradeDef then return true end
  local meta = minetest.get_meta(pos)
  if upgradeDef.storage_upgrade then
    local storageUpgrade = meta:get_int(META_UPGRADE_ADD)
    if wasAdded then storageUpgrade = storageUpgrade + upgradeDef.storage_upgrade
    else storageUpgrade = storageUpgrade - upgradeDef.storage_upgrade end
    meta:set_int(META_UPGRADE_ADD, storageUpgrade)
  end
  if upgradeDef.storage_multiplier then
    meta:set_int(META_UPGRADE_MULT, wasAdded and upgradeDef.storage_multiplier or 1)
  end
end

function logistica.can_remove_mass_storage_upgrade(pos, upgradeName)
  local upgradeDef = logistica.craftitem.storage_upgrade[upgradeName]
  if not upgradeDef then return true end
  local inv = minetest.get_meta(pos):get_inventory()
  local maxStored = 0
  for _, st in ipairs(logistica.get_list(inv, "storage")) do
    if st:get_count() > maxStored then maxStored = st:get_count() end
  end
  local currMax = logistica.get_mass_storage_max_size(pos)
  if upgradeDef.storage_upgrade then
    return (currMax - upgradeDef.storage_upgrade) >= maxStored
  end
  if upgradeDef.storage_multiplier then
    -- removing the multiplier divides capacity by storage_multiplier
    return math.floor(currMax / upgradeDef.storage_multiplier) >= maxStored
  end
  return true
end

function logistica.is_multiplier_storage_upgrade(stackName)
  local upgradeDef = logistica.craftitem.storage_upgrade[stackName]
  return upgradeDef ~= nil and upgradeDef.storage_multiplier ~= nil
end

function logistica.has_multiplier_upgrade_in_inv(inv)
  for _, st in ipairs(logistica.get_list(inv, "upgrade")) do
    if logistica.is_multiplier_storage_upgrade(st:get_name()) then return true end
  end
  return false
end

-- Returns what get_mass_storage_max_size would return if upgrade at slotIndex were replaced by newUpgradeName
function logistica.get_mass_storage_max_after_swap(pos, slotIndex, newUpgradeName)
  local node = minetest.get_node(pos)
  local def = minetest.registered_nodes[node.name]
  if not (def and def.logistica and def.logistica.maxItems) then return 0 end
  local storageUpgrade = 0
  local storageMult = 1
  for i, item in ipairs(logistica.get_list(minetest.get_meta(pos):get_inventory(), "upgrade")) do
    local name = (i == slotIndex) and newUpgradeName or item:get_name()
    local upgradeDef = logistica.craftitem.storage_upgrade[name]
    if upgradeDef then
      if upgradeDef.storage_upgrade then storageUpgrade = storageUpgrade + upgradeDef.storage_upgrade end
      if upgradeDef.storage_multiplier then storageMult = upgradeDef.storage_multiplier end
    end
  end
  return math.min((def.logistica.maxItems + storageUpgrade) * storageMult, 65535)
end
