local i = logistica.itemstrings
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
    {L("optic_cable"), i.fragment}
  }
})

minetest.register_craft({
  output = L("hyperspanner"),
  recipe = {
    {i.crystal},
    {L("silverin_circuit")},
    {i.steel},
  }
})

minetest.register_craft({
  output = L("photonizer"),
  recipe = {
    {i.fragment},
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
    {"", i.diamond,               ""},
    {"", L("storage_upgrade_1"),  ""},
    {"", L("standing_wave_box"),  ""},
  }
})

minetest.register_craft({
  output = i.lava_bucket,
  type = "shapeless",
  recipe = { L("lava_unit"), "bucket:bucket_empty" }
})

minetest.register_craft({
  output = L("cobblegen_upgrade"),
  recipe = {
    {L("silverin_plate"), i.lava_bucket,  L("silverin_plate")},
    {"",                  i.water_bucket, ""},
  },
  replacements = {
    {i.water_bucket,  i.empty_bucket},
    {i.water_bucket,  i.empty_bucket},
  }
})

minetest.register_craft({
  output = L("wireless_access_pad"),
  recipe = {
    {L("standing_wave_box"), i.diamond,             L("standing_wave_box")},
    {L("wireless_crystal"),  L("silverin_circuit"), L("wireless_crystal")},
    {L("silverin_slice"),    L("silverin_circuit"), L("silverin_slice")},
  }
})
