local SIZE = logistica.settings.cable_size

local itemstrings = logistica.itemstrings
--------------------------------
-- Access Point
--------------------------------

logistica.register_access_point("Access Point", "access_point", {
      "logistica_access_point_top.png",
      "logistica_access_point_bottom.png",
      "logistica_access_point_side.png^[transformFX",
      "logistica_access_point_side.png",
      "logistica_access_point_back.png",
      "logistica_access_point_front.png",
})

--------------------------------
-- Autocrafter
--------------------------------

logistica.register_autocrafter("Autocrafter", "autocrafter", {
  "logistica_autocrafter.png"
})

--------------------------------
-- Bucket Emptier
--------------------------------

logistica.register_bucket_emptier("Bucket Emptier", "bucket_emptier", {
  "logistica_bucket_emptier_top.png",
  "logistica_bucket_emptier_top.png",
  "logistica_bucket_emptier_side.png",
})

--------------------------------
-- Bucket Filler
--------------------------------

logistica.register_bucket_filler("Bucket Filler", "bucket_filler", {
  "logistica_bucket_filler_top.png",
  "logistica_bucket_filler_top.png",
  "logistica_bucket_filler_side.png",
})

--------------------------------
-- Cables
--------------------------------

-- regular
logistica.register_cable("Optic Cable", "optic_cable")

