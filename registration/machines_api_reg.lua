local S = logistica.TRANSLATOR

local SIZE = logistica.settings.cable_size

local itemstrings = logistica.itemstrings
--------------------------------
-- Access Point
--------------------------------

logistica.register_access_point(S("Access Point"), "access_point", {
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

logistica.register_autocrafter(S("Autocrafter"), "autocrafter", {
  "logistica_autocrafter.png"
})

--------------------------------
-- Disassembler
--------------------------------

logistica.register_disassembler(S("Logistica Machine Disassembler"), "disassembler", {
  "logistica_lava_furnace_side.png",
  "logistica_lava_furnace_side.png",
  "logistica_disassembler_side.png",
})

--------------------------------
-- Bucket Emptier
--------------------------------

logistica.register_bucket_emptier(S("Bucket Emptier"), "bucket_emptier", {
  "logistica_bucket_emptier_top.png",
  "logistica_bucket_emptier_top.png",
  "logistica_bucket_emptier_side.png",
})

--------------------------------
-- Bucket Filler
--------------------------------

logistica.register_bucket_filler(S("Bucket Filler"), "bucket_filler", {
  "logistica_bucket_filler_top.png",
  "logistica_bucket_filler_top.png",
  "logistica_bucket_filler_side.png",
})

--------------------------------
-- Cables
--------------------------------

-- regular
logistica.register_cable(S("Optic Cable"), "optic_cable")

-- full-block cable
logistica.register_cable(S("Embedded Optic Cable"), "optic_cable_block",
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
logistica.register_cable_toggleable(S("Toggleable Cable"), "optic_cable_toggleable",
  {"logistica_cable_toggleable_on.png"},
  {"logistica_cable_toggleable_off.png"}
)

-- insulating (directional, front-to-back only)
logistica.register_insulating_cable(S("Insulated Optic Cable"), "cable_insulating")

-- insulating L-shape (front arm + right arm), same textures
logistica.register_insulating_cable(S("Insulated Optic Cable (L-Shape)"), "cable_insulating_l",
  {"logistica_cable_insulating.png"}, "l_shape")

--------------------------------
-- Cobble Generator
--------------------------------

if logistica.settings.enable_cobblestone_supplier then
  logistica.register_cobble_generator_supplier(S("Cobble Generator"), "cobblegen_supplier", {
    "logistica_cobblegen_top.png",
    "logistica_cobblegen_bottom.png",
    "logistica_cobblegen_side.png^[transformFX",
    "logistica_cobblegen_side.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_front.png",
  })
end -- enable_cobblestone_supplier

--------------------------------
-- Controller
--------------------------------

logistica.register_controller("simple_controller", {
  description = S("Logistic Network Controller"),
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

logistica.register_crafting_supplier(S("Crafting Supplier"), "crafting_supplier", {
  "logistica_crafting_supplier_top.png",
  "logistica_crafting_supplier_bottom.png",
  "logistica_crafting_supplier_side.png",
})

--------------------------------
-- Cooking Supplier
--------------------------------

if logistica.settings.enable_cooking_supplier then
  logistica.register_cooking_supplier(S("Cooking Supplier"), "cooking_supplier", {
    "logistica_cooking_supplier_top.png",
    "logistica_crafting_supplier_bottom.png",
    "logistica_cooking_supplier_side.png",
  })
end -- enable_cooking_supplier

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

logistica.register_injector(S("Slow Network Importer\nImports 10 items at a time"), "injector_slow", 10, imp_tiles("item"))
logistica.register_injector(S("Fast Network Importer\nImports 99 items at a time"), "injector_fast", 99, imp_tiles("stack"))

--------------------------------
-- Item Storage
--------------------------------

logistica.register_item_storage(S("Tool Chest\nStores Tools Only"), "item_storage", {
      "logistica_tool_chest_top.png",
      "logistica_tool_chest_bottom.png",
      "logistica_tool_chest_side.png^[transformFX",
      "logistica_tool_chest_side.png",
      "logistica_tool_chest_back.png",
      "logistica_tool_chest_front.png",
})

--------------------------------
-- Rock Melter
--------------------------------

logistica.register_rock_melter(S("Rock Melter").."\n"..S("Melts stone-type blocks to produce lava"), "rock_melter", {
  inactive = {
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_front.png",
  },
  active = {
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_side.png",
    "logistica_rock_melter_front_active.png",
  },
})

--------------------------------
-- Lava Furnace
--------------------------------

logistica.register_lava_furnace(S("Lava Furnace"), "lava_furnace", 4, {
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

logistica.register_lava_furnace_fueler(S("Lava Furnace Fueler"), "lava_furnace_fueler", {
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

logistica.register_pump(S("Liquid Pump"), "pump",
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

logistica.register_mass_storage("mass_storage_basic", S("Mass Storage"), 8, 1024, 4, { 
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

logistica.register_requester(S("Item Request Inserter\nInserts 1 item at a time"), "requester_item", 1, ins_tiles("item"))
logistica.register_requester(S("Bulk Request Inserter\nInserts up to 64 items at a time"), "requester_stack", 64, ins_tiles("stack"))

--------------------------------
-- Reservoirs
--------------------------------

logistica.compat_bucket_register_buckets()

--------------------------------
-- Passive Supply Chest
--------------------------------

logistica.register_supplier(S("Passive Supplier Chest"), "passive_supplier", 32, {
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

logistica.register_trashcan(S("Trashcan"), "trashcan", {
  "logistica_trashcan_top.png",
  "logistica_trashcan_bottom.png",
  "logistica_trashcan_side.png",
  "logistica_trashcan_side.png",
  "logistica_trashcan_side.png",
  "logistica_trashcan_side.png",
})

--------------------------------
-- Vacuum Supply Chest
--------------------------------

logistica.register_vaccuum_chest(S("Vacuum Supplier Chest"), "vaccuum_chest", 16, {
  "logistica_vaccuum_top.png",
  "logistica_vaccuum_bottom.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_side.png",
  "logistica_vaccuum_front.png",
})

--------------------------------
-- Farming Supplier
--------------------------------

logistica.register_farming_supplier(S("Farming Supplier"), "farming_supplier", 14, {
  "logistica_farming_supplier_top.png",
  "logistica_farming_supplier_bottom.png",
  "logistica_farming_supplier_side.png",
  "logistica_farming_supplier_side.png",
  "logistica_farming_supplier_side.png",
  "logistica_farming_supplier_side.png",
})

--------------------------------
-- Wood Supplier
--------------------------------

logistica.register_woodcutter(S("Woodcutting Supplier"), "woodcutter", 14, {
  "logistica_woodcutter_top.png",
  "logistica_woodcutter_bottom.png",
  "logistica_woodcutter_side.png",
  "logistica_woodcutter_side.png^[transformFX",
  "logistica_woodcutter_front.png",
  "logistica_woodcutter_bottom.png", -- back
})

--------------------------------
-- Signal Lamp
--------------------------------

logistica.register_signal_lamp(
  S("White Signal Lamp"),
  "signal_lamp_white",
  "logistica_signal_lamp_white_off.png",
  "logistica_signal_lamp_white_on.png"
)

logistica.register_signal_lamp(
  S("Red Signal Lamp"),
  "signal_lamp_red",
  "logistica_signal_lamp_red_off.png",
  "logistica_signal_lamp_red_on.png"
)

logistica.register_signal_lamp(
  S("Green Signal Lamp"),
  "signal_lamp_green",
  "logistica_signal_lamp_green_off.png",
  "logistica_signal_lamp_green_on.png"
)

logistica.register_signal_lamp(
  S("Blue Signal Lamp"),
  "signal_lamp_blue",
  "logistica_signal_lamp_blue_off.png",
  "logistica_signal_lamp_blue_on.png"
)

logistica.register_signal_lamp(
  S("Cyan Signal Lamp"),
  "signal_lamp_cyan",
  "logistica_signal_lamp_cyan_off.png",
  "logistica_signal_lamp_cyan_on.png"
)

logistica.register_signal_lamp(
  S("Yellow Signal Lamp"),
  "signal_lamp_yellow",
  "logistica_signal_lamp_yellow_off.png",
  "logistica_signal_lamp_yellow_on.png"
)

logistica.register_signal_lamp(
  S("Purple Signal Lamp"),
  "signal_lamp_purple",
  "logistica_signal_lamp_purple_off.png",
  "logistica_signal_lamp_purple_on.png"
)

--------------------------------
-- Mesecon Signal Receiver (mesecon effector -> logistica signal sender)
--------------------------------

if minetest.get_modpath("mesecons") then
  logistica.register_mesecon_signaler(
    S("Logistica Mesecon Signal Receiver"),
    "mesecon_signaler",
    "logistica_mesecon_signaler_top_off.png",
    "logistica_mesecon_signaler_top_on.png",
    "logistica_cable_toggleable_on.png", -- side
    "logistica_access_point_bottom.png" -- bottom
  )
end

--------------------------------
-- Mesecon Signal Sender (logistica signal receiver -> mesecon receptor)
--------------------------------

if minetest.get_modpath("mesecons") then
  logistica.register_mesecon_sender(
    S("Logistica Mesecon Signal Sender"),
    "mesecon_sender",
    "logistica_mesecon_sender_top_off.png",
    "logistica_mesecon_sender_top_on.png",
    "logistica_cable_toggleable_on.png", -- side
    "logistica_access_point_bottom.png" -- bottom
  )
end

--------------------------------
-- Signal Lamp 2-Color
--------------------------------

logistica.register_signal_lamp_2c(
  S("Blue/Red Signal Lamp"),
  "signal_lamp_2c_br",
  S("blue"), "logistica_signal_lamp_2c_br_off_top.png", "logistica_signal_lamp_2c_br_blue_side.png",
  S("red"),  "logistica_signal_lamp_2c_br_off_top.png",  "logistica_signal_lamp_2c_br_red_side.png",
             "logistica_signal_lamp_2c_br_off_top.png",  "logistica_signal_lamp_2c_br_off_side.png"
)

--------------------------------
-- Signal Logic Gate
--------------------------------

logistica.register_signal_logic_gate(
  S("Signal Logic Gate"),
  "signal_logic_gate",
  {
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_top.png",
    "logistica_signal_logic_gate_side.png",
    "logistica_signal_logic_gate_side.png",
    "logistica_signal_logic_gate_side.png",
    "logistica_signal_logic_gate_side.png",
  }
)

--------------------------------
-- Signal NOT Gate
--------------------------------

logistica.register_signal_not_gate(
  S("Signal NOT Gate"),
  "signal_not_gate",
  {
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_side.png",
    "logistica_signal_not_gate_side.png",
    "logistica_signal_not_gate_side.png",
    "logistica_signal_not_gate_side.png",
  }
)

--------------------------------
-- Signal Toggle
--------------------------------

logistica.register_signal_toggle(
  S("Signal Toggle"),
  "signal_toggle",
  {
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_top.png",
    "logistica_signal_toggle_side.png",
    "logistica_signal_toggle_side.png",
    "logistica_signal_toggle_side.png",
    "logistica_signal_toggle_side.png",
  },
  {
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_top.png",
    "logistica_signal_toggle_side_on.png",
    "logistica_signal_toggle_side_on.png",
    "logistica_signal_toggle_side_on.png",
    "logistica_signal_toggle_side_on.png",
  }
)

--------------------------------
-- Signal Delayer
--------------------------------

logistica.register_signal_delayer(
  S("Signal Delayer"),
  "signal_delayer",
  {
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_top.png",
    "logistica_signal_delayer_side.png",
    "logistica_signal_delayer_side.png",
    "logistica_signal_delayer_side.png",
    "logistica_signal_delayer_side.png",
  },
  {
    "logistica_signal_not_gate_top.png",
    "logistica_signal_not_gate_top.png",
    "logistica_signal_delayer_side_on.png",
    "logistica_signal_delayer_side_on.png",
    "logistica_signal_delayer_side_on.png",
    "logistica_signal_delayer_side_on.png",
  }
)

--------------------------------
-- Signal Toggler
--------------------------------

logistica.register_signal_toggler(
  S("Signal Network Switch"),
  "signal_toggler",
  {
    "logistica_signal_toggler_side_off.png^[transformR270",
    "logistica_signal_toggler_side_off.png^[transformR90",
    "logistica_signal_toggler_side_off.png^[transformR180",
    "logistica_signal_toggler_side_off.png",
    "logistica_signal_toggler_back_off.png",
    "logistica_signal_toggler_front.png",
  },
  {
    "logistica_signal_toggler_side_on.png^[transformR270",
    "logistica_signal_toggler_side_on.png^[transformR90",
    "logistica_signal_toggler_side_on.png^[transformR180",
    "logistica_signal_toggler_side_on.png",
    "logistica_signal_toggler_back_on.png",
    "logistica_signal_toggler_front.png",
  }
)

--------------------------------
-- Signal Switch
--------------------------------

logistica.register_signal_button(
  S("Signal Button"),
  "signal_button",
  {
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_signal_button_front.png",
  },
  {
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_signal_button_front_on.png",
  }
)

logistica.register_signal_switch(
  S("Signal Switch"),
  "signal_switch",
  {
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_signal_switch_front_off.png",
  },
  {
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_cobblegen_back.png",
    "logistica_signal_switch_front_on.png",
  }
)

--------------------------------
-- Wireless Receiver
--------------------------------

if logistica.settings.enable_wireless_antennas then

logistica.register_wireless_receiver("wireless_receiver", {
  description = S("Wireless Receiver"),
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
  description = S("Wireless Transmitter\nMust be placed on top of a Network Controller"),
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

end -- enable_wireless_antennas

--------------------------------
-- Item Monitor
--------------------------------

logistica.register_item_monitor(
  S("Item Monitor"),
  "item_monitor",
  {
      "logistica_item_monitor_top.png",
      "logistica_access_point_bottom.png",
      "logistica_item_monitor_side.png^[transformFX",
      "logistica_item_monitor_side.png",
      "logistica_item_monitor_back.png",
      "logistica_item_monitor_front.png",
  }
)

--------------------------------
-- Signal Item Count Sender
--------------------------------

logistica.register_signal_item_counter(
  S("Signal Item Count Sender"),
  "signal_item_counter",
  {"logistica_fueler_front.png", "logistica_signal_item_counter_side.png"},
  {"logistica_fueler_front.png", "logistica_signal_item_counter_side_on.png"}
)

--------------------------------
-- Signal Liquid Count Sender
--------------------------------

logistica.register_signal_liquid_counter(
  S("Signal Liquid Count Sender"),
  "signal_liquid_counter",
  {"logistica_fueler_front.png", "logistica_signal_liquid_counter_side.png"},
  {"logistica_fueler_front.png", "logistica_signal_liquid_counter_side_on.png"}
)

--------------------------------
-- Signal Timer Sender
--------------------------------

logistica.register_signal_ext_reader(
  S("External Content Reader"),
  "signal_ext_reader",
  {
    "logistica_signal_ext_reader_side.png^[transformR270",
    "logistica_signal_ext_reader_side.png^[transformR90",
    "logistica_signal_ext_reader_side.png^[transformR180",
    "logistica_signal_ext_reader_side.png",
    "logistica_signal_ext_reader_back.png",
    "logistica_fueler_front.png", -- front
  }
)

logistica.register_signal_timer(
  S("Signal Timer Sender"),
  "signal_timer",
  {"logistica_fueler_front.png", "logistica_signal_timer_side.png"},
  {"logistica_fueler_front.png", "logistica_signal_timer_side_on.png"}
)

--------------------------------
-- Signal Node Detector
--------------------------------

logistica.register_signal_node_detector(
  S("Signal Node Detector"),
  "signal_node_detector",
  {
    "logistica_signal_node_detector_side.png^[transformR270",
    "logistica_signal_node_detector_side.png^[transformR90",
    "logistica_signal_node_detector_side.png^[transformR180",
    "logistica_signal_node_detector_side.png",
    "logistica_signal_node_detector_back.png",
    "logistica_signal_toggler_front.png",
  },
  {
    "logistica_signal_node_detector_side_on.png^[transformR270",
    "logistica_signal_node_detector_side_on.png^[transformR90",
    "logistica_signal_node_detector_side_on.png^[transformR180",
    "logistica_signal_node_detector_side_on.png",
    "logistica_signal_node_detector_back.png",
    "logistica_signal_toggler_front.png",
  }
)

if logistica.settings.enable_node_digger then
  logistica.register_signal_node_digger(
    S("Signal Node Digger"),
    "signal_node_digger",
    {
      "logistica_signal_node_digger_side.png^[transformR270",
      "logistica_signal_node_digger_side.png^[transformR90",
      "logistica_signal_node_digger_side.png^[transformR180",
      "logistica_signal_node_digger_side.png",
      "logistica_signal_node_digger_back.png",
      "logistica_signal_toggler_front.png",
    }
  )
end

if logistica.settings.enable_node_placer then
  logistica.register_signal_node_placer(
    S("Signal Node Placer"),
    "signal_node_placer",
    {
      "logistica_signal_node_placer_side.png^[transformR270",
      "logistica_signal_node_placer_side.png^[transformR90",
      "logistica_signal_node_placer_side.png^[transformR180",
      "logistica_signal_node_placer_side.png",
      "logistica_signal_node_placer_back.png",
      "logistica_signal_toggler_front.png",
    }
  )
end

--------------------------------
-- Wireless Upgrader
--------------------------------

if logistica.settings.enable_wireless_access_pad then
  logistica.register_synchronizer(S("Wireless Upgrader"), "wireless_synchronizer", {
    "logistica_synchronizer_side.png"
  })
end

--------------------------------
-- Signal Monitor
--------------------------------

logistica.register_signal_monitor(
  S("Signal Monitor"),
  "signal_monitor",
  {
    "logistica_signal_toggler_front.png",
    "logistica_signal_toggler_front.png",
    "logistica_signal_monitor_side.png^[transformFX",
    "logistica_signal_monitor_side.png",
    "logistica_signal_monitor_side.png",
    "logistica_signal_monitor_front.png",
  }
)

--------------------------------
-- Digiline Signal Sender
--------------------------------

if minetest.get_modpath("digilines") and logistica.settings.enable_digiline_machines then
  logistica.register_digiline_sender(
    S("Logistica Digiline Signal Sender"),
    "digiline_sender",
    {
      "logistica_digiline_sender_side.png",
      "logistica_access_point_bottom.png",
      "logistica_digiline_sender_side.png",
      "logistica_digiline_sender_side.png",
      "logistica_digiline_sender_side.png",
      "logistica_digiline_sender_side.png",
    }
  )
  logistica.register_digiline_receiver(
    S("Logistica Digiline to Signal Converter"),
    "digiline_receiver",
    "logistica_digiline_receiver_side.png",
    "logistica_digiline_receiver_top.png",
    "logistica_access_point_bottom.png"
  )
end
