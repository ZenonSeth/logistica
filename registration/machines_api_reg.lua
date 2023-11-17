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
-- Cables
--------------------------------

local CABLE_SIZE = 1/16
logistica.register_cable("Optic cable", "optic_cable", CABLE_SIZE)
-- TODO: plate + cable = masked cable
-- logistica.register_cable("Optic cable", "optic_wall", CABLE_SIZE, {
--   fixed = {
--     { -CABLE_SIZE, -CABLE_SIZE, -CABLE_SIZE, CABLE_SIZE, CABLE_SIZE, CABLE_SIZE }
--   }
-- })
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
  groups = { oddly_breakable_by_hand = 1, cracky = 2 },
  sounds = logistica.node_sound_metallic(),
  drawtype = "normal",
  node_box = { type = "regular"},
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

logistica.register_item_storage("Tool Box\nStores Tools Only", "item_storage", {
      "logistica_tool_box_top.png",
      "logistica_tool_box_bottom.png",
      "logistica_tool_box_side.png^[transformFX",
      "logistica_tool_box_side.png",
      "logistica_tool_box_back.png",
      "logistica_tool_box_front.png",
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

logistica.register_vaccuum_chest("Vaccuum Supplier Chest", "vaccuum_chest", 16, {
  "logistica_vaccuum_top.png",
  "logistica_vaccuum_bottom.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_front.png",
})
