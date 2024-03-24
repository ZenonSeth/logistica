if not (minetest.get_modpath("default") and minetest.get_modpath("bucket"))
and not (minetest.get_modpath("mcl_core") and minetest.get_modpath("mcl_buckets")) then
    minetest.log("error", "Logistica requires either default and bucket (included in Minetest Game) or mcl_core and mcl_buckets (included in MineClone2 and Mineclonia)")
    return
end

logistica = {}

logistica.MODNAME = minetest.get_current_modname() or "logistica"
logistica.MODPATH = minetest.get_modpath(logistica.MODNAME)

-- order of loading files DOES matter
dofile(logistica.MODPATH.."/util/util.lua")
dofile(logistica.MODPATH.."/entity/entity.lua")
dofile(logistica.MODPATH.."/logic/logic.lua")
dofile(logistica.MODPATH.."/item/item.lua")
dofile(logistica.MODPATH.."/tools/tools.lua")

-- api should be below the other files except the registrations and guide
dofile(logistica.MODPATH.."/api/api.lua")
dofile(logistica.MODPATH.."/registration/registration.lua")
dofile(logistica.MODPATH.."/guide_api/guide_api.lua")
dofile(logistica.MODPATH.."/guide/guide.lua")
