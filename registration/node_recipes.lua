local itemstrings = logistica.itemstrings
local function L(s) return "logistica:"..s end

minetest.register_craft({
  output = L("lava_furnace"),
  recipe = {
    {itemstrings.clay,  itemstrings.obsidian,     itemstrings.clay},
    {itemstrings.steel, itemstrings.empty_bucket, itemstrings.steel},
    {itemstrings.steel, itemstrings.empty_bucket, itemstrings.steel},
  }
})

minetest.register_craft({
  output = L("mass_storage_basic"),
  recipe = {
    {L("silverin_plate"),      L("optic_cable"),         L("silverin_plate")},
    {L("silverin_mirror_box"), L("silverin_mirror_box"), L("silverin_mirror_box")},
    {L("silverin_plate"),      L("silverin_circuit"),    L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("item_storage"),
  recipe = {
    {L("silverin_plate"), "",                       L("silverin_plate")},
    {L("optic_cable"),    L("silverin_mirror_box"), L("silverin_circuit")},
    {L("silverin_plate"), L("silverin_mirror_box"), L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("passive_supplier"),
  recipe = {
    {L("silverin_plate"), itemstrings.chest, L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),   L("silverin_circuit")},
    {L("silverin_plate"), "",                L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("requester_item"),
  recipe = {
    {L("silverin_plate"), "",              L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"), L("silverin_circuit")},
    {L("silverin_plate"), "",              L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("requester_stack"),
  recipe = {
    {L("silverin_plate"), L("silverin_circuit"), L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),       L("silverin_circuit")},
    {L("silverin_plate"), L("silverin_circuit"), L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("injector_slow"),
  recipe = {
    {L("silverin_plate"), "",                       L("silverin_plate")},
    {L("optic_cable"),    L("photonizer_reversed"), L("silverin_circuit")},
    {L("silverin_plate"), "",                       L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("injector_fast"),
  recipe = {
    {L("silverin_plate"), L("silverin_circuit"),    L("silverin_plate")},
    {L("optic_cable"),    L("photonizer_reversed"), L("silverin_circuit")},
    {L("silverin_plate"), L("silverin_circuit"),    L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("simple_controller"),
  recipe = {
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
    {L("silverin_circuit"), L("optic_cable"),      L("silverin_circuit")},
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("access_point"),
  recipe = {
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
    {L("photonizer"),       L("optic_cable"),      L("photonizer_reversed")},
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("trashcan"),
  recipe = {
    {L("silverin_plate"), L("optic_cable"),   L("silverin_plate")},
    {"",                  "",                 ""},
    {L("silverin_plate"), itemstrings.cactus, L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("vaccuum_chest"),
  recipe = {
    {L("silverin_plate"), itemstrings.chest,   L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),     L("silverin_circuit")},
    {L("silverin_plate"), itemstrings.crystal, L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("autocrafter"),
  recipe = {
    {L("silverin_plate"), itemstrings.chest,     L("silverin_plate")},
    {"",                  L("silverin_circuit"), ""},
    {L("silverin_plate"), "",                    L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("crafting_supplier"),
  recipe = {
    {L("silverin_plate"),   itemstrings.chest, L("silverin_plate")},
    {L("silverin_circuit"), L("photonizer"),   L("silverin_circuit")},
    {L("silverin_plate"),   L("optic_cable"),  L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("cobblegen_supplier"),
  recipe = {
    {L("silverin_plate"), itemstrings.lava_bucket,  L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),          L("silverin_circuit")},
    {L("silverin_plate"), itemstrings.water_bucket, L("silverin_plate")},
  },
  replacements = {
    {itemstrings.water_bucket, itemstrings.empty_bucket},
    {itemstrings.lava_bucket,  itemstrings.empty_bucket},
  }
})

minetest.register_craft({
  output = L("wireless_synchronizer"),
  recipe = {
    {L("silverin_plate"),   L("wireless_crystal"), L("silverin_plate")},
    {L("wireless_crystal"), L("silverin_circuit"), L("wireless_crystal")},
    {L("silverin_plate"),   L("wireless_crystal"), L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("reservoir_silverin_empty"),
  recipe = {
    {L("silverin_plate"), "",                    L("silverin_plate")},
    {L("optic_cable"),    L("compression_tank"), L("photonizer")},
    {L("silverin_plate"), "",                    L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("reservoir_obsidian_empty"),
  recipe = {
    {itemstrings.obsidian, L("silverin_plate"),   itemstrings.obsidian},
    {L("optic_cable"),     L("compression_tank"), L("photonizer")},
    {itemstrings.obsidian, L("silverin_plate"),   itemstrings.obsidian},
  }
})

minetest.register_craft({
  output = L("lava_furnace_fueler"),
  recipe = {
    {L("silverin_plate"), itemstrings.clay, L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),  ""},
    {L("silverin_plate"), itemstrings.clay, L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("optic_cable_block"),
  recipe = {
    {L("silverin_plate")},
    {L("optic_cable")},
    {L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("silverin_block"),
  recipe = {
    {L("silverin_plate"), L("silverin_plate"), L("silverin_plate")}
  }
})

minetest.register_craft({
  output = L("silverin_plate 3"),
  type = "shapeless",
  recipe = {
    L("silverin_block")
  }
})

minetest.register_craft({
  output = L("bucket_filler"),
  recipe = {
    {L("silverin_plate"), "",                       L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),          ""},
    {L("silverin_plate"), itemstrings.empty_bucket, L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("bucket_emptier"),
  recipe = {
    {L("silverin_plate"), itemstrings.empty_bucket, L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),          ""},
    {L("silverin_plate"), "",                       L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("pump"),
  recipe = {
    {L("silverin_plate"), itemstrings.empty_bucket, L("silverin_plate")},
    {L("optic_cable"),    itemstrings.crystal ,     L("photonizer")},
    {L("silverin_plate"), L("compression_tank"),    L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("wireless_receiver"),
  recipe = {
    {L("wireless_antenna"),    L("optic_cable"),      L("wireless_antenna")},
    {L("photonizer_reversed"), L("silverin_plate"),   L("photonizer")},
    {"",                       L("silverin_circuit"), ""},
  }
})

minetest.register_craft({
  output = L("wireless_transmitter"),
  recipe = {
    {L("wireless_antenna"),    L("optic_cable"),      L("wireless_antenna")},
    {L("photonizer_reversed"), itemstrings.diamond,   L("photonizer")},
    {L("wireless_antenna"),    L("silverin_circuit"), L("wireless_antenna")},
  }
})
