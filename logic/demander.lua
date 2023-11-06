local TIMER_DURATION_SHORT = 1.0
local TIMER_DURATION_LONG = 3.0
local META_DEMANDER_LISTNAME = "demtarlist"
local META_SUPPLIER_LISTNAME = "suptarlist"
local TARGET_NODES_REQUIRING_TIMER = {}
TARGET_NODES_REQUIRING_TIMER["default:furnace"] = true
TARGET_NODES_REQUIRING_TIMER["gravelsieve:auto_sieve3"] = true

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function get_max_rate_for_demander(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return 0 end
  local nodeDef = minetest.registered_nodes[node.name]
  if nodeDef and nodeDef.logistica and nodeDef.logistica.demander_transfer_rate then
    if nodeDef.logistica.demander_transfer_rate <= 0 then return 9999
    else return nodeDef.logistica.demander_transfer_rate end
  else
    return 0
  end
end

local function get_valid_demander_and_target_inventory(demanderPos)
  local meta = get_meta(demanderPos)
  local targetList = meta:get_string(META_DEMANDER_LISTNAME)
  if not targetList then return end

  local targetPos = logistica.get_demander_target(demanderPos)
  if not targetPos then return end

  -- exclude logistica nodes from this
  if string.find(minetest.get_node(targetPos).name, "logistica:") then return end

  local targetInv = get_meta(targetPos):get_inventory()
  if not targetInv:get_list(targetList) then return end

  return {
    demanderPos = demanderPos,
    demanderInventory = meta:get_inventory(),
    targetInventory = targetInv,
    targetList = targetList,
    targetPos = targetPos,
  }
end

local function get_actual_demand_for_item(demandStack, invs)
  local storageList = invs.targetInventory:get_list(invs.targetList)
  local remaining = demandStack:get_count()
    for i,_ in ipairs(storageList) do
      local stored = storageList[i]
      if demandStack:get_name() == stored:get_name() then
        remaining = remaining - stored:get_count()
      end
      if remaining <= 0 then return ItemStack("") end
    end
    if remaining > 0 then
      local missingStack = ItemStack(demandStack)
      missingStack:set_count(remaining)
      return missingStack
    else
      return ItemStack("")
    end
end

-- returns:
-- nil: nothing in inventory?
-- 0: no item has demand
-- ItemStack: the next demanded item
local function get_next_demanded_stack(pos)
  local inventories = get_valid_demander_and_target_inventory(pos)
  if not inventories then return nil end
  local demandStack = nil
  local nextSlot = logistica.get_next_filled_item_slot(get_meta(pos), "filter")
  local startingSlot = nextSlot
  repeat
    if nextSlot <= 0 then return nil end
    local filterStack = inventories.demanderInventory:get_list("filter")[nextSlot]
    demandStack = get_actual_demand_for_item(filterStack, inventories)
    if demandStack:get_count() > 0 then return demandStack end
    nextSlot = logistica.get_next_filled_item_slot(get_meta(pos), "filter")
  until( nextSlot == startingSlot ) -- until we get back to the starting slot
  return 0 -- we had filled slots, but none had demand
end

local function take_demanded_items_from_network(pos, network)
  local demandStack = get_next_demanded_stack(pos)
  if demandStack == nil then return false end
  if demandStack == 0 then return true end -- had items but nothing in demand
  -- limiting the number of items requested
  demandStack:set_count(math.min(get_max_rate_for_demander(pos), demandStack:get_count()))
  local collect = function(st) return logistica.insert_itemstack_for_demander(pos, st) end
  logistica.take_stack_from_network(demandStack, network, collect)
  return true
end

----------------------------------------------------------------
-- Storage operation functions
----------------------------------------------------------------

function logistica.start_demander_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_SHORT end
  logistica.start_node_timer(pos, duration)
  logistica.set_node_on_off_state(pos, true)
end

function logistica.on_demander_timer(pos, elapsed)
  local network = logistica.get_network_or_nil(pos)
  if not network or not logistica.is_machine_on(pos) then
    logistica.set_node_on_off_state(pos, false)
    return false
  end
  if take_demanded_items_from_network(pos, network) then return true
  else return false end
end

function logistica.set_demander_target_list(pos, listName)
  local meta = get_meta(pos)
  meta:set_string(META_DEMANDER_LISTNAME, listName)
end

function logistica.get_demander_target_list(pos)
  local meta = get_meta(pos)
  return meta:get_string(META_DEMANDER_LISTNAME)
end

function logistica.set_supplier_target_list(pos, listName)
  local meta = get_meta(pos)
  meta:set_string(META_SUPPLIER_LISTNAME, listName)
end

function logistica.get_supplier_target_list(pos)
  local meta = get_meta(pos)
  return meta:get_string(META_SUPPLIER_LISTNAME)
end



-- function logistica.update_demander_demand(demanderPos)
--   local meta = get_meta(demanderPos)
--   local inventories = get_valid_demander_and_target_inventory(demanderPos)
--   if not inventories then return end
--   local demandList = logistica.get_demand_based_on_list(
--     inventories.demanderInventory, "filter",
--     inventories.targetInventory, inventories.targetList
--   )
-- end

-- returns a list of ItemStacks tha represent the current demand of this demander
function logistica.get_demander_demand(pos)
  local inv = get_meta(pos):get_inventory()
  local list = inv:get_list("filter")
  if not list then return {} end
  local ret = {}
  for k, v in list do
    ret[k] = ItemStack(v)
  end
  return ret
end

-- returns the demander's target position or nil if the demander isn't loaded
function logistica.get_demander_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local shift = logistica.get_rot_directions(node.param2).backward
  if not shift then return nil end
  return {x = (pos.x + shift.x),
          y = (pos.y + shift.y),
          z = (pos.z + shift.z)}
end

function logistica.get_supplier_target(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local shift = logistica.get_rot_directions(node.param2).backward
  if not shift then return nil end
  return {x = (pos.x + shift.x),
          y = (pos.y + shift.y),
          z = (pos.z + shift.z)}
end

-- returns how many items remain from the itemstack after we attempt to insert it
-- `targetInventory` and `targetList` are optional (tied together), if not passed, it will be looked up
function logistica.insert_itemstack_for_demander(demanderPos, itemstack)
  if not itemstack or itemstack:is_empty() then return 0 end

  local inventories = get_valid_demander_and_target_inventory(demanderPos)
  if not inventories then return itemstack:get_count() end
  local targetInventory = inventories.targetInventory
  local targetList = inventories.targetList

  local leftover = targetInventory:add_item(targetList, itemstack)
  local targetNode = minetest.get_node(inventories.targetPos)
  if leftover:get_count() < itemstack:get_count() and TARGET_NODES_REQUIRING_TIMER[targetNode.name] then
    logistica.start_node_timer(inventories.targetPos, 1)
  end
  return leftover:get_count()
end
