local S = logistica.TRANSLATOR

local FILLED_BUCKET_TO_NAME = {} -- { full_bucket_name = liquidName }
local NAME_TO_FILLED_BUCKETS = {} -- { liquidName = { full_bucket_name = true, ... } }
local FILLED_TO_EMPTY = {} -- { full_bucket_name = empty_bucket_name }
local EMPTY_TO_FILLED = {} -- { empty_bucket_name = { liquidName = full_bucket_name } }
local NAME_TO_EMPTY_BUCKETS = {} -- { liquidName = { emptyBucket = true, ... } }
local NAME_TO_DESC = {} -- { liquidName = "Description of liquid" }
local NAME_TO_TEXTURE = {} -- { liquidName = "texture_of_liquid" }
local NAME_TO_SOURCE = {} -- { liquidName = source_node_name }
local SOURCE_TO_NAME = {} -- { source_node_name = liquid_name }

local EMPTY_BUCKET = logistica.itemstrings.empty_bucket
local EMPTY_SUFFIX = "_empty"

local META_LIQUID_LEVEL = "liquidLevel"
local LIQUID_NONE = ""
local BUCKET_ANY = "BUCKET_ANY"

local strDescription = S("Reservoir")
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

local function get_empty_buckets_that_can_accept(liquidName)
  local savedBuckets = NAME_TO_EMPTY_BUCKETS[liquidName]
  if savedBuckets then return savedBuckets
  else return {} end
end

local function does_full_bucket_match_liquid(fullBucketName, liquidName)
  if liquidName == LIQUID_NONE then
    return FILLED_BUCKET_TO_NAME[fullBucketName] ~= nil
  end
  local filledBuckets = NAME_TO_FILLED_BUCKETS[liquidName]
  if not filledBuckets then return false end
  return filledBuckets[fullBucketName] ~= nil
end

-- returns full bucket itemstack name, or nil if there isn't one (because empty can't hold liquid)
local function get_filled_bucket_for_empty_and_liquid(emptyBucketName, liquidName)
  local emptyBucketsForLiquid = NAME_TO_EMPTY_BUCKETS[liquidName]
  if not emptyBucketsForLiquid then return nil end
  if not emptyBucketsForLiquid[emptyBucketName] then return nil end
  local potentialFilledBuckets = EMPTY_TO_FILLED[emptyBucketName]
  if not potentialFilledBuckets then return nil end
  return potentialFilledBuckets[liquidName]
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

function logistica.reservoir_register_names(liquidName, bucketName, emptyBucketName, liquidDesc, liquidTexture, sourceNodeName)
  if not emptyBucketName then emptyBucketName = EMPTY_BUCKET end

  FILLED_BUCKET_TO_NAME[bucketName] = liquidName

  if not NAME_TO_FILLED_BUCKETS[liquidName] then NAME_TO_FILLED_BUCKETS[liquidName] = {} end
  NAME_TO_FILLED_BUCKETS[liquidName][bucketName] = true

  FILLED_TO_EMPTY[bucketName] = emptyBucketName

  if not EMPTY_TO_FILLED[emptyBucketName] then EMPTY_TO_FILLED[emptyBucketName] = {} end
  EMPTY_TO_FILLED[emptyBucketName][liquidName] = bucketName

  if not NAME_TO_EMPTY_BUCKETS[liquidName] then NAME_TO_EMPTY_BUCKETS[liquidName] = {} end
  NAME_TO_EMPTY_BUCKETS[liquidName][emptyBucketName] = true

  NAME_TO_DESC[liquidName] = liquidDesc
  NAME_TO_TEXTURE[liquidName] = liquidTexture
  if sourceNodeName then
    NAME_TO_SOURCE[liquidName] = sourceNodeName
    SOURCE_TO_NAME[sourceNodeName] = liquidName
  end
end

