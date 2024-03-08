
local function L(s) return "logistica:"..s end
local SILV = L("silverin")
local SILV_SLICE = L("silverin_slice")

minetest.register_craft({
  output = SILV_SLICE.." 8",
  type = "shapeless",
  recipe = { SILV },
})

minetest.register_craft({
  output = SILV,
  type = "shapeless",
  recipe = {
    SILV_SLICE, SILV_SLICE, SILV_SLICE, SILV_SLICE,
    SILV_SLICE, SILV_SLICE, SILV_SLICE, SILV_SLICE
  },
})

minetest.register_craft({
  output = L("optic_cable 8"),
  recipe = {
    {L("silverin_plate")},
    {L("silverin_slice")},
    {L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("optic_cable_toggleable_off"),
  recipe = {
    {L("optic_cable"), "default:mese_crystal_fragment"}
  }
})

minetest.register_craft({
  output = L("hyperspanner"),
  recipe = {
    {"default:mese_crystal"},
    {L("silverin_circuit")},
    {"default:steel_ingot"},
  }
})

minetest.register_craft({
  output = L("photonizer"),
  recipe = {
    {"default:mese_crystal_fragment"},
    {L("silverin_circuit")},
    {L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("photonizer"),
  type = "shapeless",
  recipe = { L("hyperspanner"), L("photonizer_reversed")},
  replacements = {{L("hyperspanner"), L("hyperspanner")}},
})

minetest.register_craft({
  output = L("photonizer_reversed"),
  type = "shapeless",
  recipe = { L("hyperspanner"), L("photonizer")},
  replacements = {{L("hyperspanner"), L("hyperspanner")}},
})

minetest.register_craft({
  output = L("standing_wave_box"),
  recipe = {
    {L("silverin_mirror_box")},
    {L("silverin_circuit")},
  }
})

minetest.register_craft({
  output = L("storage_upgrade_1"),
  recipe = {
    {L("silverin_slice"), L("standing_wave_box"), L("silverin_slice")},
    {L("silverin_slice"), L("silverin_circuit"),  L("silverin_slice")},
  }
})

minetest.register_craft({
  output = L("storage_upgrade_2"),
  recipe = {
    {"", "default:diamond",      ""},
    {"", L("storage_upgrade_1"), ""},
    {"", L("standing_wave_box"), ""},
  }
})

minetest.register_craft({
  output = "bucket:bucket_lava",
  type = "shapeless",
  recipe = { L("lava_unit"), "bucket:bucket_empty" }
})

minetest.register_craft({
  output = L("cobblegen_upgrade"),
  recipe = {
    {L("silverin_plate"), "bucket:bucket_lava", L("silverin_plate")},
    {"",                  "bucket:bucket_water",  ""},
  },
  replacements = {
    {"bucket:bucket_water", "bucket:bucket_empty"},
    {"bucket:bucket_lava",  "bucket:bucket_empty"},
  }
})

minetest.register_craft({
  output = L("wireless_access_pad"),
  recipe = {
    {L("standing_wave_box"), "default:diamond",     L("standing_wave_box")},
    {L("wireless_crystal"),  L("silverin_circuit"), L("wireless_crystal")},
    {L("silverin_slice"),    L("silverin_circuit"), L("silverin_slice")},
  }
})
