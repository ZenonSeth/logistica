local itemstrings = logistica.itemstrings
local techage = minetest.get_modpath("techage")

assert(type(itemstrings) == "table")

if techage then itemstrings.cobble = "techage:basalt_cobble" end
