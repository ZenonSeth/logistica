logistica.ui = {}

logistica.ui.background = "no_prepend[]bgcolor[#0000;true;#0008]background9[0,0;1,1;logistica_formspec_background.png;true;8]"
logistica.ui.background_lava_furnace = "no_prepend[]background9[0,0;1,1;logistica_lava_furnace_bg.png;true;8]"


local function list_dropdown(name, itemTable, x, y, default, label)
  local labelField = ""
  if label then labelField = "label["..x..","..(y-0.2)..";"..label.."]" end
  local defaultIndex = 0
  for i, v in ipairs(itemTable) do if default == v then defaultIndex = i end end
  local items = table.concat(itemTable, ",")
  return "dropdown["..x..","..y..";2,0.6;"..name..";"..items..";"..defaultIndex..";false]"..labelField
end

--------------------------------
-- public functions
--------------------------------

function logistica.ui.on_off_btn(isOn, x, y, name, label, w, h)
  if not label then label = "" end
  if not w or not h then
    w = 1; h = 1
  end

  local texture = (isOn and "logistica_icon_on.png" or "logistica_icon_off.png")
  return "image_button["..x..","..y..";"..w..","..h..";"..
        ""..texture..";"..name..";;false;false;"..texture.."]"..
        "label["..(x+0.1)..","..y..";"..label.."]"
end

function logistica.ui.pull_list_picker(name, x, y, pullFromPos, default, label)
  return list_dropdown(name, logistica.get_pull_lists(pullFromPos), x, y, default, label)
end

function logistica.ui.push_list_picker(name, x, y, pushToPos, default, label)
  return list_dropdown(name, logistica.get_push_lists(pushToPos), x, y, default, label)
end
