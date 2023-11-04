logistica = {}

logistica.MODNAME = minetest.get_current_modname() or "logistica"
logistica.MODPATH = minetest.get_modpath(logistica.MODNAME)

-- order of loading files DOES matter
dofile(logistica.MODPATH.."/util/util.lua")
dofile(logistica.MODPATH.."/logic/logic.lua")
dofile(logistica.MODPATH.."/tools/tools.lua")

-- api should be below the other files except the registrations
dofile(logistica.MODPATH.."/api/api.lua")
