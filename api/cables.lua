
local SIZE = logistica.settings.cable_size

-- Main function to register a new cable of certain tier
-- customNodeBox  can specify any of the fixed/connect_DIR - values will be overwritten per-item basis
function logistica.register_cable(desc, name, customNodeBox)
  local lname = string.lower(name)
  local cable_name = "logistica:" .. lname
  local cable_group = logistica.TIER_ALL
  logistica.cables[cable_name] = name
	local cnb = customNodeBox or {}

  local node_box = {
    type           = "connected",
    fixed          = cnb.fixed          or { -SIZE, -SIZE, -SIZE, SIZE, SIZE, SIZE },
    connect_top    = cnb.connect_top    or { -SIZE, -SIZE, -SIZE, SIZE, 0.5,  SIZE }, -- y+
    connect_bottom = cnb.connect_bottom or { -SIZE, -0.5,  -SIZE, SIZE, SIZE, SIZE }, -- y-
    connect_front  = cnb.connect_front  or { -SIZE, -SIZE, -0.5,  SIZE, SIZE, SIZE }, -- z-
    connect_back   = cnb.connect_back   or { -SIZE, -SIZE,  SIZE, SIZE, SIZE, 0.5  }, -- z+
    connect_left   = cnb.connect_left   or { -0.5,  -SIZE, -SIZE, SIZE, SIZE, SIZE }, -- x-
    connect_right  = cnb.connect_right  or { -SIZE, -SIZE, -SIZE, 0.5,  SIZE, SIZE }, -- x+
  }

  local def = {
    description = desc,
    tiles = { "logistica_" .. lname .. ".png" },
    inventory_image = "logistica_" .. lname .. "_inv.png",
    wield_image = "logistica_" .. lname .. "_inv.png",
    groups = {
      cracky = 3,
      choppy = 3,
      oddly_breakable_by_hand = 2,
      pickaxey = 1,
      axey = 1,
      handy = 1,
      [cable_group] = 1,
    },
    sounds = logistica.node_sound_metallic(),
    drop = cable_name,
    paramtype = "light",
		paramtype2 = "facedir",
    sunlight_propagates = true,
    drawtype = "nodebox",
    node_box = node_box,
    connects_to = { "group:" .. cable_group, logistica.GROUP_ALL, logistica.GROUP_CABLE_OFF },
    on_construct = function(pos) logistica.on_cable_change(pos) end,
    after_dig_node = function(pos, oldnode, oldmeta, _) logistica.on_cable_change(pos, oldnode, oldmeta) end,
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10
  }

  minetest.register_node(cable_name, def)

  local def_broken = {}
  for k, v in pairs(def) do def_broken[k] = v end
  def_broken.tiles = { "logistica_" .. lname .. ".png^logistica_broken.png" }
  def_broken.inventory_image = "logistica_" .. lname .. "_inv.png^logistica_broken.png"
  def_broken.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 2, pickaxey = 1, axey = 1, handy = 1, not_in_creative_inventory = 1 }
  def_broken.description = "Broken " .. desc
  def_broken.node_box = { type = "fixed", fixed = { -0.5, -SIZE, -SIZE, 0.5, SIZE, SIZE } }
  def_broken.selection_box = def_broken.node_box
  def_broken.connects_to = nil
  def_broken.on_construct = nil
  def_broken.after_dig_node = nil

  minetest.register_node(cable_name .. "_disabled", def_broken)
end
