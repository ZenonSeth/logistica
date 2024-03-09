local itemstrings = logistica.itemstrings
local L  = function(str) return "logistica:"..str end

logistica.register_lava_furnace_recipe(itemstrings.sand, {
  output = L("silverin"),
  lava = 25,
  additive = itemstrings.ice,
  additive_use_chance = 50,
  time = 2.5
})

logistica.register_lava_furnace_recipe(L("silverin"), {
  output = L("silverin_plate 4"),
  lava = 50,
  additive = itemstrings.steel,
  additive_use_chance = 100,
  time = 5
})

logistica.register_lava_furnace_recipe(L("silverin_slice"), {
  output = L("silverin_circuit"),
  lava = 60,
  additive = itemstrings.fragment,
  additive_use_chance = 100,
  time = 10
})

logistica.register_lava_furnace_recipe(itemstrings.glass, {
  output = L("silverin_mirror_box"),
  lava = 50,
  additive = L("silverin_slice 6"),
  additive_use_chance = 100,
  time = 4
})

logistica.register_lava_furnace_recipe(L("silverin"), {
  output = L("wireless_crystal"),
  lava = 60,
  additive = itemstrings.crystal,
  additive_use_chance = 100,
  time = 12
})
