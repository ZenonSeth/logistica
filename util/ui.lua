logistica.ui = {}

logistica.ui.background = "no_prepend[]bgcolor[#0000]background9[0,0;1,1;logistica_formspec_background.png;true;8]"

-- returns a string of comma separated lists we're allowed to push to at the given pushToPos
local function get_lists(pushToPos, allowedLists)
  logistica.load_position(pushToPos)
  local availableLists = minetest.get_meta(pushToPos):get_inventory():get_lists()
  local pushLists = {}
  for name, _ in pairs(availableLists) do
    if allowedLists[name] then
      table.insert(pushLists, name)
    end
  end
  return pushLists
end


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

function logistica.ui.on_off_btn(isOn, x, y, name, showLabel, w, h)
  if showLabel == nil then showLabel = true end
  if not w or not h then
    w = 1; h = 1
  end
  local label=""
  if showLabel then label = "label["..(x+0.2)..","..y..";Power]" end

  local texture = (isOn and "logistica_icon_on.png" or "logistica_icon_off.png")
  return "image_button["..x..","..y..";"..w..","..h..";"..
        ""..texture..";"..name..";;false;false;"..texture.."]"..label
end

function logistica.ui.pull_list_picker(name, x, y, pullFromPos, default, label)
  return list_dropdown(name, get_lists(pullFromPos, logistica.ALLOWED_PULL_LISTS), x, y, default, label)
end

function logistica.ui.push_list_picker(name, x, y, pushToPos, default, label)
  return list_dropdown(name, get_lists(pushToPos, logistica.ALLOWED_PUSH_LISTS), x, y, default, label)
end
