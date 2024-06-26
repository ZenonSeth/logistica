local META_KEY_PREV = "logprev_"
--local META_KEY_CURR = "logcurr_"

local SEP = ";"

LOG_CACHE_MASS_STORAGE = {
  listName = "filter",
  clear = function (network) network.storage_cache = {} end,
  cache = function (network) return network.storage_cache end,
  nodes = function (network) return network.mass_storage end,
}
LOG_CACHE_SUPPLIER = {
  listName = "main",
  clear = function (network) network.supplier_cache = {} end,
  cache = function (network) return network.supplier_cache end,
  nodes = function (network) return network.suppliers end,
}
LOG_CACHE_REQUESTER = {
  listName = "filter",
  clear = function (network) network.requester_cache = {} end,
  cache = function (network) return network.requester_cache end,
  nodes = function (network) return network.requesters end,
}

-- returns {{b is missing these from a}, {b has these new to a}}
local function diff(seta, setb)
    local d = {}
    local e = {}
    for k,v in pairs(seta) do d[k]=true end
    for k,v in pairs(setb) do if not d[k] then e[k] = true else d[k]=nil end end
    return {d, e}
end

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local function list_to_cache_nameset(list)
  local ret = {}
  for i, item in ipairs(list) do
    if item:get_name() ~= "" then
      ret[item:get_name()] = true
    end
  end
  return ret
end

local function nameset_to_cache_str(nameset)
  local str = ""
  local first = true
  for k, _ in pairs(nameset) do
    if first then str = k ; first = false
    else str = str..SEP..k end
  end
  return str
end

local function cache_str_to_nameset(cache_str)
  local vals = string.split(cache_str, SEP, false)
  local ret = {}
  for _,v in ipairs(vals) do ret[v] = true end
  return ret
end

local function save_prev_cache(nodeMeta, listName, nameset)
  nodeMeta:set_string(META_KEY_PREV..listName, nameset_to_cache_str(nameset))
end

local function clear_prev_cache(nodeMeta, listName)
  nodeMeta:set_string(META_KEY_PREV..listName, "")
end

local function get_prev_cache_as_nameset(nodeMeta, listName)
  return cache_str_to_nameset(nodeMeta:get_string(META_KEY_PREV..listName))
end

-- local function save_curr_cache(nodeMeta, listName, cacheStr)
--   nodeMeta:set_string(META_KEY_CURR..listName, cacheStr)
-- end

-- local function get_curr_cache_as_namelist(nodeMeta, listName)
--   return nodeMeta:get_string(META_KEY_CURR..listName)
-- end

-- clears all cache for the given ops, and re-caches them
local function update_network_cache(network, cacheOps)
  cacheOps.clear(network)
  local nodes = cacheOps.nodes(network)
  local cache = cacheOps.cache(network)
  local listName = cacheOps.listName
  for hash, _ in pairs(nodes) do
    local storagePos = minetest.get_position_from_hash(hash)
    logistica.load_position(storagePos)
    local nodeMeta = get_meta(storagePos)
    local list = logistica.get_cache_list_for(storagePos, nodeMeta, listName)
    for _, itemStack in ipairs(list) do
      local name = itemStack:get_name()
      if name ~= "" then
        if not cache[name] then cache[name] = {} end
        cache[name][hash] = true
      end
    end
    save_prev_cache(nodeMeta, listName, list_to_cache_nameset(list))
  end
end

-- smartly tries to update the the cache for the given position
local function update_network_cache_for_pos(pos, cacheOps, optNetwork)
  local network = optNetwork or logistica.get_network_or_nil(pos)
  if not network then return end
  local meta = get_meta(pos)
  local hash = minetest.hash_node_position(pos)
  local listName = cacheOps.listName
  local prevCacheItems = get_prev_cache_as_nameset(meta, listName)
  local currCacheItems = list_to_cache_nameset(logistica.get_cache_list_for(pos, meta, listName))

  local cache = cacheOps.cache(network)
  local remAndAdd = diff(prevCacheItems, currCacheItems)
  for name, _ in pairs(remAndAdd[1]) do
    if cache[name] then cache[name][hash] = nil end
    if logistica.table_is_empty(cache[name]) then cache[name] = nil end
  end
  for name, _ in pairs(remAndAdd[2]) do
    if not cache[name] then cache[name] = {} end
    if cache[name] then cache[name][hash] = true end
  end
  save_prev_cache(meta, listName, currCacheItems)
end

local function remove_network_cache_for_pos(pos, cacheOps, optNetwork)
  local network = optNetwork or logistica.get_network_or_nil(pos)
  if not network then return end
  local meta = get_meta(pos)
  local hash = minetest.hash_node_position(pos)
  local listName = cacheOps.listName
  local cache = cacheOps.cache(network)
  local prevCacheItems = get_prev_cache_as_nameset(meta, listName)

  for name, _ in pairs(prevCacheItems) do
    local posCache = cache[name]
    if posCache then posCache[hash] = nil end
  end
  --clear_prev_cache(meta, listName)
end

--------------------------------
-- public functions
--------------------------------

-- clears previous specified cache and updates entirely
-- `type` is one of LOG_CACHE_MASS_STORAGE, LOG_CACHE_SUPPLIER, LOG_CACHE_REQUESTER
function logistica.update_cache_network(network, type)
  update_network_cache(network, type)
end

-- updates the storage cache for the specific position
-- `type` is one of LOG_CACHE_MASS_STORAGE, LOG_CACHE_SUPPLIER, LOG_CACHE_REQUESTER
-- optNetwork is optional, the network it belongs to
function logistica.update_cache_at_pos(pos, type, optNetwork)
  update_network_cache_for_pos(pos, type, optNetwork)
end

-- removes the given pos's cache from the network
-- `type` is one of LOG_CACHE_MASS_STORAGE, LOG_CACHE_SUPPLIER, LOG_CACHE_REQUESTER
function logistica.update_cache_node_removed_at_pos(pos, type, optNetwork)
  remove_network_cache_for_pos(pos, type, optNetwork)
end

-- helper

function logistica.get_cache_list_for(position, meta, listName)
  local nodeName = minetest.get_node(position).name
  local nodeDef = minetest.registered_nodes[nodeName]
  if nodeDef and nodeDef.logistica and nodeDef.logistica.get_cache_list then
    return nodeDef.logistica.get_cache_list(position) or {}
  else
    return logistica.get_list(meta:get_inventory(), listName)
  end
end
