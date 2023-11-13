local S = logistica.TRANSLATOR

logistica.craftitem.nodes = {}
local items = logistica.craftitem.nodes

local crystalGroups = {
  oddly_breakable_by_hand = 1, cracky = 3
}

local sounds = default.node_sound_glass_defaults()

items["logistica:silverin"] = {
  tiles = {
		"logistica_silverin_nodebox.png",
		"logistica_silverin_nodebox.png",
		"logistica_silverin_nodebox.png^[transformFX",
		"logistica_silverin_nodebox.png^[transformFX",
		"logistica_silverin_nodebox.png",
		"logistica_silverin_nodebox.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.50, -0.25, 0.25, 0.50, 0.25}
		}
	},
  use_texture_alpha = "blend",
  groups = crystalGroups,
  sounds = sounds,
  description = S("Silverin Crystal"),
  inventory_image = "logistica_silverin.png",
  stack_max = 99,
}

items["logistica:silverin_plate"] = {
  tiles = { "logistica_silverin_plate.png" },
	drawtype = "nodebox",
	paramtype = "light",
  paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.50, -0.50, -0.50, 0.50, -7/16, 0.50}
		}
	},
  groups = { cracky = 2 },
  sounds = logistica.node_sound_metallic(),
  description = S("Silverin Plate"),
  inventory_image = "logistica_silverin_plate_inv.png",
  stack_max = 99,
}

-- items["logistica:silverin_block"] = {
--   description = S("Silverin Block"),
--   tiles = "logistica_silverin_plate.png",
--   stack_max = 99,
-- }

for name, def in pairs(items) do
  minetest.register_node(name, def)
end