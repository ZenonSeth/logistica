local S = logistica.TRANSLATOR
local L = function(str) return "logistica:"..str end

logistica.craftitem.general = {}
local items = logistica.craftitem.general

items[L("lava_unit")] = {
  description = S("A Unit of Lava\nUse in Lava Furnace or with Empty Bucket"),
  inventory_image = "logistica_lava_unit.png",
  stack_max = 1,
}

items[L("silverin_slice")] = {
  description = S("Silverin Slice"),
  inventory_image = "logistica_silverin_slice.png",
  stack_max = logistica.stack_max,
}

items[L("silverin_circuit")] = {
  description = S("Silverin Circuit"),
  inventory_image = "logistica_silverin_circuit.png",
  stack_max = logistica.stack_max,
}

items[L("silverin_mirror_box")] = {
  description = S("Silverin Mirror Box"),
  inventory_image = "logistica_silverin_mirror_box.png",
  stack_max = logistica.stack_max,
}

items[L("photonizer")] = {
  description = S("Photonizer\nE = M*C^2"),
  inventory_image = "logistica_photonizer.png",
  stack_max = logistica.stack_max,
}

items[L("photonizer_reversed")] = {
  description = S("Photonizer (Reversed Polarity)\nM = E/C^2"),
  inventory_image = "logistica_photonizer_reversed.png",
  stack_max = logistica.stack_max,
}

items[L("standing_wave_box")] = {
  description = S("Wave Function Maintainer"),
  inventory_image = "logistica_standing_wave_box.png",
  stack_max = logistica.stack_max,
}

items[L("cobblegen_upgrade")] = {
  description = S("Cobble Generator Upgrade\nIncreases Cobble Generator Output"),
  inventory_image = "logistica_cobblegen_upgrade.png",
  stack_max = 4,
}

items[L("wireless_crystal")] = {
  description = S("Wireless Crystal\nFor use in a Wireless Upgrader"),
  inventory_image = "logistica_wireless_crystal.png",
  stack_max = logistica.stack_max,
}

items[L("compression_tank")] = {
  description = S("Compression Tank\nStores liquids at high pressure. Used for making Reservoirs."),
  inventory_image = "logistica_compression_tank.png",
  stack_max = logistica.stack_max,
}

items[L("wireless_antenna")] = {
  description = S("Wireless Antenna"),
  inventory_image = "logistica_wireless_antenna.png",
  stack_max = 8,
}

for name, info in pairs(items) do
  minetest.register_craftitem(name, {
    description = info.description,
    inventory_image = info.inventory_image,
    stack_max = info.stack_max,
  })
end
