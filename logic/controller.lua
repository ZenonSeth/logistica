--[[
Outline of controller tick/s:
1. Gather demand from each demander, add them to queue
   - smart queue needed, unify demand per demander
2. For the first N demands, check each supplier and if applicable fulfil demand
3. Gather all storage slots
  - cached, hopefully
4. For each storage slot, check each supplier, and pull up to S items per slot into storage
]]

local TIMER_DURATION_SHORT = 0.5
local TIMER_DURATION_LONG = 2.0

function logistica.start_controller_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_LONG end
  local timer = minetest.get_node_timer(pos)
  timer:start(duration)
end

function logistica.on_controller_timer(pos, elapsed)
  local node = minetest.get_node(pos)
  if not node then return false end -- what?
  if node.name:find("_disabled") then return false end  -- disabled controllers don't do anything

  local had_demand = false

  local network = logistica.get_network_or_nil(pos)
  if not network then
    logistica.on_controller_change(pos, nil) -- this should re-scan the network
  end
  network = logistica.get_network_or_nil(pos)
  if not network then return true end  -- something went wrong, retry again

  local nodes_in_demand = {}
  for demander,_ in pairs(network.demanders) do
    -- check for demand
  end

  -- for each demand, check suppliers


  -- for each demand, check storage

  if had_demand then
    logistica.start_controller_timer(pos, TIMER_DURATION_SHORT)
  else
    logistica.start_controller_timer(pos, TIMER_DURATION_LONG)
  end

  return false
end
