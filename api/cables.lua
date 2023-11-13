


-- Main function to register a new cable of certain tier
-- customNodeBox  can specify any of the fixed/connect_DIR - values will be overwritten per-item basis
function logistica.register_cable(desc, name, size, customNodeBox)
  local lname = string.lower(name)
  local cable_name = "logistica:" .. lname
  local cable_group = logistica.get_cable_group(lname)
  logistica.cables[cable_name] = name
  logistica.tiers[lname] = true
	local cnb = customNodeBox or {}

  local node_box = {
    type           = "connected",
    fixed          = cnb.fixed          or { -size, -size, -size, size, size, size },
    connect_top    = cnb.connect_top    or { -size, -size, -size, size, 0.5, size }, -- y+
    connect_bottom = cnb.connect_bottom or { -size, -0.5, -size, size, size, size }, -- y-
    connect_front  = cnb.connect_front  or { -size, -size, -0.5, size, size, size }, -- z-
    connect_back   = cnb.connect_back   or { -size, -size, size, size, size, 0.5 }, -- z+
    connect_left   = cnb.connect_left   or { -0.5, -size, -size, size, size, size }, -- x-
    connect_right  = cnb.connect_right  or { -size, -size, -size, 0.5, size, size }, -- x+
  }

  local def = {
    description = desc,
    tiles = { "logistica_" .. lname .. "_cable.png" },
    inventory_image = "logistica_" .. lname .. "_cable_inv.png",
    wield_image = "logistica_" .. lname .. "_cable_inv.png",
    groups = {
      cracky = 3,
      choppy = 3,
      oddly_breakable_by_hand = 2,
      [cable_group] = 1,
    },
    sounds = logistica.node_sound_metallic(),
    drop = cable_name,
    paramtype = "light",
		paramtype2 = "facedir",
    sunlight_propagates = true,
    drawtype = "nodebox",
    node_box = node_box,
    connects_to = { "group:" .. cable_group, "group:"..logistica.get_machine_group(lname), logistica.GROUP_ALL },
    on_construct = function(pos) logistica.on_cable_change(pos, nil) end,
    after_destruct = function(pos, oldnode) logistica.on_cable_change(pos, oldnode) end,
  }

  minetest.register_node(cable_name, def)

  local def_broken = {}
  for k, v in pairs(def) do def_broken[k] = v end
  def_broken.tiles = { "logistica_" .. lname .. "_cable.png^logistica_broken.png" }
  def_broken.inventory_image = "logistica_" .. lname .. "_cable_inv.png^logistica_broken.png"
  def_broken.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 }
  def_broken.description = "Broken " .. desc
  def_broken.node_box = { type = "fixed", fixed = { -0.5, -size, -size, 0.5, size, size } }
  def_broken.selection_box = def_broken.node_box
  def_broken.connects_to = nil
  def_broken.on_construct = nil
  def_broken.after_destruct = nil

  minetest.register_node(cable_name .. "_disabled", def_broken)
end
