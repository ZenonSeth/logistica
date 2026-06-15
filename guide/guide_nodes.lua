local S = logistica.TRANSLATOR
local GUIDE_NAME = "logistica_guide"

local function show_guide_node(_, _, clicker)
  if clicker and clicker:is_player() then
    logistica.GuideApi.show_guide(clicker:get_player_name(), GUIDE_NAME)
  end
end

local function toggle_to_open(pos, node)
  minetest.set_node(pos, { name = "logistica:guide_open", param2 = node.param2 })
end

local function toggle_to_closed(pos, node)
  minetest.set_node(pos, { name = "logistica:guide_closed", param2 = node.param2 })
end

local function book_facedir(look)
  local x, y, z = look.x, look.y, look.z
  local ax, ay, az = math.abs(x), math.abs(y), math.abs(z)
  if ay > ax and ay > az then
    -- looking mostly vertical: bottom faces +/-Y, secondary horizontal dir sets rotation
    local base = (y > 0) and 20 or 0
    if ax >= az and ax > 0 then
      return base + ((x > 0) and 1 or 3)
    elseif az > 0 then
      return base + ((z > 0) and 0 or 2)
    end
    return base  -- looking straight up/down: default rotation
  elseif ax > az then
    return (x > 0) and 17 or 15
  else
    return (z > 0) and 8 or 6
  end
end

local function book_after_place(pos, placer)
  if not placer or not placer:is_player() then return end
  local node = minetest.get_node(pos)
  node.param2 = book_facedir(placer:get_look_dir())
  minetest.swap_node(pos, node)
end

local book_light = 1
local book_groups = { oddly_breakable_by_hand = 3, book = 1 }
local book_groups_closed = { oddly_breakable_by_hand = 3, book = 1, not_in_creative_inventory = 1 }

local closed_tiles = {
  "logistica_guide_book_closed_top.png",    -- top (+Y): cover
  "logistica_guide_book_closed_bottom.png",    -- bottom (-Y)
  "logistica_guide_book_closed_side.png",   -- right (+X)
  "logistica_guide_book_closed_spine.png",   -- left (-X)
  "logistica_guide_book_closed_topside.png^[transformFX",  -- back (+Z)
  "logistica_guide_book_closed_topside.png",  -- front (-Z)
}

local open_tiles = {
  "logistica_guide_book_open_top.png",    -- top (+Y): open pages
  "logistica_guide_book_open_bottom.png",    -- bottom (-Y)
  "logistica_guide_book_open_side.png",   -- right (+X): page edges
  "logistica_guide_book_open_side.png",   -- left (-X): page edges
  "logistica_guide_book_open_side.png",  -- back (+Z): spine end
  "logistica_guide_book_open_side.png",  -- front (-Z): spine end
}

local closed_nodebox = {
  type = "fixed",
  fixed = {
    { -7/32, -12/32, -9/32,  7/32, -11/32,  9/32 },  -- top cover (1/32)
    { -7/32, -16/32, -9/32,  7/32, -15/32,  9/32 },  -- bottom cover (1/32)
    { -6/32, -15/32, -8/32,  6/32, -12/32,  8/32 },  -- pages (flush at -X spine, inset 1/32 on +X and both Z ends)
    { -7/32, -16/32, -9/32, -6/32, -11/32,  9/32 },  -- spine (1/32 thick on -X edge)
  },
}

local open_nodebox = {
  type = "fixed",
  fixed = {
    { -15/32, -16/32, -9/32, 15/32, -15/32,  9/32 },  -- cover/base (1/32 thick)
    { -14/32, -15/32, -8/32,  -1/32, -13/32,  8/32 },  -- left page
    {   1/32, -15/32, -8/32,  14/32, -13/32,  8/32 },  -- right page
  },
}

minetest.register_node("logistica:guide_closed", {
  description = S("Logistica Guide Book (closed)"),
  tiles = closed_tiles,
  groups = book_groups_closed,
  paramtype = "light",
  paramtype2 = "facedir",
  drawtype = "nodebox",
  node_box = closed_nodebox,
  selection_box = { type = "fixed", fixed = { -7/32, -16/32, -9/32, 7/32, -11/32, 9/32 } },
  light_source = book_light,
  drop = "logistica:guide_open",
  sounds = logistica.sound_mod.node_sound_defaults(),
  after_place_node = book_after_place,
  on_rightclick = show_guide_node,
  on_punch = toggle_to_open,
})

minetest.register_node("logistica:guide_open", {
  description = S("Logistica Guide Book"),
  tiles = open_tiles,
  groups = book_groups,
  paramtype = "light",
  paramtype2 = "facedir",
  drawtype = "nodebox",
  node_box = open_nodebox,
  selection_box = { type = "fixed", fixed = { -14/32, -16/32, -8/32, 14/32, -13/32, 8/32 } },
  light_source = book_light,
  drop = "logistica:guide_open",
  sounds = logistica.sound_mod.node_sound_defaults(),
  after_place_node = book_after_place,
  on_rightclick = show_guide_node,
  on_secondary_use = function(_, user, _) show_guide_node(nil, nil, user) end,
  on_punch = toggle_to_closed,
})
