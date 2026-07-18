local FS = logistica.FTRANSLATOR

local FORMSPEC_NAME = "logistica_qcgen"

local function get_qcgen_formspec(pos)
  local network = logistica.get_network_or_nil(pos)
  local curr = logistica.network_get_quantum_cycles(network)
  local max = logistica.network_get_quantum_cycles_max()
  return "formspec_version[4]" ..
    "size[8,4]" ..
    logistica.ui.background ..
    "label[0.5,0.6;" .. FS("Quantum Cycle Generator") .. "]" ..
    "label[0.5,1.3;" .. FS("Burns lava from the Network to bank Quantum Cycles,") .. "]" ..
    "label[0.5,1.7;" .. FS("used by other machines to instantly finish work.") .. "]" ..
    "label[0.5,2.3;" .. FS("Only one Generator is required per Network -") .. "]" ..
    "label[0.5,2.7;" .. FS("additional Generators do not increase generation speed.") .. "]" ..
    "label[0.5,3.4;" .. FS("Network Quantum Cycles: ") .. curr .. "/" .. max .. "]"
end

local function on_qcgen_rightclick(pos, node, clicker)
  if not clicker or not clicker:is_player() then return end
  if logistica.should_hide_from_player(pos, clicker:get_player_name()) then return end
  minetest.show_formspec(clicker:get_player_name(), FORMSPEC_NAME, get_qcgen_formspec(pos))
end

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------
-- `simpleName` is used for the description and for the name (can contain spaces)
function logistica.register_quantum_cycle_generator(desc, name, tiles)
  local lname = string.lower(name:gsub(" ", "_"))
  local qcgen_name = "logistica:" .. lname
  logistica.GROUPS.quantum_generators.register(qcgen_name)
  local grps = {oddly_breakable_by_hand = 3, cracky = 3, handy = 1, pickaxey = 1}
  grps[logistica.TIER_ALL] = 1
  local def = {
    description = desc,
    drawtype = "normal",
    tiles = tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = grps,
    drop = qcgen_name,
    sounds = logistica.node_sound_metallic(),
    on_rightclick = on_qcgen_rightclick,
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(qcgen_name, def)
  logistica.register_non_pushable(qcgen_name)

  local def_disabled = table.copy(def)
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v .. "^logistica_disabled.png" end

  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3, cracky = 3, choppy = 3, not_in_creative_inventory = 1, pickaxey = 1, axey = 1, handy = 1 }
  def_disabled.on_rightclick = nil

  minetest.register_node(qcgen_name .. "_disabled", def_disabled)
end
