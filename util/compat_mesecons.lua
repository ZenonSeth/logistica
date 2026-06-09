local mesecon_pushers = minetest.get_modpath("mesecons_mvps")
local mesecons_is_present = minetest.get_modpath("mesecons")

local register_stopper = function(name, func) end
if mesecon_pushers then register_stopper = mesecon.register_mvps_stopper end

function logistica.register_non_pushable(nodeName)
  register_stopper(nodeName)
end

-- Mesecons apis are present.
function logistica.mesecons_is_present()
  return mesecons_is_present
end
