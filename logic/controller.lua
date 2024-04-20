
local TIMER_DURATION_LONG = 5

function logistica.start_controller_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_LONG end
  logistica.start_node_timer(pos, duration)
end

function logistica.on_controller_timer(pos, _)
  local node = minetest.get_node_or_nil(pos)
  if not node then return true end -- what?
  if not logistica.GROUPS.controllers.is(node.name) then return false end

  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    logistica.on_controller_change(pos) -- this should re-scan the network
  end
  return true
end
