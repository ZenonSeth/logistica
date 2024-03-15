local PUMP_MAX_RANGE = logistica.settings.pump_max_range
local PUMP_MAX_DEPTH = logistica.settings.pump_max_depth

local PUMP_NODES_PER_ROW = 2 * PUMP_MAX_RANGE + 1
local PUMP_NODES_PER_LAYER = PUMP_NODES_PER_ROW * PUMP_NODES_PER_ROW
local PUMP_INDEX_MAX = PUMP_NODES_PER_LAYER * PUMP_MAX_DEPTH

local META_PUMP_INDEX = "pumpix"
local META_OWNER = "pumpowner"
local META_LAST_LAYER = "pumplsl"
local META_LAST_LAYER_HAD_SUCCESS = "pumplss"

local ON_SUFFIX = "_on"

local MAX_CHECKS_PER_TIMER = PUMP_NODES_PER_LAYER -- limits how many nodes the index can advance per timer

local TIMER_SHORT = 1.0
local TIMER_LONG = 3.0

local SOURCES_TO_NAMES = nil

local PUMP_NEIGHBORS = {
  vector.new(-1, 0,  0),
  vector.new( 1, 0,  0),
  vector.new( 0, 0,  1),
  vector.new( 0, 0, -1),
}

local function ends_with(str, ending)
  return str:sub(-#ending) == ending
end

local function sources_to_names()
  if not SOURCES_TO_NAMES then SOURCES_TO_NAMES = logistica.reservoir_get_all_sources_to_names_map() end
  return SOURCES_TO_NAMES
end

local function pump_get_index(meta)
  return meta:get_int(META_PUMP_INDEX)
end

local function pump_set_index(meta, newIndex)
  meta:set_int(META_PUMP_INDEX, newIndex)
end

local function get_owner_name(meta)
  return meta:get_string(META_OWNER)
end

local function get_last_layer(meta)
  return meta:get_int(META_LAST_LAYER)
end

local function set_last_layer(meta, layerInt)
  meta:set_int(META_LAST_LAYER, layerInt)
end

local function get_last_layer_success(meta)
  return meta:get_int(META_LAST_LAYER_HAD_SUCCESS) == 0
end

local function set_last_layer_success(meta, success)
  meta:set_int(META_LAST_LAYER_HAD_SUCCESS, success and 0 or 1)
end

-- returns nil if target position does not have a valid liquid source
-- otherwise returns table {nodeName = "name", isRenewable = true/false, bucketName = "bucket_itemstack_name"}
local function get_valid_source(targetPosition, ownerName)
  logistica.load_position(targetPosition)

  if minetest.is_protected(targetPosition, ownerName) then return nil end

  local node = minetest.get_node_or_nil(targetPosition)
  if not node then return nil end

  local liquidName = sources_to_names()[node.name]
  if not liquidName then return nil end

  -- ensure it's really a source node
  local nodeDef = minetest.registered_nodes[node.name]
  if nodeDef.liquidtype ~= "source" then return nil end

  local bucketName = logistica.reservoir_get_full_bucket_for_liquid(liquidName)
  if not bucketName then return nil end

  -- otherwise its valid
  local isRenewable = nodeDef.liquid_renewable ; if isRenewable == nil then isRenewable = true end -- default value is true, per api docs
  return {
    nodeName = node.name,
    isRenewable = isRenewable,
    bucketName = bucketName,
  }
end

-- returns a vector of the position associated with this index
local function pump_index_to_position(pumpPosition, pumpIndex)
  local x =  pumpIndex % PUMP_NODES_PER_LAYER % PUMP_NODES_PER_ROW
  local y = -math.floor(pumpIndex / PUMP_NODES_PER_LAYER)
  local z =  math.floor((pumpIndex % PUMP_NODES_PER_LAYER) / PUMP_NODES_PER_ROW)
  return vector.add(pumpPosition, vector.new(x - PUMP_MAX_RANGE, y - 1, z - PUMP_MAX_RANGE))
end

-- returns true if succeeded, false if not
local function put_liquid_in_neighboring_reservoirs(pumpPosition, bucketItemStack)
  for _, v in ipairs(PUMP_NEIGHBORS) do
    local neighborPos = vector.add(pumpPosition, v)
    logistica.load_position(neighborPos)
    local neighborNode = minetest.get_node_or_nil(neighborPos)
    if neighborNode and logistica.is_reservoir(neighborNode.name) then
      local resultStack = logistica.reservoir_use_item_on(neighborPos, bucketItemStack, neighborNode)
      if resultStack ~= nil then return true end
    end
  end
  return false
end

-- returns true if succeeded, false if not
local function put_liquid_in_network_reservoirs(pumpPosition, bucketItemStack, network)
  if not network then return false end
  local resultStack = logistica.use_bucket_for_liquid_in_network(pumpPosition, bucketItemStack)
  return resultStack ~= nil -- if we got a replacement, it was successfully emptied into network
end

function logistica.pump_on_power(pos, power)
  local node = minetest.get_node_or_nil(pos)
  if power then
    logistica.start_node_timer(pos, TIMER_SHORT)
    if node and not ends_with(node.name, ON_SUFFIX) then
      logistica.swap_node(pos, node.name..ON_SUFFIX)
    end
  else
    if node and ends_with(node.name, ON_SUFFIX) then
      logistica.swap_node(pos, node.name:sub(1, #node.name - #ON_SUFFIX))
    end
  end
  logistica.set_node_tooltip_from_state(pos, nil, power)
end


function logistica.pump_timer(pos, _)
  local network = logistica.get_network_or_nil(pos)
  local meta = minetest.get_meta(pos)

  local count = 1
  local success = false
  local index = pump_get_index(meta)
  local owner = get_owner_name(meta)

  local lastLayer = get_last_layer(meta)
  local lastLayerSuccess = get_last_layer_success(meta)

  repeat
    local targetPosition = pump_index_to_position(pos, index)
    if targetPosition.y ~= lastLayer then
      -- new layer reached
      if lastLayerSuccess then -- let index continue as normal, but reset last layer success
        set_last_layer_success(meta, false)
      else -- reset index back to 0, and target position with it
        index = 0
        targetPosition = pump_index_to_position(pos, index)
      end
      set_last_layer(meta, targetPosition.y)
    end

    local sourceInfo = get_valid_source(targetPosition, owner)
    if sourceInfo then
      local bucketItemStack = ItemStack(sourceInfo.bucketName)
      success = put_liquid_in_neighboring_reservoirs(pos, bucketItemStack)
      if not success then
        success = put_liquid_in_network_reservoirs(pos, bucketItemStack, network)
      end

      if success then
        set_last_layer_success(meta, true)
        if not sourceInfo.isRenewable then -- renewable liquids are not removed to reduce lag
          minetest.remove_node(targetPosition)
        end
      end
    end
    index = (index + 1) % PUMP_INDEX_MAX
    count = count + 1
  until (count > MAX_CHECKS_PER_TIMER or success)

  if success then logistica.start_node_timer(pos, TIMER_SHORT)
  else logistica.start_node_timer(pos, TIMER_LONG) end

  pump_set_index(meta, index) -- save index even if no success

  return false
end
