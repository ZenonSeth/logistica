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
