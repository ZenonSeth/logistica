local S = logistica.TRANSLATOR

local META_CURRENT_BUCKET_INDEX = "filcur"

local INV_MAIN = "main"
local INV_INPUT = "input"

local buckets_to_names = nil
local function get_all_buckets_to_names_list()
  if not buckets_to_names then
    buckets_to_names = logistica.table_to_list_indexed(
      logistica.reservoir_get_all_buckets_to_names_map(),
      function (bucketName, liquidName)
        return { bucketName = bucketName, liquidName = liquidName }
      end
  )
  end
  return buckets_to_names
end

-- Returns a a table of {bucketName = "bucket:name", liquidName = "Name of liquid"}
function logistica.filler_get_current_selected_bucket(pos)
  local meta = minetest.get_meta(pos)
  local index = meta:get_int(META_CURRENT_BUCKET_INDEX)
  local allBuckets = get_all_buckets_to_names_list()
  local currBucket = allBuckets[index]
  if not currBucket then currBucket = allBuckets[0] or {} end
  return {
    bucketName = currBucket.bucketName or "",
    liquidName = currBucket.liquidName or "",
  }
end

function logistica.filler_change_selected_bucket(pos, change)
  local allBucketsToNames = get_all_buckets_to_names_list()
  local maxSize = #allBucketsToNames
  local meta = minetest.get_meta(pos)
  local index = meta:get_int(META_CURRENT_BUCKET_INDEX)
  index = index + change
  if index < 1 then index = maxSize
  elseif index > maxSize then index = 1 end
  meta:set_int(META_CURRENT_BUCKET_INDEX, index)

  -- set the main inventory's list
  local inv = meta:get_inventory()
  local mainList = {}
  if allBucketsToNames[index] then
    mainList[1] = ItemStack(allBucketsToNames[index].bucketName)
  end
  inv:set_list(INV_MAIN, mainList)
  logistica.on_supplier_change(pos) -- notify we got new item (well probably)
end

-- return a table of {remaining = int, erroMsg = ""}, indicating how many items remain to be fulfilled, and an optional error msg if any
function logistica.take_item_from_bucket_filler(pos, stackToTake, network, collectorFunc, isAutomatedRequest, dryRun, depth)
  if stackToTake:get_count() <= 0 then return { remaining = 0, errorMsg =  S("Can't take a stack of size 0") } end
  if not network then return { remaining = stackToTake:get_count(), errorMsg =  S("No network") } end -- filling happens from network reservoirs, so need a network
  if not depth then depth = 1 end

  local originalRequestedBuckets = stackToTake:get_count()
  local stackToTakeName = stackToTake:get_name()
  local liquidName = logistica.reservoir_get_liquid_name_for_bucket(stackToTakeName)
  if not liquidName then return { remaining = stackToTake:get_count(), errorMsg =  S("Unknown liquid: ")..liquidName } end

  local liquidInfo = logistica.get_liquid_info_in_network(pos, liquidName)
  local remainingRequest = math.min(liquidInfo.curr, originalRequestedBuckets)
  local unfillableBuckets = originalRequestedBuckets - remainingRequest

  local filledBucketName = logistica.reservoir_get_full_bucket_for_liquid(liquidName)
  local emptyBucketName = logistica.reservoir_get_empty_bucket_for_liquid(liquidName)

  -- first try to get the empty bucket from our internal inventory
  local inv = minetest.get_meta(pos):get_inventory()
  local collectedInternal = remainingRequest
  local tookFromInternal = false
  while collectedInternal > 0 and not tookFromInternal do -- try to take max, then 1 less, etc, until we take it, or we hit 0
    local needed = ItemStack(emptyBucketName); needed:set_count(collectedInternal)
    if inv:contains_item(INV_INPUT, needed) then
      tookFromInternal = true
    else
      collectedInternal = collectedInternal - 1
    end
  end

  -- remaining decreased by how many we actually managed to take from internal inv
  remainingRequest = remainingRequest - collectedInternal

  -- then if necessary, try to take remaining empty buckets from network
  local collectedFromNetwork = 0
  if remainingRequest > 0 then
    local collectEmpty = function(stackToInsert) collectedFromNetwork = stackToInsert:get_count() ; return 0 end
    local stackToTakeFromNetwork = ItemStack(emptyBucketName) ; stackToTakeFromNetwork:set_count(remainingRequest)
    logistica.take_stack_from_network(stackToTakeFromNetwork, network, collectEmpty, isAutomatedRequest, false, true, depth + 1)
    remainingRequest = remainingRequest - collectedFromNetwork
  end

  local numEmptyBucketsAvailable = collectedInternal + collectedFromNetwork

  local emptyBucketStack = ItemStack(emptyBucketName)
  for _ = 1, numEmptyBucketsAvailable, 1 do
    logistica.fill_bucket_from_network(network, emptyBucketStack, liquidName)
  end

  local toGive = ItemStack(filledBucketName) ; toGive:set_count(numEmptyBucketsAvailable)
  local leftover = collectorFunc(toGive)

  if not dryRun then -- actually remove empty buckets from storages
    local numAccepted = numEmptyBucketsAvailable - leftover
    local actuallyTakeFromInternal = math.min(collectedInternal, numAccepted)
    if actuallyTakeFromInternal > 0 then
      local stackRemInternal = ItemStack(emptyBucketName) ; stackRemInternal:set_count(actuallyTakeFromInternal)
      inv:remove_item(INV_INPUT, stackRemInternal)
    end

    local actuallyTakeFromNetwork = math.min(collectedFromNetwork, numAccepted - actuallyTakeFromInternal)
    local stackToTakeFromNetwork = ItemStack(emptyBucketName) ; stackToTakeFromNetwork:set_count(actuallyTakeFromNetwork)
    logistica.take_stack_from_network(stackToTakeFromNetwork, network, function(_) return 0 end, isAutomatedRequest, false, false, depth + 1)
  end

  local error = nil
  if numEmptyBucketsAvailable < originalRequestedBuckets - unfillableBuckets then
    error = S("Not enough empty buckets available")
  elseif unfillableBuckets > 0 then
    error = S("Not enough liquid available in network")
  end
  return { remaining = unfillableBuckets + remainingRequest, errorMsg = error }
end
