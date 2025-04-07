local function L(s) return "logistica:"..s end

local itemstrings = logistica.itemstrings
local techage = minetest.get_modpath("techage")

assert(type(itemstrings) == "table")

if techage then itemstrings.cobble = "techage:basalt_cobble" end
itemstrings.nodebreaker = techage and "techage:ta4_quarry_pas" or L("silverin_circuit")
