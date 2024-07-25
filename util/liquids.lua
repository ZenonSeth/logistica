local S = logistica.TRANSLATOR

local itemstrings = logistica.itemstrings

logistica.liquids = {}
local liq = logistica.liquids
liq.lava = "lava"
liq.water = "water"
liq.river_water = "river_water"

liq.name_to_description = {
  [liq.lava] = S("Lava"),
  [liq.water] = S("Water"),
  [liq.river_water] = S("River Water"),
}

local lava_texture = "default_lava.png"
local water_texture = "default_water.png"
local river_water_texture = "default_river_water.png"

local mcla = minetest.get_game_info().id == "mineclonia"
local mcl2 = minetest.get_game_info().id == "mineclone2" or minetest.get_game_info().id == "VoxeLibre"
if mcla then
  lava_texture = "default_lava_source_animated.png^[sheet:1x16:0,0"
  water_texture = "default_water_source_animated.png^[sheet:1x16:0,0"
  river_water_texture = "default_river_water_source_animated.png^[sheet:1x16:0,0"
elseif mcl2 then
  lava_texture = "mcl_core_lava_source_animation.png^[sheet:1x16:0,0"
  water_texture = "mcl_core_water_source_animation.png^[sheet:1x16:0,0^[multiply:#3F76E4"
  river_water_texture = "mcl_core_water_source_animation.png^[sheet:1x16:0,0^[multiply:#0084FF"
end

liq.name_to_texture = {
  [liq.lava] = lava_texture,
  [liq.water] = water_texture,
  [liq.river_water] = river_water_texture,
}

liq.name_to_source_block = {
  [liq.lava] = itemstrings.lava_source,
  [liq.water] = itemstrings.water_source,
  [liq.river_water] = itemstrings.river_water_source,
}

liq.name_to_light = {
  [liq.lava] = 8,
  [liq.water] = 0,
  [liq.river_water] = 0,
}
