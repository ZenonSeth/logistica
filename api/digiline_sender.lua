
if not minetest.get_modpath("digilines") then return end

local FS   = logistica.FTRANSLATOR
local SIZE = logistica.settings.cable_size
local FORMSPEC_NAME = "logistica:digiline_sender"
local NUM_SLOTS  = 8
local ON_OFF_BTN = "onoffbtn"
local TAB_FIELD  = "dstab"
local HELP_LIST  = "dshelptbl"

local SLOT_X = 0.5
local SLOT_Y = 6.2

local HELP_TOPICS = {
  {
    title = "Overview",
    content = [[
The Digiline Signal Sender polls your Logistica network every second and sends a message on a Digilines channel whenever the resolved message changes.

Configure a channel, an optional list of signal names to monitor, optional item filter slots, and a message template with placeholders.

The message is only sent when its content changes from the last sent value, so downstream Digilines devices only receive updates on actual change.
    ]],
  },
  {
    title = "Signal (%s)",
    content = [[
%s1, %s2, %s3, ... are placeholder which are replaced by the current state of the Nth signal listed in the Signals field.

Signals should be entered in the Signald field as a comma- or space-separated list, e.g.:
  alarm, pump_running, tooMuchCobble

%s1 resolves to "On" or "Off" (without quotes) based on whether the first signal is currently ON in the network.

If a signal is not present on the network it is treated as Off.

If you use %s4 but only have 3 signals configured, a warning is shown and the placeholder is left as-is.
    ]],
  },
  {
    title = "Item (%i)",
    content = [[
%i1 through %i8 are placeholder which are replaced by the count of items matching the corresponding filter slot in the network.

Place an item in filter slot N to set what %iN counts. Crafting suppliers are excluded from the count.

If filter slot N is empty, %iN resolves to "n/a" and a warning is shown.

Example message:
  iron=%i1 coal=%i2

With 64 iron and 128 coal in the network, this sends:
  iron=64 coal=128
Note that its without quotes around them, so its sent as int.

If you want to send it as a string, instead write:
  iron="%i1" coal="%i2"

    ]],
  },
  {
    title = "Parse as table",
    content = [[
When "Parse as table" is checked, the resolved message string is parsed as a Lua table before sending.

Write a Lua table literal in the message field. Placeholders are substituted first, then the result is parsed.

Example:
  { iron = %i1, door = "%s1" }

With 64 iron and signal door_open = On, this sends the table:
  { iron = 64, door = "On" }

Rules:
- Plain Lua data only: strings, numbers, booleans, tables.
- No expressions, no function calls.
- String values must be quoted: "%s1" not %s1.
- Nested tables are allowed: { pos = { x = %i1, y = %i2 } }
- You do not need to write "return" at the front; it is added automatically.

If parsing fails, the send is skipped and a warning is shown.
    ]],
  },
  {
    title = "Tips",
    content = [[
The message is only sent when it changes. If all your placeholders resolve to the same values as last time, nothing is sent.

The enable toggle pauses all sends without losing configuration.

When disconnected from a Logistica network, the timer stops. Signals not on the network resolve to Off, item counts resolve to 0.

Validation warnings shown in the formspec are checked at save time and slot change time. Runtime parse errors (table mode) are written to the warning field when they occur.
    ]],
  },
}

local forms = {}

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------

local function get_tab(playerName)
  return (forms[playerName] and forms[playerName].tab) or 1
end

local function get_help_topic(playerName)
  return (forms[playerName] and forms[playerName].help_topic) or 1
end

local function save_text_fields(pos, fields)
  if fields.channel ~= nil or fields.signal_names ~= nil or fields.message ~= nil then
    logistica.digiline_sender_on_save(
      pos,
      fields.channel      or minetest.get_meta(pos):get_string("channel"),
      fields.signal_names or minetest.get_meta(pos):get_string("signal_names"),
      fields.message      or minetest.get_meta(pos):get_string("message")
    )
  end
end

----------------------------------------------------------------
-- settings tab
----------------------------------------------------------------

