
local TIMER_DURATION_LONG = 5

function logistica.start_controller_timer(pos, duration)
  if duration == nil then duration = TIMER_DURATION_LONG end
  logistica.start_node_timer(pos, duration)
end

local function try_migrate_owner_from_transmitter(pos)
  local meta = minetest.get_meta(pos)
  if meta:get_string("owner") ~= "" then return end
  local network = logistica.get_network_or_nil(pos, nil, true)
  if not network then return end
  for posHash, _ in pairs(network.wireless_transmitters) do
    local trMeta = minetest.get_meta(minetest.get_position_from_hash(posHash))
    local trOwner = trMeta:get_string("owner")
    if trOwner ~= "" then
      meta:set_string("owner", trOwner)
      return
    end
  end
end

function logistica.on_controller_timer(pos, _)
  local node = minetest.get_node_or_nil(pos)
  if not node then return true end -- what?
  if not logistica.GROUPS.controllers.is(node.name) then return false end

  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then
    logistica.on_controller_change(pos) -- this should re-scan the network
  end
  try_migrate_owner_from_transmitter(pos)
  return true
end
