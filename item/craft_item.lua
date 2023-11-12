local S = logistica.TRANSLATOR

logistica.craftitem.general = {}
local items = logistica.craftitem.general

items["logistica:silverin_slice"] = {
  description = S("Silverin Slice"),
  inventory_image = "logistica_silverin_slice.png",
  stack_max = 99,
}

-- items["logistica:silverin_photonizer"] = {
--   description = S("Silverin Phonizer"),
--   inventory_image = "logistica_silverin_slice.png",
--   stack_max = 99,
-- }

-- items["logistica:silverin_wavebox"] = {
--   description = S("Standing-Wave State Maintainer"),
--   inventory_image = "logistica_silverin_slice.png",
--   stack_max = 99,
-- }

for name, info in pairs(items) do
  minetest.register_craftitem(name, {
    description = info.description,
    inventory_image = info.inventory_image,
    stack_max = info.stack_max,
  })
end
