-- mostly decorative things that don't fit anywhere else
local S = logistica.TRANSLATOR
local function L(s) return "logistica:"..s end

minetest.register_node(L("silverin_block"), {
  drawtype = "normal",
  description = S("Silverin Block"),
  tiles = {"logistica_silverin_plate.png"},
  paramtype2 = "facedir",
  groups = { cracky = 2, pickaxey = 2 },
  sounds = logistica.node_sound_metallic(),
  stack_max = logistica.stack_max,
  _mcl_hardness = 1.5,
  _mcl_blast_resistance = 40
})
