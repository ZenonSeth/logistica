local S = logistica.TRANSLATOR

logistica.craftitem.storage_upgrade = {}
local items = logistica.craftitem.storage_upgrade

items["logistica:storage_upgrade_1"] = {
  description = S("Silverin Storage Upgrade\nAdds 512 Mass Storage Slot Capacity"),
  storage_upgrade = 512,
  inventory_image = "logistica_storage_upgrade_1.png",
  stack_max = logistica.stack_max,
}

items["logistica:storage_upgrade_2"]= {
  description = S("Diamond Storage Upgrade\nAdds 1024 Mass Storage Slot Capacity"),
  storage_upgrade = 1024,
  inventory_image = "logistica_storage_upgrade_2.png",
  stack_max = logistica.stack_max,
}

items["logistica:leaves_upgrade"] = {
  description = S("Leaves Upgrade\nInsert into a Wood Supplier to also harvest leaves"),
  inventory_image = "logistica_leaves_upgrade.png",
  stack_max = 1,
}

items["logistica:sprinkler_upgrade"] = {
  description = S("Sprinkler Upgrade\nInsert into a Farming Supplier to enable water-assisted growth"),
  inventory_image = "logistica_sprinkler_upgrade.png",
  stack_max = 1,
}

items["logistica:autocrafting_upgrade"] = {
  description = S("Access Point Crafting Upgrade\nInsert into an Access Point to enable autocrafting"),
  inventory_image = "logistica_autocrafting_upgrade.png",
  stack_max = 1,
}

items["logistica:autocrafting_recursive_upgrade"] = {
  description = S("Recursive Crafting Upgrade\nInsert into an Access Point to enable autocrafting and recursive crafting"),
  inventory_image = "logistica_autocrafting_recursive_upgrade.png",
  stack_max = 1,
}

items["logistica:storage_upgrade_multiplier"] = {
  description = S("Mass Storage Capacity Multiplier\nMultiplies Mass Storage Slot Capacity by 16\nOnly 1 can be inserted per Mass Storage"),
  storage_multiplier = 16,
  inventory_image = "logistica_storage_upgrade_multiplier.png",
  stack_max = logistica.stack_max,
}

--------------------------------
-- registration
--------------------------------

for name, info in pairs(items) do
  minetest.register_craftitem(name, {
    description = info.description,
    inventory_image = info.inventory_image,
    stack_max = info.stack_max,
  })
end
