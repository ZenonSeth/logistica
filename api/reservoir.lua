local S = logistica.TRANSLATOR
local function L(str) return "logistica:"..str end

local META_LIQUID_LEVEL = "liquidLevel"
local META_LIQUID_NAME = "liquidName"

local EMPTY_SUFFIX = "_empty"

local LIQUID_NONE = ""

local VAR_SMALL = "silverin"
local VAR_LARGE = "obsidian"

local SMALL_MAX = 32
local LARGE_MAX = 128

local variants = {VAR_SMALL}
if logistica.settings.large_liquid_tank_enabled then table.insert(variants, VAR_LARGE) end

local variantSpecificDefs = {
  [VAR_SMALL] = {
    description = logistica.reservoir_get_description(0, SMALL_MAX, ""),
    tiles = {"logistica_reservoir_silverin.png"},
    sounds = logistica.node_sound_metallic(),
    logistica = {
      maxBuckets = SMALL_MAX,
    },
  },
  [VAR_LARGE] = {
    description = logistica.reservoir_get_description(0, LARGE_MAX, ""),
    tiles = {"logistica_reservoir_obsidian.png"},
    sounds = logistica.sound_mod.node_sound_stone_defaults(),
    logistica = {
      maxBuckets = LARGE_MAX,
    },
  }
}

----------------------------------------------------------------
-- general helper functions
----------------------------------------------------------------

-- local function drop_item(pos, stack)
--   minetest.add_item(pos, stack)
-- end

local function give_item_to_player(pos, player, stack)
  local inv = player:get_inventory()
  local leftover = inv:add_item("main", stack)
  if leftover and not leftover:is_empty() then
    -- print("leftover not empty, size = " .. leftover:get_count())
    minetest.item_drop(leftover, player, player:get_pos())
  end
end

local function make_inv_image(variant, liquidTexture)
  local liquidMask = "^[mask:logistica_reservoir_liquid_mask.png"
  local resize = "^[resize:83x83" -- this needs to match the size of the mask png
  if variant == VAR_SMALL then
    return liquidTexture..resize..liquidMask.."^logistica_reservoir_silverin_inv.png"
  elseif variant == VAR_LARGE then
    return liquidTexture..resize..liquidMask.."^logistica_reservoir_obsidian_inv.png"
  else
    return nil
  end
end

----------------------------------------------------------------
-- callbacks
----------------------------------------------------------------

local function after_place_node(pos, placer, itemstack, pointed_thing)
  local nodeMeta = minetest.get_meta(pos)
  local node = minetest.get_node(pos)
  local stackMeta = itemstack:get_meta()
  local nodeDef = minetest.registered_nodes[node.name]
  if not nodeDef or not nodeDef.logistica then return end

  local liquidLevel = stackMeta:get_int(META_LIQUID_LEVEL)
  local liquidDesc = logistica.reservoir_get_description_of_liquid(nodeDef.logistica.liquidName)
  local maxBuckets = nodeDef.logistica.maxBuckets

  nodeMeta:set_int(META_LIQUID_LEVEL, liquidLevel)
  node.param2 = logistica.reservoir_make_param2(liquidLevel, maxBuckets)
  minetest.swap_node(pos, node)
  nodeMeta:set_string("infotext", logistica.reservoir_get_description(liquidLevel, maxBuckets, liquidDesc))
  logistica.on_reservoir_change(pos)
end

local function preserve_metadata(pos, oldnode, oldmeta, drops)
  if not drops or not drops[1] then return end
  local nodeDef = minetest.registered_nodes[oldnode.name]
  if not nodeDef or not nodeDef.logistica then return end

  local meta = minetest.get_meta(pos)
  local drop = drops[1]
  local dropMeta = drop:get_meta()
  local liquidDesc = logistica.reservoir_get_description_of_liquid(nodeDef.logistica.liquidName)
  local maxBuckets = nodeDef.logistica.maxBuckets
  local liquidLevel = meta:get_int(META_LIQUID_LEVEL)

  dropMeta:set_int(META_LIQUID_LEVEL, liquidLevel)
  dropMeta:set_string("description", logistica.reservoir_get_description(liquidLevel, maxBuckets, liquidDesc))
end

local function on_rightclick(pos, node, player, itemstack, pointed_thing, max)
  if not player or not player:is_player() or minetest.is_protected(pos, player:get_player_name()) then return end

    local usedItem = logistica.reservoir_use_item_on(pos, itemstack, node)

    if not usedItem then return end

    if itemstack:get_count() == 1 then
      return usedItem
    else
      give_item_to_player(pos, player, usedItem)
      itemstack:take_item(1)
      return itemstack
    end
end

--------------------------------
-- registration helpers
--------------------------------

local commonDef = {
  drawtype = "glasslike_framed_optional",
  paramtype = "light",
  paramtype2 = "glasslikeliquidlevel",
  is_ground_content = false,
  sunlight_propagates = false,
  groups = {cracky = 3, level = logistica.node_level(1), pickaxey = 1, [logistica.TIER_ALL] = 1},
  preserve_metadata = preserve_metadata,
  after_place_node = after_place_node,
  after_dig_node = logistica.on_reservoir_change,
  on_rightclick = on_rightclick,
  stack_max = 1,
  backface_culling = false,
  _mcl_hardness = 1.5,
  _mcl_blast_resistance = 10
}

local function get_variant_def(variantName)
  if not variantSpecificDefs[variantName] then return nil end
  local vDef = table.copy(variantSpecificDefs[variantName])
  local def = table.copy(commonDef)
  for k,v in pairs(vDef) do def[k] = v end
  return def
end

--------------------------------
-- minetest registration
--------------------------------

-- register empty tanks, always
for _, variantName in ipairs(variants) do
  local def = get_variant_def(variantName)
  local nodeName = L("reservoir_"..variantName..EMPTY_SUFFIX)
  def.drops = nodeName
  def.logistica.liquidName = LIQUID_NONE
  minetest.register_node(nodeName, def)
  logistica.reservoirs[nodeName] = true
end

--[[
  `liquidName`: the name used to register the reservoir, should have no spaces and all lowercase<br>
  `liquidDesc`: a human readable liquid description, e.g. "Water"<br>
  `bucketItemName` : the name of the bucket that holds the liquid<br>
  `liquidTexture` : a single texture to use for the liquid<br>
  `optLight` : optional, if nil assumed 0. How much a non-empty reservoir will glow
  `emptyBucketName` : optional, if nil, bucket:bucket_empty will be used - the "empty" container to use<br>
]]
function logistica.register_reservoir(liquidName, liquidDesc, bucketItemName, liquidTexture, optLight, optEmptyBucketName)
  local lname = string.lower(liquidName:gsub(" ", "_"))

  for _, variantName in ipairs(variants) do
    local nodeName = L("reservoir_"..variantName.."_"..lname)
    local def = get_variant_def(variantName)
    def.drops = nodeName
    def.special_tiles = {liquidTexture}
    def.logistica.liquidName = lname
    def.groups.not_in_creative_inventory = 1
    def.light_source = optLight
    def.inventory_image = make_inv_image(variantName, liquidTexture)

    minetest.register_node(nodeName, def)
    logistica.reservoirs[nodeName] = true

    logistica.reservoir_register_names(lname, bucketItemName, optEmptyBucketName, liquidDesc, liquidTexture)
  end
end
