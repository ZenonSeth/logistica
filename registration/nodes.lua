--------------------------------
-- Access Point
--------------------------------

logistica.register_access_point("Access Point", "base", {
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
logistica.register_cable("Silver", CABLE_SIZE)

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

logistica.register_injector("Slow Network Importer\nImports 10 items at a time", "slow", 10, imp_tiles("item"))
logistica.register_injector("Fast Network Importer\nImports 99 items at a time", "fast", 99, imp_tiles("stack"))

--------------------------------
-- Item Storage
--------------------------------

logistica.register_item_storage("Tool Box\nStores Tools Only", "simple", {
      "logistica_tool_box_top.png",
      "logistica_tool_box_bottom.png",
      "logistica_tool_box_side.png^[transformFX",
      "logistica_tool_box_side.png",
      "logistica_tool_box_back.png",
      "logistica_tool_box_front.png",
})

--------------------------------
-- Mass Storage
--------------------------------

logistica.register_mass_storage("basic", "Mass Storage", 8, 1024, 4, { 
  "logistica_basic_mass_storage.png", "logistica_basic_mass_storage.png",
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

logistica.register_requester("Item Request Inserter\nInserts 1 item at a time", "item", 1, ins_tiles("item"))
logistica.register_requester("Bulk Request Inserter\nInserts up to 64 items at a time", "stack", 64, ins_tiles("stack"))

--------------------------------
-- Passive Supply Chest
--------------------------------

logistica.register_supplier("Passive Supplier Chest", "simple", 16, {
      "logistica_passive_supplier_top.png",
      "logistica_passive_supplier_bottom.png",
      "logistica_passive_supplier_side.png^[transformFX",
      "logistica_passive_supplier_side.png",
      "logistica_passive_supplier_side.png",
      "logistica_passive_supplier_front.png",
})

--------------------------------
-- Lava Furnace
--------------------------------