local function get_settings_tab(pos)
  local meta       = minetest.get_meta(pos)
  local posForm    = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
  local channel    = meta:get_string("channel")
  local sigNames   = meta:get_string("signal_names")
  local message    = meta:get_string("message")
  local warning    = meta:get_string("warning")
  local parseTable = meta:get_string("parse_as_table") == "1"
  local isOn       = logistica.is_machine_on(pos)

  local slotLabels = {}
  for i = 1, NUM_SLOTS do
    local sx = SLOT_X + (i - 1) * 1.25
    slotLabels[#slotLabels + 1] = string.format(
      "label[%.2f,%.2f;%%i%d]", sx + 0.1, SLOT_Y + 1.2, i)
  end

  local warnLine = ""
  if warning and warning ~= "" then
    warnLine = "label[0.5,9.2;" .. minetest.formspec_escape("Warning: " .. warning) .. "]"
  end

  return
    -- title + enable
    "label[0.5,0.35;" .. FS("Digiline Signal Sender") .. "]" ..
    logistica.ui.on_off_btn(isOn, 10.5, 0.4, ON_OFF_BTN, FS("Enable"), 1.0, 1.0) ..
    -- channel
    "label[0.5,1.1;" .. FS("Channel:") .. "]" ..
    "field[2.0,0.8;4.0,0.75;channel;;" .. minetest.formspec_escape(channel) .. "]" ..
    -- signal names
    "label[0.5,1.85;" .. FS("Signals:") .. "]" ..
    "label[6.3,1.85;" .. FS("(%s1 = 1st, %s2 = 2nd, ...)") .. "]" ..
    "field[2.0,1.55;4.0,0.75;signal_names;;" .. minetest.formspec_escape(sigNames) .. "]" ..
    -- message
    "label[0.5,2.55;" .. FS("Message:") .. "]" ..
    "textarea[0.5,2.8;11.0,2.5;message;;" .. minetest.formspec_escape(message) .. "]" ..
    -- filter slots
    "label[0.5," .. (SLOT_Y - 0.35) .. ";" .. FS("Item filters:") .. "]" ..
    "list[" .. posForm .. ";filter;" .. SLOT_X .. "," .. SLOT_Y .. ";8,1;0]" ..
    -- save + parse as table
    "button[4.5,7.75;3.0,0.75;save;" .. FS("Save") .. "]" ..
    "checkbox[8.0,8.1;parse_as_table;" .. FS("Parse as table") .. ";" .. (parseTable and "true" or "false") .. "]" ..
    table.concat(slotLabels) ..
    warnLine ..
    -- player inventory
    logistica.player_inv_formspec(0.5, 8.9) ..
    "listring[" .. posForm .. ";filter]" ..
    "listring[current_player;main]"
end

----------------------------------------------------------------
-- help tab
----------------------------------------------------------------

