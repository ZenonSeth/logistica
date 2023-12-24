
local TIMER_DURATION = 1
local META_TARGET_LAVA = "tarlava"
local META_LAVA_IN_TANK = "lavam"

local EMPTY_BUCKET = "bucket:bucket_empty"
local LAVA_LIQUID_NAME = "lava"

local function get_lava_furnace_lava_in_tank(meta)
  return meta:get_int(META_LAVA_IN_TANK)
end

local function set_lava_furnace_lava_in_tank(meta, newLevel)
  meta:set_int(META_LAVA_IN_TANK, newLevel)
end

local function get_min_lava(meta)
  return meta:get_int(META_TARGET_LAVA)
end

--------------------------------
-- public functions
--------------------------------

-- returns the lava cap in milibuckets
function logistica.lava_furnace_get_lava_capacity(pos)
  local nodeName = minetest.get_node(pos).name
  local nodeDef = minetest.registered_nodes[nodeName]
  if not nodeDef or not nodeDef.logistica or not nodeDef.logistica.lava_capacity then
    return nil
  end
  return nodeDef.logistica.lava_capacity * 1000
end

function logistica.lava_furnace_fueler_start_timer(pos)
  logistica.start_node_timer(pos, TIMER_DURATION)
end

-- returns the target position of the lava furnace
function logistica.lava_furnace_fueler_target_pos(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return nil end
  local target = vector.add(pos, logistica.get_rot_directions(node.param2).backward)
  if not minetest.get_node_or_nil(target) then return nil end
  return target
end

function logistica.lava_furnace_fueler_on_timer(pos, elapsed)
  if not logistica.is_machine_on(pos) then return end
  if not logistica.get_network_or_nil(pos) then return true end

  local targetPos = logistica.lava_furnace_fueler_target_pos(pos)
  local targetNode = minetest.get_node(targetPos)
  local targetDef = minetest.registered_nodes[targetNode.name]

  if not targetDef
    or not targetDef.logistica
    or not targetDef.logistica.lava_furnace
    or not targetDef.logistica.lava_capacity
  then
    return true
  end

  local meta = minetest.get_meta(pos)
  local targetMeta = minetest.get_meta(targetPos)

  local minLava = get_min_lava(meta)
  local targetLavaCap = logistica.lava_furnace_get_lava_capacity(targetPos)
  local targetCurrLava = get_lava_furnace_lava_in_tank(targetMeta)
  local newTargetLava = targetCurrLava + 1000

  if targetCurrLava < minLava and newTargetLava < targetLavaCap then
    local takenLiquid = logistica.use_bucket_for_liquid_in_network(pos, ItemStack(EMPTY_BUCKET), LAVA_LIQUID_NAME)
    if not takenLiquid then return true end
    set_lava_furnace_lava_in_tank(targetMeta, newTargetLava)
    logistica.start_node_timer(targetPos, 1)
  end

  return true
end
