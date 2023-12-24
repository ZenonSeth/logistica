local function L(s) return "logistica:"..s end

minetest.register_craft({
  output = L("lava_furnace"),
  recipe = {
    {"default:clay",        "default:obsidianbrick", "default:clay"},
    {"default:steel_ingot", "bucket:bucket_empty",   "default:steel_ingot"},
    {"default:steel_ingot", "bucket:bucket_empty",   "default:steel_ingot"},
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
    {L("silverin_plate"), "default:chest", L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"), L("silverin_circuit")},
    {L("silverin_plate"), "",              L("silverin_plate")},
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
    {L("silverin_plate"), L("silverin_circuit"),   L("silverin_plate")},
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
    {L("silverin_plate"), L("optic_cable"), L("silverin_plate")},
    {"",                  "",               ""},
    {L("silverin_plate"), "default:cactus", L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("vaccuum_chest"),
  recipe = {
    {L("silverin_plate"), "default:chest",        L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),        L("silverin_circuit")},
    {L("silverin_plate"), "default:mese_crystal", L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("autocrafter"),
  recipe = {
    {L("silverin_plate"), "default:chest",        L("silverin_plate")},
    {"",                  L("silverin_circuit"),  ""},
    {L("silverin_plate"), "",                     L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("crafting_supplier"),
  recipe = {
    {L("silverin_plate"),   "default:chest",  L("silverin_plate")},
    {L("silverin_circuit"), L("photonizer"),  L("silverin_circuit")},
    {L("silverin_plate"),   L("optic_cable"), L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("cobblegen_supplier"),
  recipe = {
    {L("silverin_plate"), "bucket:bucket_lava",  L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),       L("silverin_circuit")},
    {L("silverin_plate"), "bucket:bucket_water", L("silverin_plate")},
  },
  replacements = {
    {"bucket:bucket_water", "bucket:bucket_empty"},
    {"bucket:bucket_lava",  "bucket:bucket_empty"},
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
    {L("optic_cable"),    "bucket:bucket_empty", L("photonizer")},
    {L("silverin_plate"), "",                    L("silverin_plate")},
  }
})

minetest.register_craft({
  output = L("reservoir_obsidian_empty"),
  recipe = {
    {"default:obsidianbrick", L("silverin_plate"),   "default:obsidianbrick"},
    {L("optic_cable"),        "bucket:bucket_empty", L("photonizer")},
    {"default:obsidianbrick", L("silverin_plate"),   "default:obsidianbrick"},
  }
})

minetest.register_craft({
  output = L("lava_furnace_fueler"),
  recipe = {
    {L("silverin_plate"), "default:clay",  L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"), ""},
    {L("silverin_plate"), "default:clay",  L("silverin_plate")},
  }
})
