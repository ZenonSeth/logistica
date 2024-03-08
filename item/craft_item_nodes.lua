local S = logistica.TRANSLATOR

logistica.craftitem.nodes = {}
local items = logistica.craftitem.nodes

local crystalGroups = {
  oddly_breakable_by_hand = 1, cracky = 3
}

local sounds = logistica.sound_mod.node_sound_glass_defaults()

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
  wield_image = "logistica_silverin_plate_inv.png",
  stack_max = 99,
  after_place_node = function(pos, placer, itemstack, pointed_thing)
    local rotNeeded = true
    local node = minetest.get_node(pos)
    if pointed_thing.type == "node" then
      local pointedNode = minetest.get_node(pointed_thing.under)
      if pointedNode.name == "logistica:silverin_plate" then
        node.param2 = pointedNode.param2
        minetest.swap_node(pos, node)
        rotNeeded = false
      end
    end
    if rotNeeded then
      if placer:is_player() then
        local lookDir = placer:get_look_dir()
        if placer:get_player_control().sneak then
          lookDir = vector.multiply(lookDir, -1)
        end
        node.param2 = logistica.dir_to_facedir(lookDir)
        minetest.swap_node(pos, node)
      end
    end
  end,
}

-- items["logistica:silverin_block"] = {
--   description = S("Silverin Block"),
--   tiles = "logistica_silverin_plate.png",
--   stack_max = 99,
-- }

for name, def in pairs(items) do
  minetest.register_node(name, def)
end