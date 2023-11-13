
local function L(s) return "logistica:"..s end
local SILV = L("silverin")
local SILV_SLICE = L("silverin_slice")

minetest.register_craft({
    output = SILV_SLICE.." 8",
    type = "shapeless",
    recipe = { SILV },
})

minetest.register_craft({
    output = SILV,
    type = "shapeless",
    recipe = {
      SILV_SLICE, SILV_SLICE, SILV_SLICE, SILV_SLICE,
      SILV_SLICE, SILV_SLICE, SILV_SLICE, SILV_SLICE
    },
})

-- minetest.register_craft({
--   output = L("network_tool"),
--   recipe = {
    
--   }
-- })

