local path = logistica.MODPATH.."/util"

dofile(path.."/common.lua")
dofile(path.."/rotations.lua")
dofile(path.."/hud.lua")
dofile(path.."/ui_logic.lua")
dofile(path.."/ui.lua")
dofile(path.."/sound.lua")

-- bad debug
d = {}
d.ttos = logistica.ttos
d.log = minetest.chat_send_all
function table.map(self, f)
    local t = {}
    for k,v in pairs(self) do
        t[k] = f(v)
    end
    return t
end