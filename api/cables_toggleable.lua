
local SIZE = 1/16

local function ends_with(str, ending)
  return str:sub(-#ending) == ending
end

local function toggle_cable(pos, node, clicker, itemstack, pointed_thing)
  if clicker:is_player() and minetest.is_protected(pos, clicker:get_player_name()) then return end
  local nodeName = node.name
  if ends_with(nodeName, "_on") then
    nodeName = nodeName:sub(1, #nodeName - 3).."_off"
    logistica.swap_node(pos, nodeName)
    logistica.on_cable_change(pos, nil, false)
  elseif ends_with(nodeName, "_off") then
    nodeName = nodeName:sub(1, #nodeName - 4).."_on"
    logistica.swap_node(pos, nodeName)
    logistica.on_cable_change(pos, nil, true)
  end
end

-- Main function to register a new toggleable cable
function logistica.register_cable_toggleable(desc, name, tilesOn, tilesOff)
  local lname = string.lower(name)
  local nameOff = "logistica:"..lname.."_off"

  for _, state in ipairs({"on", "off"}) do

    local node_box = {
      type           = "connected",
      fixed          = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
      connect_top    = { -SIZE, -SIZE, -SIZE, SIZE, 0.5,  SIZE }, -- y+
      connect_bottom = { -SIZE, -0.5,  -SIZE, SIZE, SIZE, SIZE }, -- y-
      connect_front  = { -SIZE, -SIZE, -0.5,  SIZE, SIZE, SIZE }, -- z-
      connect_back   = { -SIZE, -SIZE,  SIZE, SIZE, SIZE, 0.5  }, -- z+
      connect_left   = { -0.5,  -SIZE, -SIZE, SIZE, SIZE, SIZE }, -- x-
      connect_right  = { -SIZE, -SIZE, -SIZE, 0.5,  SIZE, SIZE }, -- x+
    }

    local cable_name = "logistica:"..lname.."_"..state
    local connectsTo = { logistica.GROUP_ALL }
    local tiles = tilesOn
    local onConst = function(p) logistica.on_cable_change(p, nil) end
    local onDest = function(p, oldnode) logistica.on_cable_change(p, oldnode) end
    if state == "off" then
      tiles = tilesOff
      connectsTo = {}
      onConst = nil
      onDest = nil
    end

    local def = {
      description = desc,
      tiles = tiles,
      -- inventory_image = "logistica_" .. lname .. "_inv.png",
      -- wield_image = "logistica_" .. lname .. "_inv.png",
      groups = {
        cracky = 3,
        choppy = 3,
        oddly_breakable_by_hand = 2,
      },
      sounds = logistica.node_sound_metallic(),
      drop = nameOff,
      paramtype = "light",
      paramtype2 = "facedir",
      sunlight_propagates = true,
      drawtype = "nodebox",
      node_box = node_box,
      connects_to = connectsTo,
      on_construct = onConst,
      after_destruct = onDest,
      on_rightclick = toggle_cable,
    }

    if state == "on" then
      logistica.cables[cable_name] = name
      def.groups[logistica.TIER_ALL] = 1
      def.groups.not_in_creative_inventory = 1
    end

    minetest.register_node(cable_name, def)

    local def_broken = table.copy(def)
    def_broken.tiles = logistica.table_map(tiles, function(s) return s.."^logistica_broken.png" end)
    -- def_broken.inventory_image = "logistica_" .. lname .. "_inv.png^logistica_broken.png"
    def_broken.groups = { cracky = 3, choppy = 3, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 }
    def_broken.description = "Broken " .. desc
    def_broken.node_box = { type = "fixed", fixed = { -0.5, -SIZE, -SIZE, 0.5, SIZE, SIZE } }
    def_broken.selection_box = def_broken.node_box
    def_broken.connects_to = nil
    def_broken.on_construct = nil
    def_broken.after_destruct = nil
    def_broken.on_rightclick = nil

    minetest.register_node(cable_name .. "_disabled", def_broken)
  end
end
