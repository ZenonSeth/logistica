
minetest.register_craftitem("logistica:network_tool",{
  description = "Logistica Network Tool\nUse on a node to see network info",
  inventory_image = "logistica_network_tool.png",
  wield_image = "logistica_network_tool.png",
  stack_max = 1,
  on_place = function(itemstack, placer, pointed_thing)
    local pos = pointed_thing.under
    if not placer or not pos then return end
    local node = minetest.get_node_or_nil(pos)
    if not node or node.name:find("logistica:") == nil then return end
    local network = logistica.get_network_name_or_nil(pos) or "<NONE>"
    -- minetest.chat_send_player(placer:get_player_name(), "Network: "..network)
    logistica.show_short_popup(
      placer:get_player_name(), 
      "("..pos.x..","..pos.y..","..pos.z..") Network: "..network
    )
  end
})