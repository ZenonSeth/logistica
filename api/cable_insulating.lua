local S = logistica.TRANSLATOR
local SIZE = logistica.settings.cable_size

-- shape = "straight" (default, group value 1): connects front-to-back only.
-- shape = "l_shape"  (group value 2): connects front arm (z-) and right arm (x+).
-- Network scan enforces the direction; all other faces are insulated.
function logistica.register_insulating_cable(desc, name, customTiles, shape)
  local lname = string.lower(name)
  local cable_name = "logistica:" .. lname
  logistica.GROUPS.cables.register(cable_name)
  local tiles = customTiles or { "logistica_" .. lname .. ".png" }

  local isL = (shape == "l_shape")
  local insulType = isL and 2 or 1

  local node_box
  if isL then
    node_box = {
      type  = "fixed",
      fixed = {
        {-SIZE, -SIZE, -0.5,  SIZE, SIZE,  SIZE},  -- forward arm (z-) + center
        {-SIZE, -SIZE, -SIZE, 0.5,  SIZE,  SIZE},  -- right arm (x+) + center
      },
    }
  else
    node_box = {
      type  = "fixed",
      fixed = {-SIZE, -SIZE, -0.5, SIZE, SIZE, 0.5},
    }
  end

  local def = {
    description = desc,
    tiles = tiles,
    groups = {
      cracky = 3,
      choppy = 3,
      oddly_breakable_by_hand = 2,
      pickaxey = 1,
      axey = 1,
      handy = 1,
      [logistica.TIER_ALL] = 1,
      logistica_insulating = insulType,
    },
    sounds = logistica.node_sound_metallic(),
    drop = cable_name,
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    drawtype = "nodebox",
    node_box = node_box,
    on_construct = function(pos) logistica.on_cable_insulating_change(pos) end,
    after_dig_node = function(pos, oldnode, oldmeta, _) logistica.on_cable_insulating_change(pos, oldnode, oldmeta) end,
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(cable_name, def)
  logistica.register_non_pushable(cable_name)

  local def_broken = {}
  for k, v in pairs(def) do def_broken[k] = v end
  def_broken.tiles = logistica.table_map(tiles, function(s) return s.."^logistica_broken.png" end)
  def_broken.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 2, pickaxey = 1, axey = 1, handy = 1, not_in_creative_inventory = 1 }
  def_broken.description = S("Broken ") .. desc
  def_broken.selection_box = node_box
  def_broken.on_construct = nil
  def_broken.after_dig_node = nil

  minetest.register_node(cable_name .. "_disabled", def_broken)
end
