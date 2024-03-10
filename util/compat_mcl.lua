local mcl = minetest.get_modpath("mcl_core")

logistica.sound_mod = mcl and mcl_sounds or default

-- Returns a player's inventory formspec with the correct width and hotbar position for the current game
function logistica.player_inv_formspec(x,y)
    local formspec
    if mcl then
        formspec = "list[current_player;main;"..x..","..y..";9,3;9]"..
            "list[current_player;main;"..x..","..(y+4)..";9,1]"
    else
        formspec = "list[current_player;main;"..x..","..y..";8,1]"..
        "list[current_player;main;"..x..","..(y + 1.25)..";8,3;8]"
    end
    return formspec
end

local formspec_width_extra = (mcl and 1 or 0) + 0.25
logistica.inv_size = function(w, h)
 return tostring(w + formspec_width_extra)..","..tostring(h)
end
logistica.inv_width = (mcl and 9 or 8) + 0.25
logistica.stack_max = mcl and 64 or 99

logistica.node_level = mcl and function(l) return 0 end or function(l) return l end

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
    cobble = mcl and "mcl_core:cobble" or "default:cobble",
}
