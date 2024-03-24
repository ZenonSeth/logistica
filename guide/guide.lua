local path = logistica.MODPATH .. "/guide"
logistica.Guide = {}
logistica.Guide.Desc = {}



dofile(path.."/guide_desc_howto.lua")
dofile(path.."/guide_desc_machines.lua")
dofile(path.."/guide_desc_items.lua")
dofile(path.."/guide_content.lua")
dofile(path.."/guide_item.lua")
