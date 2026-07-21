local itemstrings = logistica.itemstrings
local function L(s) return "logistica:"..s end

logistica.register_craft({
  output = L("lava_furnace"),
  recipe = {
    {itemstrings.clay,  itemstrings.obsidian,     itemstrings.clay},
    {itemstrings.steel, itemstrings.empty_bucket, itemstrings.steel},
    {itemstrings.steel, itemstrings.empty_bucket, itemstrings.steel},
  }
})

logistica.register_craft({
  output = L("rock_melter"),
  recipe = {
    {L("hardened_silverin_block"), itemstrings.clay,           L("hardened_silverin_block")},
    {L("optic_cable"),             L("compression_tank"),      L("photonizer")},
    {L("hardened_silverin_block"), itemstrings.clay,           L("hardened_silverin_block")},
  }
})

logistica.register_craft({
  output = L("mass_storage_basic"),
  recipe = {
    {L("silverin_plate"),      L("optic_cable"),         L("silverin_plate")},
    {L("silverin_mirror_box"), L("silverin_mirror_box"), L("silverin_mirror_box")},
    {L("silverin_plate"),      L("silverin_circuit"),    L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("item_storage"),
  recipe = {
    {L("silverin_plate"), "",                       L("silverin_plate")},
    {L("optic_cable"),    L("silverin_mirror_box"), L("silverin_circuit")},
    {L("silverin_plate"), L("silverin_mirror_box"), L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("passive_supplier"),
  recipe = {
    {L("silverin_plate"), itemstrings.chest, L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),   ""},
    {L("silverin_plate"), "",                L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("requester_item"),
  recipe = {
    {L("silverin_plate"), "",              L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"), ""},
    {L("silverin_plate"), "",              L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("requester_stack"),
  recipe = {
    {L("silverin_plate"), L("silverin_circuit"), L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),       ""},
    {L("silverin_plate"), "",                   L("silverin_plate")},
  }
})

logistica.register_craft({ no_recycle = true,
  output = L("requester_stack"),
  recipe = {
    {L("requester_item"), L("silverin_circuit"), ""},
  }
})
logistica.register_craft({
  output = L("injector_slow"),
  recipe = {
    {L("silverin_plate"), "",                       L("silverin_plate")},
    {L("optic_cable"),    L("photonizer_reversed"), ""},
    {L("silverin_plate"), "",                       L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("injector_fast"),
  recipe = {
    {L("silverin_plate"), L("silverin_circuit"),    L("silverin_plate")},
    {L("optic_cable"),    L("photonizer_reversed"), ""},
    {L("silverin_plate"), "",                       L("silverin_plate")},
  }
})

logistica.register_craft({ no_recycle = true,
  output = L("injector_fast"),
  recipe = {
    {L("injector_slow"), L("silverin_circuit"),""},
  }
})

logistica.register_craft({
  output = L("simple_controller"),
  recipe = {
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
    {L("silverin_circuit"), L("optic_cable"),      L("silverin_circuit")},
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("access_point"),
  recipe = {
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
    {L("photonizer"),       L("optic_cable"),      L("photonizer_reversed")},
    {L("silverin_plate"),   L("silverin_circuit"), L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("trashcan"),
  recipe = {
    {L("silverin_plate"), L("optic_cable"),   L("silverin_plate")},
    {"",                  "",                 ""},
    {L("silverin_plate"), itemstrings.cactus, L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("vaccuum_chest"),
  recipe = {
    {L("silverin_plate"), itemstrings.chest,   L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),     ""},
    {L("silverin_plate"), itemstrings.crystal, L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("woodcutter"),
  recipe = {
    {itemstrings.steel,  itemstrings.steel,     itemstrings.steel},
    {L("optic_cable"),   L("silverin_block"),   L("photonizer")},
    {"",                 itemstrings.chest,     ""},
  }
})

logistica.register_craft({
  output = L("farming_supplier"),
  recipe = {
    {itemstrings.glass,  itemstrings.steel,    itemstrings.crystal},
    {L("optic_cable"),   L("silverin_block"),  L("photonizer")},
    {"",                 itemstrings.chest,    ""},
  }
})

logistica.register_craft({
  output = L("autocrafter"),
  recipe = {
    {L("silverin_plate"), itemstrings.chest,     L("silverin_plate")},
    {"",                  L("silverin_circuit"), ""},
    {L("silverin_plate"), "",                    L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("crafting_supplier"),
  recipe = {
    {L("silverin_plate"),   itemstrings.chest, L("silverin_plate")},
    {L("silverin_circuit"), L("photonizer"),   L("silverin_circuit")},
    {L("silverin_plate"),   L("optic_cable"),  L("silverin_plate")},
  }
})

if logistica.settings.enable_cooking_supplier then
  logistica.register_craft({
    output = L("cooking_supplier"),
    recipe = {
      {L("silverin_plate"),          L("compression_tank"), L("silverin_plate")},
      {L("hardened_silverin_block"), L("crafting_supplier"), L("hardened_silverin_block")},
      {L("silverin_plate"),          L("optic_cable"),      L("silverin_plate")},
    }
  })
end -- enable_cooking_supplier

if logistica.settings.enable_cobblestone_supplier then
  logistica.register_craft({
    output = L("cobblegen_supplier"),
    recipe = {
      {L("silverin_plate"), itemstrings.lava_bucket,  L("silverin_plate")},
      {L("optic_cable"),    L("photonizer"),          itemstrings.nodebreaker},
      {L("silverin_plate"), itemstrings.water_bucket, L("silverin_plate")},
    },
    replacements = {
      {itemstrings.water_bucket, itemstrings.empty_bucket},
      {itemstrings.lava_bucket,  itemstrings.empty_bucket},
    }
  })
end -- enable_cobblestone_supplier

if logistica.settings.enable_wireless_access_pad then
  logistica.register_craft({
    output = L("wireless_synchronizer"),
    recipe = {
      {L("silverin_plate"),   L("wireless_crystal"), L("silverin_plate")},
      {L("wireless_crystal"), L("silverin_circuit"), L("wireless_crystal")},
      {L("silverin_plate"),   L("wireless_crystal"), L("silverin_plate")},
    }
  })
end

logistica.register_craft({
  output = L("reservoir_silverin_empty"),
  recipe = {
    {L("silverin_plate"), "",                    L("silverin_plate")},
    {L("optic_cable"),    L("compression_tank"), L("photonizer")},
    {L("silverin_plate"), "",                    L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("reservoir_obsidian_empty"),
  recipe = {
    {itemstrings.obsidian, L("silverin_plate"),   itemstrings.obsidian},
    {L("optic_cable"),     L("compression_tank"), L("photonizer")},
    {itemstrings.obsidian, L("silverin_plate"),   itemstrings.obsidian},
  }
})

logistica.register_craft({
  output = L("lava_furnace_fueler"),
  recipe = {
    {L("silverin_plate"), itemstrings.clay, L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),  ""},
    {L("silverin_plate"), itemstrings.clay, L("silverin_plate")},
  }
})

logistica.register_craft({ no_recycle = true, output = L("optic_cable_block"), recipe = {
  {L("silverin_plate")},
  {L("optic_cable")},
  {L("silverin_plate")},
}})

logistica.register_craft({ no_recycle = true, output = L("cable_insulating"),   type = "shapeless", recipe = {L("optic_cable")} })
logistica.register_craft({ no_recycle = true, output = L("cable_insulating_l"), type = "shapeless", recipe = {L("cable_insulating")} })
logistica.register_craft({ no_recycle = true, output = L("optic_cable"),        type = "shapeless", recipe = {L("cable_insulating_l")} })

logistica.register_craft({
  output = L("silverin_block"),
  recipe = {
    {L("silverin_plate"), L("silverin_plate"), L("silverin_plate")}
  }
})

logistica.register_craft({
  output = L("silverin_plate 3"),
  type = "shapeless",
  recipe = {
    L("silverin_block")
  }
})

logistica.register_craft({
  output = L("bucket_filler"),
  recipe = {
    {L("silverin_plate"), "",                       L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),          ""},
    {L("silverin_plate"), itemstrings.empty_bucket, L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("bucket_emptier"),
  recipe = {
    {L("silverin_plate"), itemstrings.empty_bucket, L("silverin_plate")},
    {L("optic_cable"),    L("photonizer"),          ""},
    {L("silverin_plate"), "",                       L("silverin_plate")},
  }
})

logistica.register_craft({
  output = L("pump"),
  recipe = {
    {L("silverin_plate"), itemstrings.empty_bucket, L("silverin_plate")},
    {L("optic_cable"),    itemstrings.crystal ,     L("photonizer")},
    {L("silverin_plate"), L("compression_tank"),    L("silverin_plate")},
  }
})

if logistica.settings.enable_wireless_antennas then
  logistica.register_craft({
    output = L("wireless_receiver"),
    recipe = {
      {L("wireless_antenna"),    L("optic_cable"),      L("wireless_antenna")},
      {L("photonizer_reversed"), L("silverin_plate"),   L("photonizer")},
      {"",                       L("silverin_circuit"), ""},
    }
  })

  logistica.register_craft({
    output = L("wireless_transmitter"),
    recipe = {
      {L("wireless_antenna"),    L("optic_cable"),      L("wireless_antenna")},
      {L("photonizer_reversed"), itemstrings.diamond,   L("photonizer")},
      {L("wireless_antenna"),    L("silverin_circuit"), L("wireless_antenna")},
    }
  })
end

local PLATE  = L("silverin_plate")
local RELAY  = L("signal_relay")
local CIRC   = L("silverin_circuit")
local CABLE  = L("optic_cable")

logistica.register_craft({
  output = L("signal_button"),
  recipe = {
    {PLATE, ""               , PLATE},
    {"",    RELAY,             ""},
    {PLATE, itemstrings.steel, PLATE},
  }
})

logistica.register_craft({
  output = L("signal_switch"),
  recipe = {
    {PLATE, itemstrings.steel, PLATE},
    {"",    RELAY,             ""},
    {PLATE, "",                PLATE},
  }
})

logistica.register_craft({
  output = L("signal_lamp_white"),
  recipe = {
    {PLATE, itemstrings.glass, PLATE},
    {"",    RELAY,             ""},
    {PLATE, "",                PLATE},
  }
})

logistica.register_craft({ type = "shapeless", output = L("signal_lamp_red"),    recipe = {L("signal_lamp_white")}  })
logistica.register_craft({ type = "shapeless", output = L("signal_lamp_yellow"), recipe = {L("signal_lamp_red")}    })
logistica.register_craft({ type = "shapeless", output = L("signal_lamp_green"),  recipe = {L("signal_lamp_yellow")} })
logistica.register_craft({ type = "shapeless", output = L("signal_lamp_cyan"),   recipe = {L("signal_lamp_green")}  })
logistica.register_craft({ type = "shapeless", output = L("signal_lamp_blue"),   recipe = {L("signal_lamp_cyan")}   })
logistica.register_craft({ type = "shapeless", output = L("signal_lamp_purple"), recipe = {L("signal_lamp_blue")}   })
logistica.register_craft({ no_recycle = true, type = "shapeless", output = L("signal_lamp_white"),  recipe = {L("signal_lamp_purple")} })

logistica.register_craft({
  output = L("signal_lamp_2c_br"),
  recipe = {
    {PLATE, itemstrings.glass, PLATE},
    {"",    RELAY,             ""},
    {PLATE, itemstrings.glass, PLATE},
  }
})

logistica.register_craft({
  output = L("signal_toggler"),
  recipe = {
    {PLATE, CABLE, PLATE},
    {"",    RELAY, ""},
    {PLATE, "",    PLATE},
  }
})

logistica.register_craft({
  output = L("signal_not_gate"),
  recipe = {
    {PLATE, CIRC,  PLATE},
    {"",    RELAY, ""},
    {PLATE, "",    PLATE},
  }
})

logistica.register_craft({
  output = L("signal_logic_gate"),
  recipe = {
    {PLATE, CIRC,  PLATE},
    {"",    RELAY, ""},
    {PLATE, CIRC,  PLATE},
  }
})

logistica.register_craft({
  output = L("signal_toggle"),
  recipe = {
    {PLATE, RELAY, PLATE},
    {RELAY, CIRC,  RELAY},
    {PLATE, "",    PLATE},
  }
})

logistica.register_craft({
  output = L("signal_delayer"),
  recipe = {
    {PLATE, RELAY, PLATE},
    {CIRC,  RELAY, CIRC},
    {PLATE, RELAY, PLATE},
  }
})

logistica.register_craft({
  output = L("signal_ext_reader"),
  recipe = {
    {PLATE,            CIRC,  PLATE},
    {L("photonizer"),  RELAY, CIRC},
    {PLATE,            CIRC,  PLATE},
  }
})

logistica.register_craft({
  output = L("item_monitor"),
  recipe = {
    {itemstrings.glass, itemstrings.crystal, itemstrings.glass},
    {CIRC,              L("photonizer"),     CIRC},
    {PLATE,             CABLE,               PLATE},
  }
})

logistica.register_craft({
  output = L("signal_monitor"),
  recipe = {
    {itemstrings.glass, CIRC,  itemstrings.glass},
    {CIRC,              RELAY, CIRC},
    {PLATE,             CABLE, PLATE},
  }
})

logistica.register_craft({
  output = L("signal_item_counter"),
  recipe = {
    {PLATE, "",    PLATE},
    {CIRC,  RELAY, CIRC},
    {PLATE, "",    PLATE},
  }
})

logistica.register_craft({
  output = L("signal_liquid_counter"),
  recipe = {
    {PLATE, "",                          PLATE},
    {CIRC,  itemstrings.empty_bucket,    CIRC},
    {PLATE, RELAY,                       PLATE},
  }
})

logistica.register_craft({
  output = L("signal_timer"),
  recipe = {
    {PLATE, itemstrings.steel, PLATE},
    {"",    RELAY,             ""},
    {PLATE, itemstrings.steel, PLATE},
  }
})

logistica.register_craft({
  output = L("signal_node_detector"),
  recipe = {
    {PLATE,            "",               PLATE},
    {itemstrings.glass, RELAY,           L("silverin_block")},
    {PLATE,            CIRC,             PLATE},
  }
})

if logistica.settings.enable_node_digger then
  logistica.register_craft({
    output = L("signal_node_digger"),
    recipe = {
      {PLATE,             itemstrings.steel, PLATE},
      {itemstrings.glass, RELAY,             L("silverin_block")},
      {PLATE,             CIRC,              PLATE},
    }
  })
end

if logistica.settings.enable_node_placer then
  logistica.register_craft({
    output = L("signal_node_placer"),
    recipe = {
      {PLATE,              CIRC,  PLATE},
      {L("silverin_block"), RELAY, itemstrings.glass},
      {PLATE,              CIRC,  PLATE},
    }
  })
end

if logistica.settings.enable_requester_programmer then
  logistica.register_craft({
    output = L("requester_programmer_on"),
    recipe = {
      {PLATE, CIRC,                 PLATE},
      {RELAY, L("requester_item"), RELAY},
      {PLATE, CIRC,                 PLATE},
    }
  })
end

logistica.register_craft({
  output = L("disassembler"),
  recipe = {
    {"",              CABLE,                ""},
    {L("photonizer"), L("silverin_block"),  L("photonizer_reversed")},
    {"",              CABLE,                ""},
  }
})

if minetest.get_modpath("mesecons") then
  local WIRE = "mesecons:wire_00000000_off"
  logistica.register_craft({
    output = L("mesecon_signaler"),
    recipe = {
      {PLATE, WIRE,  PLATE},
      {"",    RELAY, ""},
      {PLATE, "",    PLATE},
    }
  })
  logistica.register_craft({
    output = L("mesecon_sender"),
    recipe = {
      {PLATE, "",    PLATE},
      {"",    RELAY, ""},
      {PLATE, WIRE,  PLATE},
    }
  })
end

if minetest.get_modpath("digilines") and logistica.settings.enable_digiline_machines then
  local DWIRE = "digilines:wire_std_00000000"
  logistica.register_craft({
    output = L("digiline_sender"),
    recipe = {
      {PLATE, DWIRE, PLATE},
      {CIRC,  RELAY, CIRC},
      {PLATE, DWIRE, PLATE},
    }
  })
  logistica.register_craft({
    output = L("digiline_receiver"),
    recipe = {
      {PLATE, "",    PLATE},
      {RELAY, CIRC,  RELAY},
      {PLATE, DWIRE, PLATE},
    }
  })
end

logistica.register_craft({
  output = L("autocrafting_upgrade"),
  recipe = {
    {PLATE,                    L("crafting_supplier"),    PLATE},
    {L("photonizer"),          PLATE,                    L("photonizer_reversed")},
    {PLATE,                    L("crafting_supplier"),    PLATE},
  }
})

logistica.register_craft({
  output = L("autocrafting_recursive_upgrade"),
  recipe = {
    {L("autocrafting_upgrade"), L("crafting_supplier"),   L("autocrafting_upgrade")},
    {L("crafting_supplier"),    CIRC,                     L("crafting_supplier")},
    {L("autocrafting_upgrade"), L("crafting_supplier"),   L("autocrafting_upgrade")},
  }
})
