local S = logistica.TRANSLATOR

local BUCKET_TO_NAME = {}
local NAME_TO_BUCKET = {}
local NAME_TO_EMPTY_BUCKET = {}
local NAME_TO_DESC = {}
local NAME_TO_TEXTURE = {}

local EMPTY_BUCKET = "bucket:bucket_empty"
local EMPTY_SUFFIX = "_empty"

local META_LIQUID_LEVEL = "liquidLevel"
local LIQUID_NONE = ""
local BUCKET_ANY = "BUCKET_ANY"

local strDescription = S("Reservoir")
local strEmpty = S("Empty")
local getStrContains = function(number, max, ofWhat)
  if number == 0 then
    return S("@1 / @2 buckets", number, max)
  else
    return S("@1 / @2 buckets of @3", number, max, ofWhat)
  end
end

local function ends_with(str, ending)
  return ending == "" or string.sub(str, -#ending) == ending
end

local function get_empty_bucket_needed_for(liquidName)
  local savedBucket = NAME_TO_EMPTY_BUCKET[liquidName]
  if savedBucket then return savedBucket
  else return EMPTY_BUCKET end
end

local function get_full_bucket_needed_for(liquidName)
  if liquidName == LIQUID_NONE then return BUCKET_ANY end
  return NAME_TO_BUCKET[liquidName]
end

local function get_empty_reservoir_name(nodeName, liquidName)
  if not ends_with(nodeName, liquidName) then return nodeName end
  if ends_with(nodeName, EMPTY_SUFFIX) then return nodeName end
  local nodeBase = string.sub(nodeName, 1, (#nodeName) - (#liquidName) - 1)
  return nodeBase..EMPTY_SUFFIX
end

local function get_liquid_reservoir_name_for(nodeName, liquidName)
  if not ends_with(nodeName, EMPTY_SUFFIX) then return nodeName end
  local nodeBase = string.sub(nodeName, 1, (#nodeName) - (#EMPTY_SUFFIX))
  local newName = nodeBase.."_"..liquidName
  if not minetest.registered_nodes[newName] then return nodeName
  else return newName end
end

--------------------------------
-- public functions
--------------------------------

function logistica.reservoir_get_description_of_liquid(liquidName)
  return NAME_TO_DESC[liquidName] or LIQUID_NONE
end

function logistica.reservoir_get_texture_of_liquid(liquidName)
  return NAME_TO_TEXTURE[liquidName] or ""
end

function logistica.reservoir_make_param2(val, max)
  local ret = math.floor(63*(val/max))
  if val > 0 and ret == 0 then
    ret = 1     -- this ensures we always have at least 1 visible liquid level
  end
  return ret
end

function logistica.reservoir_get_description(currBuckets, maxBuckets, liquidName)
  return strDescription.."\n"..getStrContains(currBuckets, maxBuckets, liquidName)
end

function logistica.reservoir_register_names(liquidName, bucketName, emptyBucketName, liquidDesc, liquidTexture)
  BUCKET_TO_NAME[bucketName] = liquidName
  NAME_TO_BUCKET[liquidName] = bucketName
  if emptyBucketName then
    NAME_TO_EMPTY_BUCKET[liquidName] = emptyBucketName
  end
  NAME_TO_DESC[liquidName] = liquidDesc
  NAME_TO_TEXTURE[liquidName] = liquidTexture
end

-- returns nil if item had no effect<br>
-- returns an ItemStack to replace the item, if it had effect (e.g. took or stored liquid)
function logistica.reservoir_use_item_on(pos, itemstack, optNode)
  local node = optNode or minetest.get_node(pos)
  local nodeDef = minetest.registered_nodes[node.name]
  if not nodeDef or not nodeDef.logistica or not nodeDef.logistica.liquidName or not nodeDef.logistica.maxBuckets then return end

  local itemStackName = itemstack:get_name()
  local meta = minetest.get_meta(pos)
  local nodeLiquidLevel = meta:get_int(META_LIQUID_LEVEL)
  local liquidName = nodeDef.logistica.liquidName
  local maxBuckets = nodeDef.logistica.maxBuckets
  local liquidDesc = logistica.reservoir_get_description_of_liquid(liquidName)

  local emptyBucket = get_empty_bucket_needed_for(liquidName)
  local fullBucket = get_full_bucket_needed_for(liquidName)

  if itemStackName == emptyBucket then
    if nodeLiquidLevel == 0 then
      -- make sure we swap this for the empty reservoir
      logistica.swap_node(pos, get_empty_reservoir_name(node.name, liquidName))
      return nil
    end
    if not fullBucket then return nil end

    nodeLiquidLevel = nodeLiquidLevel - 1
    if nodeLiquidLevel == 0 then
      node.param2 = 0
    else
      node.param2 = logistica.reservoir_make_param2(nodeLiquidLevel, maxBuckets)
    end
    minetest.swap_node(pos, node)
    meta:set_int(META_LIQUID_LEVEL, nodeLiquidLevel)
    if nodeLiquidLevel == 0 then
      local newNodeName = get_empty_reservoir_name(node.name, liquidName)
      if not minetest.registered_nodes[newNodeName] then return nil end
      logistica.swap_node(pos, newNodeName)
    end
    meta:set_string("infotext", logistica.reservoir_get_description(nodeLiquidLevel, maxBuckets, liquidDesc))

    return ItemStack(fullBucket)
  elseif fullBucket == BUCKET_ANY or itemStackName == fullBucket then
    local newLiquidName = BUCKET_TO_NAME[itemStackName]
    if not newLiquidName then return nil end -- wasn't a bucket we can use
    local newEmptyBucket = get_empty_bucket_needed_for(newLiquidName)
    if not newEmptyBucket then return nil end

    nodeLiquidLevel = nodeLiquidLevel + 1
    if nodeLiquidLevel > maxBuckets then return nil end
    node.param2 = logistica.reservoir_make_param2(nodeLiquidLevel, maxBuckets)
    minetest.swap_node(pos, node)
    local newNodeName = get_liquid_reservoir_name_for(node.name, newLiquidName)

    local nodeDef = minetest.registered_nodes[newNodeName]
    if not nodeDef or not nodeDef.logistica then return nil end
    if nodeLiquidLevel == 1 then -- first bucket we added, swap to that reservoir type
      logistica.swap_node(pos, newNodeName)
    end
    local newLiquidDesc = logistica.reservoir_get_description_of_liquid(nodeDef.logistica.liquidName)
    meta:set_string("infotext", logistica.reservoir_get_description(nodeLiquidLevel, maxBuckets, newLiquidDesc))
    meta:set_int(META_LIQUID_LEVEL, nodeLiquidLevel)
    return ItemStack(newEmptyBucket)
  end
  return nil
end

-- returns the liquid name for the reservoir; or "" if there's no liquid stored, or nil if its not a reservoir
function logistica.reservoir_get_liquid_name(pos)
  local node = minetest.get_node(pos)
  if not logistica.is_reservoir(node.name) then return nil end
  local def = minetest.registered_nodes[node.name]
  if not def or not def.logistica or not def.logistica.liquidName then return nil end
  return def.logistica.liquidName
end

-- return {currentLevel, maxLevel} measured in buckets; or nil if its not a reservoir
function logistica.reservoir_get_liquid_level(pos)
  local node = minetest.get_node(pos)
  if not logistica.is_reservoir(node.name) then return nil end
  local def = minetest.registered_nodes[node.name]
  if not def or not def.logistica or not def.logistica.maxBuckets then return nil end
  local meta = minetest.get_meta(pos)
  return { meta:get_int(META_LIQUID_LEVEL), def.logistica.maxBuckets }
end

function logistica.reservoir_is_empty_bucket(bucketName)
  if bucketName == EMPTY_BUCKET then return true end
  for _, bucket in pairs(NAME_TO_EMPTY_BUCKET) do
    if bucket == bucketName then return true end
  end
  return false
end

function logistica.reservoir_is_full_bucket(bucketName)
  if BUCKET_TO_NAME[bucketName] ~= nil then return true end
  return false
end

-- returns true if the itemname is a known empty or filled bucket that can be used in a reservoir
function logistica.reservoir_is_known_bucket(bucketName)
  return logistica.reservoir_is_empty_bucket(bucketName) or logistica.reservoir_is_full_bucket(bucketName)
end

-- return the liquid name for the given bucket name, or nil if there's none registered
function logistica.reservoir_get_liquid_name_for_bucket(bucketName)
  return BUCKET_TO_NAME[bucketName]
end