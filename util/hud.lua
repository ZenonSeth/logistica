
local playerHud = {}

local SHORT_TIME = 3
local LONG_TIME = 10

function logistica.show_popup(playerName, text, time)
  if not time then time = SHORT_TIME end
  local player = minetest.get_player_by_name(playerName)
  if not player then return end

  if playerHud[playerName] then
    player:hud_remove(playerHud[playerName].hudId)
    playerHud[playerName].job:cancel()
    playerHud[playerName] = nil
  end
  local hudId = player:hud_add({
    hud_elem_type = "text",
    style     = 1,
    position  = {x = 0.5, y = 0.5},
    offset    = {x = 0, y = 40},
    text      = text,
    scale     = { x = 1, y = 1},
    alignment = { x = 0, y = 0 },
    number    = 0xDFDFDF,
  })
  playerHud[playerName] = {}
  playerHud[playerName].hudId = hudId
  local job = minetest.after(time, function()
    local pl = minetest.get_player_by_name(playerName)
    if not pl then return end
    if not playerHud[playerName] then return end
    pl:hud_remove(playerHud[playerName].hudId)
    playerHud[playerName] = nil
  end)
  playerHud[playerName].job = job
end
