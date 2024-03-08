local mcl = minetest.get_modpath("mcl_core")

logistica.sound_mod = mcl and mcl_sounds or default

logistica.itemstrings = {
    sand = mcl and "mcl_core:sand" or "default:silver_sand",
    chest = mcl and "mcl_chests:chest" or "default:chest",
    fragment = mcl and "mesecons:redstone" or "default:mese_crystal_fragment",
    crystal = mcl and "mesecons_torch:redstoneblock" or "default:mese_crystal",
    steel = mcl and "mcl_core:iron_ingot" or "default:steel_ingot",
    diamond = mcl and "mcl_core:diamond" or "default:diamond",
    empty_bucket = mcl and "mcl_buckets:bucket_empty" or "bucket:bucket_empty",
    lava_bucket = mcl and "mcl_buckets:bucket_lava" or "bucket:bucket_lava",
    water_bucket = mcl and "mcl_buckets:bucket_water" or "bucket:bucket_water",
    river_water_bucket = mcl and "mcl_buckets:bucket_river_water" or "bucket:bucket_river_water",
    obsidian = mcl and "mcl_core:obsidian" or "default:obsidianbrick",
    clay = mcl and "mcl_core:clay" or "default:clay",
    cactus = mcl and "mcl_core:cactus" or "default:cactus",
    ice = mcl and "mcl_core:ice" or "default:ice",
    glass = mcl and "mcl_core:glass" or "default:glass",
}