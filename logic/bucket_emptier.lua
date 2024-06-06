local S = logistica.TRANSLATOR

local INV_INPUT = "input"
local INV_MAIN = "main"

local TIMER_SHORT = 1.0
local TIMER_LONG = 3.0

function logistica.emptier_on_power(pos, power)
  if power then
    logistica.start_node_timer(pos, TIMER_SHORT)
  end
  local meta = minetest.get_meta(pos)
  logistica.set_node_tooltip_from_state(pos, nil, power)
end


function logistica.emptier_timer(pos, elapsed)
  local network = logistica.get_network_or_nil(pos)
  if not network then return false end

  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()

  local firstSlot = logistica.get_next_filled_item_slot(meta, INV_INPUT)
  local currSlot = firstSlot
  local success = false

  if currSlot > 0 then
    repeat
      local stack = inv:get_stack(INV_INPUT, currSlot)
      local stackName = stack:get_name()
      local liquidName = logistica.reservoir_get_liquid_name_for_filled_bucket(stackName)
      if liquidName then
        local emptyBucket = logistica.reservoir_get_empty_bucket_for_full_bucket(stackName)
        if emptyBucket and inv:room_for_item(INV_MAIN, ItemStack(emptyBucket)) then
          local newStack = logistica.empty_bucket_into_network(network, stack)
          if newStack then
            success = true
            local replaceStack = ItemStack("")
            if stack:get_count() > 1 then
              replaceStack = ItemStack(stackName)
              replaceStack:set_count(stack:get_count() - 1)
            end
            inv:set_stack(INV_INPUT, currSlot, replaceStack)
            inv:add_item(INV_MAIN, newStack)
            logistica.update_cache_at_pos(pos, LOG_CACHE_SUPPLIER, network)
          end
        end
      end
      if not success then currSlot = logistica.get_next_filled_item_slot(meta, INV_INPUT) end
    until(success or currSlot == firstSlot)
  end

  if success then logistica.start_node_timer(pos, TIMER_SHORT)
  else logistica.start_node_timer(pos, TIMER_LONG) end
  return false
end
