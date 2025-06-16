local function L(s) return "logistica:"..s end

local itemstrings = logistica.itemstrings
local techage = minetest.get_modpath("techage")

assert(type(itemstrings) == "table")

if techage then
  itemstrings.cobble = "techage:basalt_cobble"
  itemstrings.nodebreaker = "techage:ta4_quarry_pas" 
  itemstrings.cobgen_upgr_additional = "techage:ta4_quarry_pas"
else
  itemstrings.nodebreaker = L("silverin_circuit")
  itemstrings.cobgen_upgr_additional = ""
end
