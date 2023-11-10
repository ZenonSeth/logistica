
local TIMER_DURATION_LONG = 5

function logistica.start_controller_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_LONG end
  logistica.start_node_timer(pos, duration)
end

function logistica.on_controller_timer(pos, elapsed)
  local node = minetest.get_node_or_nil(pos)
  if not node then return true end -- what?
  if not logistica.is_controller(node.name) then return false end

  local network = logistica.get_network_or_nil(pos)
  if not network then
    logistica.on_controller_change(pos) -- this should re-scan the network
  end
  return true
end
