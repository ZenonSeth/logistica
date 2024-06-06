
-- Provide compatiblity with:
-- 1. The bucket_lite mod and its many buckets
-- 2. The wooden bucket mod (there's 2 of them but only 1 seems functional with latest minetest - the bucket_wooden)



local liquids = logistica.liquids
local des = liquids.name_to_description
local tex = liquids.name_to_texture
local src = liquids.name_to_source_block
local lit = liquids.name_to_light

--[[ table entry format:
[empty_bucket_name] = {
  [liquid_name] = filled_bucket_name
}
--]]
local buckets_to_register = {}

-- default buckets
--[[
  logistica.register_reservoir(
  liq.lava, des[liq.lava], itemstrings.lava_bucket, tex[liq.lava], src[liq.lava], lit[liq.lava])
logistica.register_reservoir(
  liq.water, des[liq.water], itemstrings.water_bucket, tex[liq.water], src[liq.water], lit[liq.water])
logistica.register_reservoir(
  liq.river_water, des[liq.river_water], itemstrings.river_water_bucket, tex[liq.river_water], src[liq.river_water], lit[liq.river_water])
]]

buckets_to_register[logistica.itemstrings.empty_bucket] = {
  [liquids.water] = logistica.itemstrings.water_bucket,
  [liquids.river_water] = logistica.itemstrings.river_water_bucket,
  [liquids.lava] = logistica.itemstrings.lava_bucket,
}

-- bucket_lite

local function liteEmptyBucket(type) return "bucket:bucket_empty_"..type end
local function liteWaterBucket(type) return "bucket:bucket_water_uni_"..type end
local function liteRiverBucket(type) return "bucket:bucket_water_river_"..type end
local function liteLavaBucket(type) return "bucket:bucket_lava_uni_"..type end
local bucket_lite_types = { "bronze", "diamond", "gold", "mese", "steel", "stone", "wood" }
for _, type in ipairs(bucket_lite_types) do
  local emptyBucket = liteEmptyBucket(type)
  if minetest.registered_items[emptyBucket] then
    buckets_to_register[emptyBucket] = {
      [liquids.water] = liteWaterBucket(type),
      [liquids.river_water] = liteRiverBucket(type),
      [liquids.lava] = liteLavaBucket(type),
    }
  end
end

-- bucket_wooden

if minetest.registered_items["bucket_wooden:bucket_empty"] then
  buckets_to_register["bucket_wooden:bucket_empty"] = {
    [liquids.water] = "bucket_wooden:bucket_water",
    [liquids.river_water] = "bucket_wooden:bucket_river_water",
  }
end

--

----------------------------------------------------------------
-- global funcs and registration
----------------------------------------------------------------

function logistica.compat_bucket_register_buckets()
  for emptyBucket, data in pairs(buckets_to_register) do
    for liquidName, fullBucket in pairs(data) do
      if minetest.registered_items[fullBucket] then
        logistica.register_reservoir(
          liquidName, des[liquidName], fullBucket, tex[liquidName], src[liquidName], lit[liquidName], emptyBucket
        )
      end
    end
  end

  -- unique buckets with unique liquids
  if minetest.registered_items["mcl_mobitems:milk_bucket"] then
    logistica.register_reservoir("milk", "Milk", "mcl_mobitems:milk_bucket", "logistica_milk_liquid.png")
  end
  if minetest.registered_items["animalia:bucket_milk"] then
    logistica.register_reservoir("milk", "Milk", "animalia:bucket_milk", "logistica_milk_liquid.png")
  end
  if minetest.registered_items["ethereal:bucket_cactus"] then
    logistica.register_reservoir("cactus_pulp", "Cactus Pulp", "ethereal:bucket_cactus", "logistica_milk_liquid.png^[colorize:#697600:227")
  end
end
