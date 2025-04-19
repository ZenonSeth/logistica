local function L(s) return "logistica:"..s end

local itemstrings = logistica.itemstrings
local techage = minetest.get_modpath("techage")

assert(type(itemstrings) == "table")

if techage then
  itemstrings.cobble = "techage:basalt_cobble"
  itemstrings.nodebreaker = "techage:ta4_quarry_pas" 
  itemstrings.cobgen_upgr_additional = "techage:ta4_quarry_pas"

  local no_push = logistica.add_disallowed_push_list
  local no_pull = logistica.add_disallowed_pull_list

  -- some nodes in techage have lists that we shouldn't push or pull from
  no_push("techage:ta4_recipeblock",     "input")
  no_push("techage:ta4_pusher_pas",      "main")
  no_push("techage:ta4_pusher_act",      "main")
  no_push("techage:ta5_hl_chest",        "main")
  no_push("techage:ta3_doorcontroller2", "main")
  no_push("techage:ta4_movecontroller2", "main")

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
else
  itemstrings.nodebreaker = L("silverin_circuit")
  itemstrings.cobgen_upgr_additional = ""
end
