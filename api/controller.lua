
--[[
  The definition table will get the fololwing fields overriden (and currently originals are not called):
  - on_construct
  - after_destruct
  - on_timer

  The definition must also provide a `logistica_controller` table. This table should contains:
  {
    get_max_demand_processing = function(pos)
    -- function that will be called to determine how many demand nodes this controller can process per tick

    get_max_storage_
  }

  simpleName is used for the node registration, and will, if necessary, be converted 
  to lowerspace and all spaces replaced with _

  tier may be `nil` which will result in the controller connecting to everything
]]
function logistica.register_controller(simpleName, def, tier)
  local controller_group = nil
  if not tier then
    tier = logistica.TIER_ALL
    controller_group = logistica.TIER_ALL
  else
    local ltier = string.lower(tier)
    logistica.tiers[ltier] = true
    controller_group = logistica.get_machine_group(ltier)
  end
 	local controller_name = "logistica:" .. string.lower(simpleName:gsub(" ", "_")) .. "_controller"
	logistica.controllers[controller_name] = tier

  local on_construct = function(pos)
      logistica.start_controller_timer(pos)
      logistica.on_controller_change(pos, nil)
  end
  local after_destruct = logistica.on_controller_change
  local on_timer = logistica.on_controller_timer

  if not def.groups then
    def.groups = {}
  end
  def.groups[controller_group] = 1
  def.on_construct = on_construct
  def.after_destruct = after_destruct
  def.on_timer = on_timer
  def.drop = controller_name

	minetest.register_node(controller_name, def)

	local def_disabled = {}
	for k, v in pairs(def) do def_disabled[k] = v end
  local tiles_disabled = {}
  for k, v in pairs(def.tiles) do tiles_disabled[k] = v.."^logistica_disabled.png" end
  def_disabled.tiles = tiles_disabled
  def_disabled.groups = { oddly_breakable_by_hand = 3 }
  def_disabled.on_construct = nil
  def_disabled.after_desctruct = nil
  def_disabled.on_timer = nil

	minetest.register_node(controller_name.."_disabled", def_disabled)
end

logistica.register_controller("Simple Controller", {
  description = "Simple Controller",
  tiles = { "logistica_silver_cable.png" },
  groups = {
    oddly_breakable_by_hand = 1,
  },
  sounds = default.node_sound_metal_defaults(),
  paramtype = "light",
  sunlight_propagates = false,
  drawtype = "normal",
  node_box = { type = "regular"},
})