local function build_help_topic_list()
  local items = {}
  for _, t in ipairs(HELP_TOPICS) do
    items[#items + 1] = minetest.formspec_escape(t.title)
  end
  return table.concat(items, ",")
end

local function get_help_tab(playerName)
  local idx     = get_help_topic(playerName)
  local content = HELP_TOPICS[idx] and HELP_TOPICS[idx].content or ""
  return
    "textlist[0.3,0.4;3.2,13.0;" .. HELP_LIST .. ";" .. build_help_topic_list() .. ";" .. idx .. ";false]" ..
    "textarea[3.8,0.4;7.9,13.0;;;" .. minetest.formspec_escape(content) .. "]"
end

----------------------------------------------------------------
-- formspec entry point
----------------------------------------------------------------

local function get_formspec(pos, playerName)
  local tab    = get_tab(playerName)
  local header =
    "formspec_version[4]" ..
    "size[" .. logistica.inv_size(12.0, 14.2) .. "]" ..
    logistica.ui.background ..
    logistica.ui.button_only_style ..
    "tabheader[0,0;" .. TAB_FIELD .. ";" .. FS("Settings") .. "," .. FS("Help") .. ";" .. tab .. ";false;true]"

  if tab == 2 then
    return header .. get_help_tab(playerName)
  end
  return header .. get_settings_tab(pos)
end

function logistica.digiline_sender_show_formspec(playerName, pos)
  if not forms[playerName] then forms[playerName] = {} end
  forms[playerName].position = pos
  minetest.show_formspec(playerName, FORMSPEC_NAME, get_formspec(pos, playerName))
end

----------------------------------------------------------------
-- field handling
----------------------------------------------------------------

local function on_receive_fields(player, formname, fields)
  if formname ~= FORMSPEC_NAME then return false end
  if not player or not player:is_player() then return false end
  local playerName = player:get_player_name()
  local data = forms[playerName]
  if not data then return false end
  local pos = data.position
  if not pos then return false end
  if not logistica.player_has_network_access(pos, playerName) then return true end

  if fields.quit then
    forms[playerName] = nil
    return true
  end

  -- tab switch: save current text fields before switching
  if fields[TAB_FIELD] then
    local newTab = tonumber(fields[TAB_FIELD]) or 1
    if newTab ~= get_tab(playerName) then
      save_text_fields(pos, fields)
      forms[playerName].tab = newTab
    end
    logistica.digiline_sender_show_formspec(playerName, pos)
    return true
  end

  -- help topic selection
  if fields[HELP_LIST] then
    local evt = minetest.explode_textlist_event(fields[HELP_LIST])
    if evt.type == "CHG" then
      forms[playerName].help_topic = evt.index
      logistica.digiline_sender_show_formspec(playerName, pos)
    end
    return true
  end

  -- settings tab actions
  if fields[ON_OFF_BTN] then
    logistica.toggle_machine_on_off(pos)
  end

  if fields.parse_as_table ~= nil then
    logistica.digiline_sender_set_parse_as_table(pos, fields.parse_as_table == "true")
  end

  if fields.save
    or fields.key_enter_field == "channel"
    or fields.key_enter_field == "signal_names"
  then
    logistica.digiline_sender_on_save(
      pos,
      fields.channel      or "",
      fields.signal_names or "",
      fields.message      or ""
    )
  end

  logistica.digiline_sender_show_formspec(playerName, pos)
  return true
end

minetest.register_on_player_receive_fields(on_receive_fields)

minetest.register_on_leaveplayer(function(objRef)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

----------------------------------------------------------------
-- Public Registration API
----------------------------------------------------------------

function logistica.register_digiline_sender(desc, name, tiles)
  local lname = "logistica:" .. name

  local grps = { oddly_breakable_by_hand = 2, cracky = 2, handy = 1, pickaxey = 1 }
  grps[logistica.TIER_ALL] = 1

  local def = {
    description = desc,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "none",
    sunlight_propagates = true,
    node_box = {
      type = "connected",
      fixed = {
        {-0.5, -0.5, -0.5,  0.5, -6/16, 0.5},
        {-SIZE, -6/16, -SIZE, SIZE, 1/16, SIZE},
      },
      connect_top   = {-SIZE, -SIZE, -SIZE, SIZE, 0.5,  SIZE},
      connect_front = {-SIZE, -SIZE, -0.5,  SIZE, SIZE, SIZE},
      connect_back  = {-SIZE, -SIZE,  SIZE, SIZE, SIZE, 0.5 },
      connect_left  = {-0.5,  -SIZE, -SIZE, SIZE, SIZE, SIZE},
      connect_right = {-SIZE, -SIZE, -SIZE, 0.5,  SIZE, SIZE},
    },
    selection_box = {
      type = "fixed",
      fixed = { {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5} }
    },
    connects_to = { logistica.GROUP_ALL, logistica.GROUP_CABLE_OFF },
    connect_sides = {"top", "left", "right", "back", "front"},
    is_ground_content = false,
    tiles = tiles,
    groups = grps,
    drop = lname,
    sounds = logistica.node_sound_metallic(),
    after_place_node = logistica.digiline_sender_after_place,
    after_dig_node   = logistica.digiline_sender_after_dig,
    on_rightclick    = logistica.digiline_sender_on_rightclick,
    on_timer         = logistica.digiline_sender_timer,
    allow_metadata_inventory_put    = logistica.digiline_sender_allow_inv_put,
    allow_metadata_inventory_take   = logistica.digiline_sender_allow_inv_take,
    allow_metadata_inventory_move   = logistica.digiline_sender_allow_inv_move,
    on_metadata_inventory_put       = logistica.digiline_sender_on_inv_change,
    on_metadata_inventory_take      = logistica.digiline_sender_on_inv_change,
    logistica = {
      on_connect_to_network      = logistica.digiline_sender_on_connect,
      on_disconnect_from_network = logistica.digiline_sender_on_disconnect,
      on_power                   = logistica.digiline_sender_on_power,
    },
    digiline = {
      receptor = { rules = digilines.rules.default },
    },
    _mcl_hardness         = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(lname, def)
  logistica.register_non_pushable(lname)
  logistica.GROUPS.misc_machines.register(lname)
end
