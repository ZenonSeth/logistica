
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
    title = "Signal (%s, %S)",
    content = [[
%s1, %s2, %s3, ... are placeholders which are replaced by the current state of the Nth signal listed in the Signals field.

%S1, %S2, %S3, ... are placeholders like above, but they resolve to a different format, primarily for use in "parse to table" mode.

Signals should be entered in the Signals field as a comma- or space-separated list, e.g.:
  alarm, pump_running, tooMuchCobble

%s1 resolves to "On" or "Off" (without quotes) based on whether the first signal is currently ON in the network.

%S1 resolves to "true" or "false" (without quotes) based on whether the first signal is currently ON in the network.

If a signal is not present on the network it is treated as OFF.

If you use %s4 (or %S4) but only have 3 signals configured, a warning is shown and the placeholder is left as-is.
    ]],
  },
  {
    title = "Item (%i, %I)",
    content = [[
%i1 through %i8 are placeholders which are replaced by the count of items matching the corresponding filter slot in the network.
%I1 through %I8 are placeholders which are replaced similarly, but the count does not include items that are below the "reserved" threshold in mass storage devices.

Place an item in filter slot N to set what %iN/%IN counts. Crafting suppliers are excluded from the count.

If filter slot N is empty, %iN/%IN resolves to "n/a" and a warning is shown.

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

local API_HELP_TOPICS = {
  {
    title = "Experimental features",
    color = "#FFFF88",
    content = "Features below this line are experimental and may change in the future",
  },
  {
     title = "API: Overview",
     color = "#FFFF88",
 
     content = [[
The Digiline Signal Sender can itself be controlled by a digilines api, using the same channel that it's configured to broadcast messages on.

This feature is only enabled if the 'Enable API programming' checkbox is checked.

The API currently has two "methods" - "configure" and "configure_raw". These are invoked by sending a table of the form:
```
{
  method = "configure" -- (or "configure_raw")
  params = {
    -- Various fields that each induce certain behaviour if present
  }
}
```
Fields set to `nil` are interpreted as "not present" (of particular note is for boolean fields, where you might want to use the expression `<your value> and true or false` in Lua to ensure a "truthy" value is in the correct type.

See the "API: Common Config Fields" section for information on the fields common to both "configure" and "configure_raw" methods.

See the "API: Raw Config Fields" section for information on the fields specific to "configure_raw", an API that controls various properties of the Digilines Sender individually

See the "API: Structured Config" section for information on the fields specific to "configure", an API that provides more structured and automatic configuration of the digilines sender, with a focus on sending tables of well-typed information for further processing or use.
]]
  },
  {
    title = "API: Common Config Fields",
    color = "#FFFF88",

    content = [[
The following fields are common to the parameters of both "configure" and "configure_raw" APIs, and have the same behaviour in each.

# `enable` (boolean)
This field enables automated enabling/disabling of the Digiline Signal Sender.

# `channel` (string)
This field enables changing the channel the Digiline Signal Sender broadcasts (and listens for API calls) on. It's a string. 

An empty string will prevent it from listening or broadcasting at all. It's also important to remember that if you're controlling it with a fixed channel, then you'll lose automated control of the device unless you change the channel you send on (or that it receives on) manually.
]]
  },
  {
    title = "API: Raw Config Fields",
    color = "#FFFF88",

    content = [[
The following fields are specific to the parameters of the "configure" API, and provide maximum flexibility but require more complex code/messages for more advanced automated information management.

# `message` (string)
If specified, this sets the message template of the Digilines Signal Sender, following the format (of substitution patterns, etc.) described in the "Overview" and sections on the available placeholders.

Setting the `params` field in the parent table to a string rather than a table (when method = "configure_raw") is interpreted as a shorthand form of using this field.

Sending a string to the Digiline Signal Sender (rather than a table structure with API calls) is interpreted similarly.

# `signals` (string or array of strings)
If specified, this allows you to set the signals available for substitution on the Digiline Signal Sender.

When it's a single string, it's interpreted as a comma-separated list of signal names (that undergo "sanitization" later), essentially the same as the signal field in the GUI.

When it's an array, each element must be a string, and it's composed into the list of signal names for the Digilines Signal Sender to use in the placeholders (these signal names are also sanitized, but before insertion into the Digilines Signal Sender).

# `items` (array of strings)
If specified, this allows you to set the items in the "filter" slots to get information on. If the array is longer than the number of available slots, it will be truncated.

The strings are in the form used internally by luanti (such as "default:dirt"). Empty strings induce the creation of an empty slot at the relevant position, and invalid names will just create "unknown item" filters that have essentially no purpose.

# `parse_as_table` (boolean)
If specified, this sets whether or not the message of the Digilines Signal Sender should be parsed as a table before being sent over digilines. 
]]
  },
  {
    title = "API: Structured Config",
    color = "#FFFF88",

    content = [[
The structured configuration API involves only one field - `message` - that describes an arbitrarily-nested structure, where you can specify that fields of a table should be substituted for various values.

It will automatically fill in slots with the needed items (but not more than the available filter slots), set `parse_as_table`, apply the signals, and so on, as required to do this. 

The API itself works by recursively traversing the sent table and detecting table fields with a "ty" entry ("template specifiers"), that specifies what value they should be replaced with and what other fields are expected there. Example:
```
{
  ty = "item",
  name = "default:dirt"
}
```
This would fill in the slots appropriately such that this field would be filled in with the count of available un-reserved dirt on the network (setting `respect_reserve=false` would count all dirt, even reserved). The structure of these "template specifiers" is checked - i.e. no extra or invalid fields are allowed.

Such "template specifiers" may also have "shorthand strings" for concise specification. Shorthand strings are of the form `<prefix>::<suffix>`, and are essentially converted to template specifiers (if you have a string that you need to ensure does not get transformed, prefix it with `lit::`).

For the above example, the shorthand string would look like "item::default:dirt". Shorthand strings are documented along with the template specifiers.

Other than the shorthand string mechanism, primitives are passed through the whole process unaltered - numbers and booleans and strings alike.

# Item Template Specifier (`ty = "item"`)
The item template specifier has a `ty` value of "item".

It has a mandatory string field `name`, which lets you control the item this refers to, using the luanti-internal itemstrings (such as "default:dirt"). Empty strings aren't valid.

It has an optional boolean field `respect_reserve` (default is true), which determines whether or not to count reserved items in the network when replacing the template specifier with the item counts. `true` means don't include reserved items in the count (useful for automation, and the default), `false` neans do include reserved items in the count (useful for displays, graphing, comparison with reserves, etc.).

This has two associated shorthand string prefixes - "item" and "item-all":
- "item::<item name>" is equivalent to the item template specifier with the given name and `respect_reserve = true` (counts unreserved items)
- "item-all::<item name>" is equivalent to the item template specifier with the given name and `respect_reserve = false` (counts all items)

It should be noted that, while item template specifiers automatically allocate slots and intelligently reuse them for all references to the same item, they can't use more than the available slots, so you must have less than or equal to that number of distinct items (but you can reference each one as many times as you like within the structured configuration template).

# Signal Template Specifier (`ty = "signal"`)
The signal template specifier has a `ty` value of "signal".

It has a mandatory string field "name", which lets you control the signal this refers to (automatically sanitized - bad names will be rejected).

It has an optional boolean field `bool_mode` (default is true), which controls whether to replace this field with a boolean (`true` or `false`), or to replace it with a string ("On" or "Off").

This has two associated shorthand string prefixes - "signal" and "signal-str":
- "signal::<signal name>" is equivalent to the signal template specifier with the given signal name and `bool_mode = true`.
- `signal-str::<signal name>` is equivalent to the signal template specifier with the given signal name and `bool_mode = false`.

# Literal Specifier (`ty = "literal"`)
This specifier has a `ty` value of "literal", and it's used to pass it's contents through without any further processing (other than removal of unsafe datatypes like functions, and removing the top-level `ty = "literal"` field from the top-level table).

It has no string shorthand equivalent because it's primarily for tables, though conceptually the "lit::" prefix is similar in nature.

# Nested Template Specifier (`ty = "nest"` or no `ty` field)
This is the "default" `ty` specifier, which is used to indicate that the table it's in needs further recursion. It's also what's assumed for tables lacking a type specifier field (other than those within a "literal" specifier).

It results in all values within the table - for every string, boolean, or numerical key (e.g. in an array) - being replaced with their template substitution in the resultant message. The only exception is the `ty` field, which if actually present and not just taken as default, is removed.

# Examples
This may be easier to illustrate with some example structured templates (which should be sent as the value of the `message` field of the params of the "configure" method):

Creating an array of 3 metal infos:
```
message = {
  [1] = { available = "item::default:gold_ingot", all = "item-all::default:gold_ingot" },
  [2] = { available = "item::default:iron_ingot", all = "item-all::default:iron_ingot" }
  [3] = { available = "item::default:copper_ingot", all = "item-all::default:copper_ingot" }
}
```

Getting some automation indicators for a process, using both signals and quantity of some item:
```
message = {
  automation_allowed = "signal::automation_enabled",
  possible_item_bundles = {
    -- Imagine this being programmatically generated
    [1] = {
      cost_weight = 10,
      ["default:iron_ingot"] = {
        needed = 4,
        available = {
          ty = "item",
          name = "default:iron_ingot"
        }
      }, 
      ["default:stick"] = {
        needed = 2,
        available = {
          ty = "item",
          name = "default:stick"
        }
      }
    },
    [2] = {
      cost_weight = 100,
      ["default:diamond"] = {
        needed = 1, 
        available = {
          ty = "item",
          name = "default:diamond"
        }
      },
      ["default:gold_ingot"] = {
        needed = 1,
        available = {
          ty = "item",
          name = "default:gold_ingot"
        }
      }
    }
  }
}
```
]]
  }
}

if logistica.settings.enable_digiline_sender_api then
  for _, t in ipairs(API_HELP_TOPICS) do
    HELP_TOPICS[#HELP_TOPICS + 1] = t
  end
end

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
  local parseTable  = meta:get_string("parse_as_table") == "1"
  local apiEnabled  = meta:get_string("api_enabled") == "1"
  local isOn        = logistica.is_machine_on(pos)

  local slotLabels = {}
  for i = 1, NUM_SLOTS do
    local sx = SLOT_X + (i - 1) * 1.25
    slotLabels[#slotLabels + 1] = string.format(
      "label[%.2f,%.2f;%%i%d]", sx + 0.1, SLOT_Y + 1.2, i)
  end

  local warnLine = warning ~= "" and "label[2.5," .. (SLOT_Y - 0.6)..";" .. minetest.formspec_escape(minetest.colorize("#FF8000", "Warning: " .. warning)) .. "]" or ""

  local apiCheckbox = ""
  if logistica.settings.enable_digiline_sender_api then
    apiCheckbox =
      "checkbox[6.5,1.15;api_enabled;" .. FS("Enable API programming") .. ";" .. (apiEnabled and "true" or "false") .. "]" ..
      "tooltip[api_enabled;" .. FS("See API Overview in Help tab for details") .. "]"
  end

  return
    -- title + enable
    "label[0.5,0.35;" .. FS("Digiline Signal Sender") .. "]" ..
    logistica.ui.on_off_btn(isOn, 10.5, 0.4, ON_OFF_BTN, FS("Enable"), 1.0, 1.0) ..
    -- channel
    "label[0.5,1.15;" .. FS("Channel:") .. "]" ..
    "field[2.0,0.8;4.0,0.75;channel;;" .. minetest.formspec_escape(channel) .. "]" ..
    apiCheckbox ..
    -- signal names
    "label[0.5,1.9;" .. FS("Signals:") .. "]" ..
    "label[6.3,1.9;" .. FS("(%s1 = 1st, %s2 = 2nd, ...)") .. "]" ..
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
    items[#items + 1] = (t.color or "") .. minetest.formspec_escape(t.title)
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

  if fields.api_enabled ~= nil then
    minetest.get_meta(pos):set_string("api_enabled", fields.api_enabled == "true" and "1" or "0")
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
      effector = { action = logistica.digiline_sender_on_receive_digilines_message },
    },
    _mcl_hardness         = 1.5,
    _mcl_blast_resistance = 10,
  }

  minetest.register_node(lname, def)
  logistica.register_non_pushable(lname)
  logistica.GROUPS.misc_machines.register(lname)
end
