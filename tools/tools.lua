local S = logistica.TRANSLATOR

minetest.register_craftitem("logistica:hyperspanner",{
  description = S("Hyperspanner\nA multipurpose engineering tool\nUse on nodes for network info.\nCan also reverse poliarity."),
  short_description = S("Hyperspanner"),
  inventory_image = "logistica_hyperspanner.png",
  wield_image = "logistica_hyperspanner.png",
  stack_max = 1,
  on_place = function(itemstack, placer, pointed_thing)
    local pos = pointed_thing.under
    if not placer or not pos then return end
    local node = minetest.get_node_or_nil(pos)
    if not node or node.name:find("logistica:") == nil then return end
    local network = logistica.get_network_name_or_nil(pos) or S("<NONE>")
    logistica.show_popup(
      placer:get_player_name(), 
      "("..pos.x..","..pos.y..","..pos.z..") "..S("Network")..": "..network
    )
  end
})

minetest.register_craftitem("logistica:wand",{
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
