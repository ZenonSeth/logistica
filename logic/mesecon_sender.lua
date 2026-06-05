
local ON_SUFFIX = "_on"

function logistica.mesecon_sender_get_name(pos)
  return minetest.get_meta(pos):get_string("signal_name")
end

function logistica.mesecon_sender_get_not(pos)
  return minetest.get_meta(pos):get_string("signal_not") == "1"
end

-- Swaps node to on/off variant. Mesecon receptor_on/off is handled by the api layer.
function logistica.mesecon_sender_set_visual(pos, isOn)
  local name = minetest.get_node(pos).name
  local isCurrentlyOn = name:sub(-#ON_SUFFIX) == ON_SUFFIX
  if isCurrentlyOn == isOn then return end
  local base = isCurrentlyOn and name:sub(1, -#ON_SUFFIX - 1) or name
  local newName = isOn and (base .. ON_SUFFIX) or base
  if minetest.registered_nodes[newName] then
    logistica.swap_node(pos, newName)
  end
end
