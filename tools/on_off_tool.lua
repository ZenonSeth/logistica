local S = logistica.TRANSLATOR

local function toggle_machine(pos, player)
  local playerName = player:get_player_name()
  if not logistica.player_has_network_access(pos, playerName) then
    logistica.show_popup(playerName, S("Cannot toggle: no access"))
    return
  end
  local isOn = logistica.toggle_machine_on_off(pos)
  if isOn == nil then return end
  minetest.sound_play(isOn and "on" or "off", { to_player = playerName, gain = 0.5, pitch = 0.7 })
  logistica.show_popup(playerName, isOn and S("Machine: ON") or S("Machine: OFF"))
end

minetest.register_tool("logistica:on_off_tool", {
  description = S("On/Off Tool\nPunch a machine to toggle its on/off state"),
  short_description = S("On/Off Tool"),
  inventory_image = "logistica_on_off_tool.png",
  wield_image = "logistica_on_off_tool.png",
  stack_max = 1,
  on_use = function(itemstack, user, pointed_thing)
    if not user or not user:is_player() then return end
    if pointed_thing.type ~= "node" then return end
    toggle_machine(pointed_thing.under, user)
  end,
})