-- full-block cable
logistica.register_cable("Embedded Optic Cable", "optic_cable_block",
  {
    type = "normal",
    fixed = {
      { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    connect_top = {}, connect_bottom = {},
    connect_front = {}, connect_back = {},
    connect_left = {}, connect_right = {},
  },
  {
    "logistica_silverin_plate.png^logistica_cable_connection_overlay.png"
  },
  -1
)

-- toggleable
logistica.register_cable_toggleable("Toggleable Cable", "optic_cable_toggleable",
  {"logistica_cable_toggleable_on.png"},
  {"logistica_cable_toggleable_off.png"}
)

--------------------------------
-- Cobble Generator
--------------------------------

logistica.register_cobble_generator_supplier("Cobble Generator", "cobblegen_supplier", {
  "logistica_cobblegen_top.png",
  "logistica_cobblegen_bottom.png",
  "logistica_cobblegen_side.png^[transformFX",
  "logistica_cobblegen_side.png",
  "logistica_cobblegen_back.png",
  "logistica_cobblegen_front.png",
})

--------------------------------
-- Controller
--------------------------------

logistica.register_controller("simple_controller", {
  description = "Logistic Network Controller",
  paramtype = "none",
  paramtype2 = "facedir",
  sunlight_propagates = false,
  light_source = 3,
  tiles = {
      "logistica_network_controller_top.png",
      "logistica_network_controller_top.png^[transformFY",
      "logistica_network_controller_side.png^[transformFX",
      "logistica_network_controller_side.png",
      "logistica_network_controller_side.png",
      {
        image = "logistica_network_controller_front_anim.png",
        backface_culling = false,
        animation = {
          type = "vertical_frames",
          aspect_w = 16,
          aspect_h = 16,
          length = 4.0
        },
      }
  },-- ^logistica_disabled.png
  tiles_disabled = {
    "logistica_network_controller_top.png^logistica_disabled.png",
    "logistica_network_controller_top.png^logistica_disabled.png^[transformFY",
    "logistica_network_controller_side.png^logistica_disabled.png^[transformFX",
    "logistica_network_controller_side.png^logistica_disabled.png",
    "logistica_network_controller_side.png^logistica_disabled.png",
    "logistica_network_controller_front_off.png"
  },
  connect_sides = {"top", "bottom", "left", "back", "right" },
  groups = { oddly_breakable_by_hand = 1, cracky = 2, handy = 1, pickaxey = 2 },
  sounds = logistica.node_sound_metallic(),
  drawtype = "normal",
  node_box = { type = "regular"},
  _mcl_hardness = 3,
  _mcl_blast_resistance = 15
})

--------------------------------
-- Crafting Supplier
--------------------------------

logistica.register_crafting_supplier("Crafting Supplier", "crafting_supplier", {
  "logistica_crafting_supplier_top.png",
  "logistica_crafting_supplier_bottom.png",
  "logistica_crafting_supplier_side.png",
})

--------------------------------
-- Network Importer
--------------------------------

local function imp_tiles(name) return {
  "logistica_"..name.."_injector_side.png^[transformR270",
  "logistica_"..name.."_injector_side.png^[transformR90",
  "logistica_"..name.."_injector_side.png^[transformR180",
  "logistica_"..name.."_injector_side.png",
  "logistica_"..name.."_injector_back.png",
  "logistica_"..name.."_injector_front.png",
} end

logistica.register_injector("Slow Network Importer\nImports 10 items at a time", "injector_slow", 10, imp_tiles("item"))
logistica.register_injector("Fast Network Importer\nImports 99 items at a time", "injector_fast", 99, imp_tiles("stack"))

--------------------------------
-- Item Storage
--------------------------------

logistica.register_item_storage("Tool Chest\nStores Tools Only", "item_storage", {
      "logistica_tool_chest_top.png",
      "logistica_tool_chest_bottom.png",
      "logistica_tool_chest_side.png^[transformFX",
      "logistica_tool_chest_side.png",
      "logistica_tool_chest_back.png",
      "logistica_tool_chest_front.png",
})

--------------------------------
-- Lava Furnace
--------------------------------

logistica.register_lava_furnace("Lava Furnace", "lava_furnace", 4, {
  inactive = {
    "logistica_lava_furnace_side.png", "logistica_lava_furnace_side.png",
    "logistica_lava_furnace_side.png", "logistica_lava_furnace_side.png",
    "logistica_lava_furnace_side.png", "logistica_lava_furnace_front_off.png"
  },
  active = {
    "logistica_lava_furnace_side.png", "logistica_lava_furnace_side.png",
    "logistica_lava_furnace_side.png", "logistica_lava_furnace_side.png",
    "logistica_lava_furnace_side.png",
    {
      image = "logistica_lava_furnace_front_on_anim.png",
      backface_culling = false,
      animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 1.5
      },
    }
  }
})

--------------------------------
-- Lava Furnace Fueler
--------------------------------

logistica.register_lava_furnace_fueler("Lava Furnace Fueler", "lava_furnace_fueler", {
  "logistica_fueler_side.png^[transformR270",
  "logistica_fueler_side.png^[transformR90",
  "logistica_fueler_side.png^[transformR180",
  "logistica_fueler_side.png",
  "logistica_fueler_back.png",
  "logistica_fueler_front.png",
})

--------------------------------
-- Liquid Pump
--------------------------------

logistica.register_pump("Liquid Pump", "pump",
  {
    "logistica_pump_top.png", "logistica_pump_bottom.png", "logistica_pump_side.png"
  },
  { "logistica_pump_top.png", "logistica_pump_bottom.png", {
    image = "logistica_pump_side_on.png",
    backface_culling = false,
    animation = {
      type = "vertical_frames",
      aspect_w = 16,
      aspect_h = 16,
      length = 1
    },
    }
}
)

--------------------------------
-- Mass Storage
--------------------------------

logistica.register_mass_storage("mass_storage_basic", "Mass Storage", 8, 1024, 4, { 
  "logistica_basic_mass_storage_top.png", "logistica_basic_mass_storage_top.png",
  "logistica_basic_mass_storage.png", "logistica_basic_mass_storage.png",
  "logistica_basic_mass_storage.png", "logistica_basic_mass_storage_front.png"
})

--------------------------------
-- Request Inserter
--------------------------------

local function ins_tiles(lname) return {
  "logistica_"..lname.."_requester_side.png^[transformR270",
  "logistica_"..lname.."_requester_side.png^[transformR90",
  "logistica_"..lname.."_requester_side.png^[transformR180",
  "logistica_"..lname.."_requester_side.png",
  "logistica_"..lname.."_requester_back.png",
  "logistica_"..lname.."_requester_front.png",
} end

logistica.register_requester("Item Request Inserter\nInserts 1 item at a time", "requester_item", 1, ins_tiles("item"))
logistica.register_requester("Bulk Request Inserter\nInserts up to 64 items at a time", "requester_stack", 64, ins_tiles("stack"))

--------------------------------
-- Reservoirs
--------------------------------

local mcla = minetest.get_game_info().id == "mineclonia"
local mcl2 = minetest.get_game_info().id == "mineclone2"

local lava_texture = "default_lava.png"
local water_texture = "default_water.png"
local river_water_texture = "default_river_water.png"

if mcla then
  lava_texture = "default_lava_source_animated.png^[sheet:1x16:0,0"
  water_texture = "default_water_source_animated.png^[sheet:1x16:0,0"
  river_water_texture = "default_river_water_source_animated.png^[sheet:1x16:0,0"
elseif mcl2 then
  lava_texture = "mcl_core_lava_source_animation.png^[sheet:1x16:0,0"
  water_texture = "mcl_core_water_source_animation.png^[sheet:1x16:0,0^[multiply:#3F76E4"
  river_water_texture = "mcl_core_water_source_animation.png^[sheet:1x16:0,0^[multiply:#0084FF"
end

logistica.register_reservoir("lava", "Lava", itemstrings.lava_bucket, lava_texture, itemstrings.lava_source, 8)
logistica.register_reservoir("water", "Water", itemstrings.water_bucket, water_texture, itemstrings.water_source)
logistica.register_reservoir("river_water", "River Water", itemstrings.river_water_bucket, river_water_texture, itemstrings.river_water_source)
-- milk buckets
if minetest.registered_items["mcl_mobitems:milk_bucket"] then
  logistica.register_reservoir("milk", "Milk", "mcl_mobitems:milk_bucket", "logistica_milk_liquid.png")
end
if minetest.registered_items["animalia:bucket_milk"] then
  logistica.register_reservoir("milk", "Milk", "animalia:bucket_milk", "logistica_milk_liquid.png")
end
if minetest.registered_items["ethereal:bucket_cactus"] then
  logistica.register_reservoir("cactus_pulp", "Cactus Pulp", "ethereal:bucket_cactus", "logistica_milk_liquid.png^[colorize:#697600:227")
end

--------------------------------
-- Passive Supply Chest
--------------------------------

logistica.register_supplier("Passive Supplier Chest", "passive_supplier", 16, {
      "logistica_passive_supplier_top.png",
      "logistica_passive_supplier_bottom.png",
      "logistica_passive_supplier_side.png^[transformFX",
      "logistica_passive_supplier_side.png",
      "logistica_passive_supplier_side.png",
      "logistica_passive_supplier_front.png",
})

--------------------------------
-- Trashcan
--------------------------------

logistica.register_trashcan("Trashcan", "trashcan", {
  "logistica_trashcan_top.png",
  "logistica_trashcan_bottom.png",
  "logistica_trashcan_side.png",
  "logistica_trashcan_side.png",
  "logistica_trashcan_side.png",
  "logistica_trashcan_side.png",
})

--------------------------------
-- Vaccuum Supply Chest
--------------------------------

logistica.register_vaccuum_chest("Vaccuum Supplier Chest", "vaccuum_chest", 16, {
  "logistica_vaccuum_top.png",
  "logistica_vaccuum_bottom.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_front.png",
})

--------------------------------
-- Wireless Receiver
--------------------------------

logistica.register_wireless_receiver("wireless_receiver", {
  description = "Wireless Receiver",
  paramtype2 = "color",
  sunlight_propagates = true,
  tiles = {
      "logistica_wifi_receiver_top.png", "logistica_wifi_receiver_top.png",
      "logistica_wifi_receiver_front.png", "logistica_wifi_receiver_front.png",
      "logistica_wifi_receiver_side.png", "logistica_wifi_receiver_side.png",
  },
  paramtype = "light",
  drawtype = "nodebox",
  node_box = {
    type = "connected",
    fixed = {
			{-4/16, -8/16, -4/16, 4/16, -6/16,  4/16}, -- base
			{-SIZE, -8/16, -SIZE, SIZE,  5/16,  SIZE}, -- column
			{-6/16,  3/16,  3/16, 6/16,  7/16,  4/16}, -- antenna1
			{-6/16,  3/16, -4/16, 6/16,  7/16, -3/16}, -- antenna2
			{-1/16,  4/16, -3/16, 1/16,  5/16,  3/16}, -- antenna bar
    },
    connect_top    = { -SIZE, -SIZE, -SIZE, SIZE, 8/16, SIZE }, -- y+
    connect_front  = { -SIZE, -SIZE, -8/16, SIZE, SIZE, SIZE }, -- z-
    connect_back   = { -SIZE, -SIZE,  SIZE, SIZE, SIZE, 8/16 }, -- z+
    connect_left   = { -8/16, -SIZE, -SIZE, SIZE, SIZE, SIZE }, -- x-
    connect_right  = { -SIZE, -SIZE, -SIZE, 8/16, SIZE, SIZE }, -- x+
  },
  selection_box = {
    type = "fixed",
    fixed = {
      {-6/16, -8/16, -4/16,  6/16, 7/16, 4/16}
    }
  },
  connects_to = { logistica.GROUP_ALL, logistica.GROUP_ALL, logistica.GROUP_CABLE_OFF },
  connect_sides = {"bottom", "left", "right", "back", "front"},
  groups = { oddly_breakable_by_hand = 1, cracky = 2, handy = 1, pickaxey = 2 },
  sounds = logistica.node_sound_metallic(),
})

--------------------------------
-- Wireless Transmitter
--------------------------------

logistica.register_wireless_transmitter("wireless_transmitter", {
  description = "Wireless Transmitter\nMust be placed on top of a Network Controller",
  short_description = "Wireless Transmitter",
  paramtype = "light",
  paramtype2 = "color",
  drawtype = "nodebox",
  tiles = {
    "logistica_wifi_transmitter_top.png",
    "logistica_wifi_transmitter_top.png",
    "logistica_wifi_transmitter_side.png",
  },
  node_box = {
    type = "fixed",
    fixed = {
      {-4/16, -8/16, -4/16,  4/16, -6/16,  4/16}, -- base bottom
      {-3/16, -6/16, -3/16,  3/16, -5/16,  3/16}, -- base upper
      {-6/16, -6/16, -1/16,  6/16, -5/16,  1/16}, -- crossbeam
      {-1/16, -6/16, -6/16,  1/16, -5/16,  6/16}, -- crossbeam
      {-7/16, -7/16, -2/16, -6/16,  7/16,  2/16}, -- antena
      { 7/16, -7/16, -2/16,  6/16,  7/16,  2/16}, -- antena
      {-2/16, -7/16,  7/16,  2/16,  7/16,  6/16}, -- antena
      {-2/16, -7/16, -7/16,  2/16,  7/16, -6/16}, -- antena
    }
  },
  selection_box = {
    type = "fixed",
    fixed = {
      {-7/16, -8/16, -7/16,  7/16, 7/16, 7/16}
    }
  },
  connect_sides = {},
  groups = { oddly_breakable_by_hand = 1, cracky = 2, handy = 1, pickaxey = 2 },
  sounds = logistica.node_sound_metallic(),
})

--------------------------------
-- Wireless Upgrader
--------------------------------

logistica.register_synchronizer("Wireless Upgrader", "wireless_synchronizer", {
  "logistica_synchronizer_side.png"
})
