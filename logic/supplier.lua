
local p2h = minetest.hash_node_position
local h2p = minetest.get_position_from_hash

-- attempts to insert the given itemstack in the network, returns how many items were inserted
function logistica.insert_item_in_network(itemstack, networkId)
  local network = logistica.networks[networkId]
  if not itemstack or not network then return 0 end

  local workingStack = ItemStack(itemstack)
  -- check demanders first
  for hash, _ in pairs(network.demanders) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    local taken = 0 -- logistica.try_to_give_item_to_demander(pos, workingStack)
    local leftover = workingStack:get_count() - taken
    if leftover <= 0 then return itemstack:get_count() end -- we took all items
    workingStack:set_count(leftover)
  end

  -- check storages
  local storages = {}
  if itemstack:get_stack_max() <= 1 then
    storages = network.item_storage
  else
    storages = network.mass_storage
  end
  for hash, _ in pairs(storages) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    local taken = logistica.try_to_add_item_to_storage(pos, workingStack)
    local leftover = workingStack:get_count() - taken
    if leftover <= 0 then return itemstack:get_count() end -- we took all items
    workingStack:set_count(leftover)
  end

  return itemstack:get_count() - workingStack:get_count()
end
