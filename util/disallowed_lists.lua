local no_push = logistica.add_disallowed_push_list
local no_pull = logistica.add_disallowed_pull_list
local do_push = logistica.add_allowed_push_list_for_node

if minetest.get_modpath("techage") then
  -- some nodes in techage have lists that we shouldn't push or pull from
  no_push("techage:ta4_recipeblock",         "input")
  no_push("techage:ta3_digtron_battery_pas", "fuel")
  no_push("techage:ta3_digtron_battery_act", "fuel")
  no_push("techage:ta4_pusher_pas",          "main")
  no_push("techage:ta4_pusher_act",          "main")
  no_push("techage:ta5_hl_chest",            "main")
  no_push("techage:ta3_doorcontroller2",     "main")
  no_push("techage:ta4_movecontroller2",     "main")

  no_pull("techage:ta2_autocrafter_pas", "output")
  no_pull("techage:ta2_autocrafter_act", "output")
  no_pull("techage:ta3_autocrafter_pas", "output")
  no_pull("techage:ta3_autocrafter_act", "output")
  no_pull("techage:ta4_autocrafter_pas", "output")
  no_pull("techage:ta4_autocrafter_act", "output")
  no_pull("techage:ta4_recipeblock",     "output")
  no_pull("techage:ta4_pusher_pas",      "main")
  no_pull("techage:ta4_pusher_act",      "main")
  no_pull("techage:ta5_hl_chest",        "main")
  no_pull("techage:ta3_doorcontroller2", "main")
  no_pull("techage:ta4_movecontroller2", "main")
end

if minetest.get_modpath("digtron") then
  no_push("digtron:builder",        "main")
  no_push("digtron:master_builder", "main")

  no_pull("digtron:builder",        "main")
  no_pull("digtron:master_builder", "main")
end

if minetest.get_modpath("pipeworks") then
  no_push("pipeworks:nodebreaker_off", "main")
  no_push("pipeworks:nodebreaker_on",  "main")
  do_push("pipeworks:nodebreaker_off", "pick")
  do_push("pipeworks:nodebreaker_on",  "pick")

  no_push("pipeworks:filter", "main")
  no_pull("pipeworks:filter", "main")
end