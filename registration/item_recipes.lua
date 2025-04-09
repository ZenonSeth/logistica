local itemstrings = logistica.itemstrings
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
    {L("optic_cable"), itemstrings.fragment}
  }
})

minetest.register_craft({
  output = L("hyperspanner"),
  recipe = {
    {itemstrings.crystal},
    {L("silverin_circuit")},
    {itemstrings.steel},
  }
})

minetest.register_craft({
  output = L("photonizer"),
  recipe = {
    {itemstrings.fragment},
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
    {"", itemstrings.diamond,               ""},
    {"", L("storage_upgrade_1"),  ""},
    {"", L("standing_wave_box"),  ""},
  }
})

for filledBucket, _ in pairs(logistica.reservoir_get_full_buckets_for_liquid(logistica.liquids.lava)) do
  local emptyBucket = logistica.reservoir_get_empty_bucket_for_full_bucket(filledBucket)
  if minetest.registered_items[filledBucket] and minetest.registered_items[emptyBucket] then
    minetest.register_craft({
      output = filledBucket,
      type = "shapeless",
      recipe = { L("lava_unit"), emptyBucket }
    })
  end
end

minetest.register_craft({
  output = L("cobblegen_upgrade"),
  recipe = {
    {L("silverin_plate"), itemstrings.lava_bucket,  L("silverin_plate")},
    {"",                  itemstrings.water_bucket, itemstrings.cobgen_upgr_additional},
  },
  replacements = {
    {itemstrings.water_bucket,  itemstrings.empty_bucket},
    {itemstrings.water_bucket,  itemstrings.empty_bucket},
  }
})

minetest.register_craft({
  output = L("wireless_access_pad"),
  recipe = {
    {L("standing_wave_box"), itemstrings.diamond,             L("standing_wave_box")},
    {L("wireless_crystal"),  L("silverin_circuit"), L("wireless_crystal")},
    {L("silverin_slice"),    L("silverin_circuit"), L("silverin_slice")},
  }
})

minetest.register_craft({
  output = L("compression_tank 2"),
  recipe = {
    {"",                  L("silverin_plate"), ""},
    {L("silverin_plate"), "",                  L("silverin_plate")},
    {"",                  L("silverin_plate"), ""},
  }
})

minetest.register_craft({
  output = L("wireless_antenna 2"),
  recipe = {
    {"", L("silverin_plate"),   ""},
    {"", L("wireless_crystal"), ""},
    {"", L("silverin_circuit"), ""},
  }
})
