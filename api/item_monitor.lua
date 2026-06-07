
function logistica.register_item_monitor(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local def = {
    description = desc,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    node_box = {
      type = "fixed",
      fixed = {
        {-8/16, -8/16, -8/16,  8/16, -7/16,  8/16}, -- base
        {-1/16, -7/16,  3/16,  1/16,  1/16,  8/16}, -- vertical stand
        {-1/16,  1/16, -6/16,  1/16,  3/16,  8/16}, -- horizontal arm
        {-7/16, -6/16, -8/16,  7/16,  7/16, -6/16}, -- monitor panel
      }
    },
    is_ground_content = false,
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = logistica.item_monitor_after_place,
    after_dig_node   = logistica.on_item_monitor_change,
    on_rightclick    = logistica.item_monitor_on_rightclick,
    on_timer         = logistica.item_monitor_timer,
    allow_metadata_inventory_put  = logistica.item_monitor_allow_inv_put,
    allow_metadata_inventory_take = logistica.item_monitor_allow_inv_take,
    allow_metadata_inventory_move = logistica.item_monitor_allow_inv_move,
    logistica = {
      on_connect_to_network      = logistica.item_monitor_on_connect,
      on_disconnect_from_network = logistica.item_monitor_on_disconnect,
      on_power                   = logistica.item_monitor_on_power,
    },
    _mcl_hardness         = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(lname, def)
  logistica.register_non_pushable(lname)
  logistica.GROUPS.misc_machines.register(lname)
end
