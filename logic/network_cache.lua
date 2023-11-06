
local CACHE_PICKER_MASS_STORAGE = {
  listName = "filter",
  clear = function (network) network.storage_cache = {} end,
  cache = function (network) return network.storage_cache end,
  nodes = function (network) return network.mass_storage end,
}
local CACHE_PICKER_SUPPLIER = {
  listName = "filter",
  clear = function (network) network.supplier_cache = {} end,
  cache = function (network) return network.supplier_cache end,
  nodes = function (network) return network.suppliers end,
}

--[[ Completely updates the storage cache which holds where items may be found
  The cache is in the followiing format:
  network.storage_cache = {
    itemName = {
      storagePositionHash1 = true,
      storagePositionHash2 = true,
    }
  }
]]
local function update_network_cache(network, cacheOps)
  cacheOps.clear(network)
  local nodes = cacheOps.nodes(network)
  local cache = cacheOps.cache(network)
  local listName = cacheOps.listName
  for hash, _ in pairs(nodes) do
    local storagePos = minetest.get_position_from_hash(hash)
    logistica.load_position(storagePos)
    local filterList = minetest.get_meta(storagePos):get_inventory():get_list(listName) or {}
    for _, itemStack in pairs(filterList) do
      local name = itemStack:get_name()
      if not cache[name] then cache[name] = {} end
      cache[name][hash] = true
    end
  end
end

-- calls updateStorageCache(network) if the current position belongs to a network
-- `pos` the position for which to try and get the network and update
-- `cacheOps` = one of the predefined `logistica.CACHE_PICKER_XXXXX` consts
local function update_network_cache_for_pos(pos, cacheOps)
  local network = logistica.get_network_or_nil(pos)
  if network then
    update_network_cache(network, cacheOps)
  end
end

local function update_cache_on_item_added(pos, network, cacheOps)
  local nodes = cacheOps.nodes(network)
  local cache = cacheOps.cache(network)
  local listName = cacheOps.listName
  logistica.load_position(pos)
  local filterList = minetest.get_meta(pos):get_inventory():get_list(listName) or {}
  for _, itemStack in pairs(filterList) do
    local name = itemStack:get_name()
    if not cache[name] then cache[name] = {} end
    cache[name][minetest.hash_node_position(pos)] = true
  end
end

local function update_cache_on_item_added_at_pos(pos, cacheOps)
  local network = logistica.get_network_or_nil(pos)
  if network then
    update_cache_on_item_added(pos, network, cacheOps)
  end
end

--------------------------------
-- public functions
--------------------------------

function logistica.update_mass_storage_cache_pos(pos)
  update_network_cache_for_pos(pos, CACHE_PICKER_MASS_STORAGE)
end

function logistica.update_mass_storage_cache(network)
  update_network_cache(network, CACHE_PICKER_MASS_STORAGE)
end

function logistica.update_mass_storage_on_item_added(pos)
  update_cache_on_item_added_at_pos(pos, CACHE_PICKER_MASS_STORAGE)
end

function logistica.update_supplier_cache_pos(pos)
  update_network_cache_for_pos(pos, CACHE_PICKER_SUPPLIER)
end

function logistica.update_supplier_cache(network)
  update_network_cache(network, CACHE_PICKER_SUPPLIER)
end

function logistica.update_supplier_on_item_added(pos)
  update_cache_on_item_added_at_pos(pos, CACHE_PICKER_SUPPLIER)
end
