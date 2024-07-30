local S = logistica.TRANSLATOR

minetest.register_tool("logistica:wand",{
  description = S("Inv List Scanner"),
  inventory_image = "logistica_wand.png",
  wield_image = "logistica_wand.png",
  stack_max = 1,
  on_place = function(itemstack, placer, pointed_thing)
    local pos = pointed_thing.under
    if not placer or not pos then return end
    local inv = minetest.get_meta(pos):get_inventory()

    local lists = inv:get_lists()
    local names = ""
    for name, _ in pairs(lists) do
      names = names..name..", "
    end

    logistica.show_popup(placer:get_player_name(), names)
  end
})
