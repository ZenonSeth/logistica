local path = logistica.MODPATH.."/util"

dofile(path.."/common.lua")
dofile(path.."/rotations.lua")
dofile(path.."/hud.lua")
dofile(path.."/ui_logic.lua")
dofile(path.."/ui.lua")
dofile(path.."/sound.lua")
dofile(path.."/inv_list_sorting.lua")
dofile(path.."/inv_list_filtering.lua")

-- bad debug
d = {}
d.ttos = logistica.ttos
d.log = minetest.chat_send_all
function d.table_map(self, f)
    local t = {}
    for k,v in pairs(self) do
        t[k] = f(v)
    end
    return t
end
function d.ltos(list)
    if not list then return "{NIL}" end
    return d.ttos(d.table_map(list, function(st) return st:to_string() end))
end