-- returns nil if item had no effect<br>
-- returns an ItemStack to replace the item, if it had effect (e.g. took or stored liquid)
function logistica.reservoir_use_item_on(pos, itemstack, optNode, dryRun)
  local node = optNode or minetest.get_node(pos)
  local nodeDef = minetest.registered_nodes[node.name]
  if not nodeDef or not nodeDef.logistica or not nodeDef.logistica.liquidName or not nodeDef.logistica.maxBuckets then return end

  local itemStackName = itemstack:get_name()
  local meta = minetest.get_meta(pos)
  local nodeLiquidLevel = meta:get_int(META_LIQUID_LEVEL)
  local liquidName = nodeDef.logistica.liquidName
  local maxBuckets = nodeDef.logistica.maxBuckets
  local liquidDesc = logistica.reservoir_get_description_of_liquid(liquidName)

  local isReservoirFull = liquidName ~= LIQUID_NONE

  local tryToFillBucket = false
  local tryToEmptyBucket = false
  if isReservoirFull then
    local emptyBucketsForLiquid = get_empty_buckets_that_can_accept(liquidName)
    if emptyBucketsForLiquid[itemStackName] then tryToFillBucket = true end
  end
  if not tryToFillBucket then
    tryToEmptyBucket = does_full_bucket_match_liquid(itemStackName, liquidName)
  end

  if tryToFillBucket then
    if nodeLiquidLevel == 0 then
      -- make sure we swap this for the empty reservoir
      logistica.swap_node(pos, get_empty_reservoir_name(node.name, liquidName))
      return nil
    end
    local fullBucket = get_filled_bucket_for_empty_and_liquid(itemStackName, liquidName)
    if not fullBucket then return nil end

    nodeLiquidLevel = nodeLiquidLevel - 1
    if nodeLiquidLevel == 0 then
      node.param2 = 0
    else
      node.param2 = logistica.reservoir_make_param2(nodeLiquidLevel, maxBuckets)
    end
    if not dryRun then
      minetest.swap_node(pos, node)
      meta:set_int(META_LIQUID_LEVEL, nodeLiquidLevel)
      if nodeLiquidLevel == 0 then
        local newNodeName = get_empty_reservoir_name(node.name, liquidName)
        if not minetest.registered_nodes[newNodeName] then return nil end
        logistica.swap_node(pos, newNodeName)
      end
      meta:set_string("infotext", logistica.reservoir_get_description(nodeLiquidLevel, maxBuckets, liquidDesc))
    end

    return ItemStack(fullBucket)
  elseif tryToEmptyBucket then
    local newLiquidName = FILLED_BUCKET_TO_NAME[itemStackName]
    if not newLiquidName then return nil end -- wasn't a bucket we can use
    local newEmptyBucket = FILLED_TO_EMPTY[itemStackName]
    if not newEmptyBucket then return nil end

    nodeLiquidLevel = nodeLiquidLevel + 1
    if nodeLiquidLevel > maxBuckets then return nil end
    node.param2 = logistica.reservoir_make_param2(nodeLiquidLevel, maxBuckets)
    minetest.swap_node(pos, node)
    local newNodeName = get_liquid_reservoir_name_for(node.name, newLiquidName)

    local nodeDef = minetest.registered_nodes[newNodeName]
    if not nodeDef or not nodeDef.logistica then return nil end
    if not dryRun then
      if nodeLiquidLevel == 1 then -- first bucket we added, swap to that reservoir type
        logistica.swap_node(pos, newNodeName)
      end
      local newLiquidDesc = logistica.reservoir_get_description_of_liquid(nodeDef.logistica.liquidName)
      meta:set_string("infotext", logistica.reservoir_get_description(nodeLiquidLevel, maxBuckets, newLiquidDesc))
      meta:set_int(META_LIQUID_LEVEL, nodeLiquidLevel)
    end
    return ItemStack(newEmptyBucket)
  end
  return nil
end

-- returns the liquid name for the reservoir; or "" if there's no liquid stored, or nil if its not a reservoir
function logistica.reservoir_get_liquid_name(pos)
  local node = minetest.get_node(pos)
  if not logistica.GROUPS.reservoirs.is(node.name) then return nil end
  local def = minetest.registered_nodes[node.name]
  if not def or not def.logistica or not def.logistica.liquidName then return nil end
  return def.logistica.liquidName
end

-- return {currentLevel, maxLevel} measured in buckets; or nil if its not a reservoir
function logistica.reservoir_get_liquid_level(pos)
  local node = minetest.get_node(pos)
  if not logistica.GROUPS.reservoirs.is(node.name) then return nil end
  local def = minetest.registered_nodes[node.name]
  if not def or not def.logistica or not def.logistica.maxBuckets then return nil end
  local meta = minetest.get_meta(pos)
  return { meta:get_int(META_LIQUID_LEVEL), def.logistica.maxBuckets }
end

function logistica.reservoir_is_empty_bucket(bucketName)
  return EMPTY_TO_FILLED[bucketName] ~= nil
end

function logistica.reservoir_is_full_bucket(bucketName)
  return FILLED_BUCKET_TO_NAME[bucketName] ~= nil
end

-- returns true if the itemname is a known empty or filled bucket that can be used in a reservoir
function logistica.reservoir_is_known_bucket(bucketName)
  return logistica.reservoir_is_empty_bucket(bucketName) or logistica.reservoir_is_full_bucket(bucketName)
end

-- return the liquid name for the given filled bucket name, or nil if there's none registered
function logistica.reservoir_get_liquid_name_for_filled_bucket(bucketName)
  return FILLED_BUCKET_TO_NAME[bucketName]
end

function logistica.reservoir_get_all_filled_buckets_to_names_map()
  return table.copy(FILLED_BUCKET_TO_NAME)
end

function logistica.reservoir_get_all_sources_to_names_map()
  return table.copy(SOURCE_TO_NAME)
end

-- returns a list of empty buckets that can accept this liquid
function logistica.reservoir_get_empty_buckets_that_can_accept(liquidName)
  local emptyBuckets = NAME_TO_EMPTY_BUCKETS[liquidName]
  if not emptyBuckets then return {} end
  return table.copy(emptyBuckets)
end

-- returns the empty bucket name corresponding to the filled bucket - or nil if the given filledBucketName isn't a full bucket
function logistica.reservoir_get_empty_bucket_for_full_bucket(filledBucketName)
  return FILLED_TO_EMPTY[filledBucketName]
end

-- returns a table {filledBucket = true, ...} of the filled buckets that can hold this liquid
-- or empty table if there are none
function logistica.reservoir_get_full_buckets_for_liquid(liquidName)
  local filledBuckets = NAME_TO_FILLED_BUCKETS[liquidName]
  if not filledBuckets then return {} end
  return table.copy(filledBuckets)
end
