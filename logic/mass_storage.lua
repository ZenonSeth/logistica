local META_IMG_PIC = "logimgpick"
local META_RES_VAL = "logresval"
local META_UPGRADE_ADD = "logstorupgr"
local VALID_RESERVE_VALUES = {}
for i = 0,5120,128 do VALID_RESERVE_VALUES[i/128 + 1] = i end
local BASE_TRANSFER_RATE = 10

local function mass_storage_room_for_item(pos, meta, stack)
  local stackName = stack:get_name()
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
    local meta = minetest.get_meta(pos)
    local storageUpgrade = meta:get_int(META_UPGRADE_ADD)
    return def.logistica.maxItems + storageUpgrade
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
  if not network then
    logistica.toggle_machine_on_off(pos)
    logistica.set_node_tooltip_from_state(pos)
    return
  end
  logistica.set_node_tooltip_from_state(pos)
  local meta = minetest.get_meta(pos)
  local stackPos = logistica.get_next_filled_item_slot(meta, "filter")
  if stackPos <= 0 then return end

  local filterStack = meta:get_inventory():get_stack("filter", stackPos)
  local spaceForItems = mass_storage_room_for_item(pos, meta, filterStack)

  if spaceForItems == 0 then return end

  local requestStack = ItemStack(filterStack)
  requestStack:set_count(math.min(spaceForItems, logistica.get_supplier_transfer_rate(meta)))

  local numTaken = 0
  for hash, _ in pairs(network.supplier_cache[requestStack:get_name()] or {}) do
    local taken = logistica.take_item_from_supplier(minetest.get_position_from_hash(hash), requestStack)
    numTaken = numTaken + taken:get_count()
    logistica.insert_item_into_mass_storage(pos, meta:get_inventory(), taken)
    if numTaken >= spaceForItems then return end -- everything isnerted, return
    requestStack:set_count(spaceForItems - numTaken)
  end
end

function logistica.start_mass_storage_timer(pos)
  logistica.start_node_timer(pos, 1)
end

function logistica.on_mass_storage_timer(pos, _)
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

-- returns a table of {0,128,256,512...} up to the max this box supports
function logistica.get_mass_storage_valid_reserve_list(pos)
  local max = logistica.get_mass_storage_max_size(pos)
  local vals = {}
  for _, v in ipairs(VALID_RESERVE_VALUES) do
    if v <= max then 
      table.insert(vals, v)
    end
  end
  return vals
end

function logistica.set_mass_storage_reserve(meta, i, value)
  meta:set_int(META_RES_VAL..tostring(i), value)
end

function logistica.on_mass_storage_reserve_changed(pos, i, value)
  local meta = minetest.get_meta(pos)
  local intVal = tonumber(value)
  if type(intVal) ~= "number" then return end
  local invalid = true
  for _, v in ipairs(VALID_RESERVE_VALUES) do if v == intVal then invalid = false end end
  if invalid then return end
  meta:set_int(META_RES_VAL..tostring(i), intVal)
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
    local item = meta:get_inventory():get_list("filter")[slot] or ItemStack("")
    logistica.display_item_on_block_front(pos, item:get_name(), newParam2)
  end
end

function logistica.get_mass_storage_imgname_or_first_item(meta)
  local inv = meta:get_inventory()
  if inv:is_empty("filter") then return "\n(Empty)" end
  local index = meta:get_int(META_IMG_PIC)
  local itemStack = inv:get_stack("filter", index)
  if not itemStack:is_empty() then return "\n(Has: "..itemStack:get_description()..")" end
  for _, v in ipairs(inv:get_list("filter")) do
    if not v:is_empty() then return "\n(Has: "..v:get_description()..")" end
  end
  return "\n(Empty)"
end

function logistica.is_valid_storage_upgrade(stackName)
  return logistica.craftitem.storage_upgrade[stackName] ~= nil
end

function logistica.update_mass_storage_cap(pos, optMeta)
  local meta = optMeta or minetest.get_meta(pos)
  local storageUpgrade = 0
  local list = meta:get_inventory():get_list("upgrade") or {}
  for _, item in ipairs(list) do
    local upgradeDef = logistica.craftitem.storage_upgrade[item:get_name()]
    if upgradeDef and upgradeDef.storage_upgrade then
      storageUpgrade = storageUpgrade + upgradeDef.storage_upgrade
    end
  end
  meta:set_int(META_UPGRADE_ADD, storageUpgrade)
end

function logistica.on_mass_storage_upgrade_change(pos, upgradeName, wasAdded)
  local upgradeDef = logistica.craftitem.storage_upgrade[upgradeName]
  if not upgradeDef or not upgradeDef.storage_upgrade then return true end
  local meta = minetest.get_meta(pos)
  local storageUpgrade = meta:get_int(META_UPGRADE_ADD)
  if wasAdded then storageUpgrade = storageUpgrade + upgradeDef.storage_upgrade
  else storageUpgrade = storageUpgrade - upgradeDef.storage_upgrade end
  meta:set_int(META_UPGRADE_ADD, storageUpgrade)
end

function logistica.can_remove_mass_storage_upgrade(pos, upgradeName)
  local upgradeDef = logistica.craftitem.storage_upgrade[upgradeName]
  if not upgradeDef or not upgradeDef.storage_upgrade then return true end
  local inv = minetest.get_meta(pos):get_inventory()
  local maxStored = 0
  for _, st in ipairs(inv:get_list("storage") or {}) do
    if st:get_count() > maxStored then maxStored = st:get_count() end
  end
  local currMax = logistica.get_mass_storage_max_size(pos)
  return (currMax - upgradeDef.storage_upgrade) >= maxStored
end
