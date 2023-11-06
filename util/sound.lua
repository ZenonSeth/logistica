
function logistica.node_sound_metallic()
  local tbl = {
    footstep = {name = "logistica_node_footstep", gain = 0.2},
    dig = {name = "logistica_node_dig", gain = 0.5},
    dug = {name = "logsitica_node_dug", gain = 0.5},
    place = {name = "default_place_node_hard", gain = 0.5},
  }
  default.node_sound_defaults(tbl)
  return tbl
end