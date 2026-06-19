local NUM_SLOTS    = 8
local POLL_INTERVAL = 1.0
local STRUCTURED_SPEC_RECURSION_LIMIT = 32

-- keyed by pos hash; stores last sent message string to avoid redundant sends
local last_sent = {}

-- Apply a function to all elements of the array, returning a new array, with any value that returns `nil` being removed.
local function filter_map(array, map_fn) 
  local result = {}
  for _, v in ipairs(array) do
    local res = map_fn(v)
    if res ~= nil then
      result[#result + 1] = res
    end
  end
  return result
end


-- Either return v if it's not nil, else return the output of calling default()
local function or_else_default(v, default)
  if v == nil then return default() else return v end
end

-- Either return v if it's not nil, else return the default value directly (for expensive defaults, use or_else_default)
local function or_default(v, default)
  if v == nil then return default else return v end
end

local function pos_hash(pos)
  return minetest.hash_node_position(pos)
end


-- API for correctly managing access to the metadata, doing things "atomically" with a finalisation function.
--
-- Uses an internal map to document "changes", and some of these have a more strongly-typed structure than the stringly-typed 
-- metadata map used in finalisation.
local metadata_api = {}

-- Create a new metadata accessor for the digiline sender at the given location. 
function metadata_api.new(pos)
  -- use metatables to do "methods" :3
  return setmetatable({
    pos = pos,
    meta = minetest.get_meta(pos),
    delta = {},
    -- Special marker for handling inventory changes.
    inventory_modified = false
  }, { __index = metadata_api })
end

-- Get the underlying channel. If the channel has been updated then returns the updated channel. 
function metadata_api:get_channel() 
  return self.delta.channel or self.meta:get_string("channel")
end

-- Set the underlying channel (str). In actuality, this sets the channel in the calculated deltas if it's different, to be written upon finalisation.
function metadata_api:set_channel(channel)
  if channel ~= self:get_channel() then
    self.delta.channel = channel
  end
end

-- Get a copy of the signal names as a raw unsanitized string.
function metadata_api:get_signal_names_raw() 
  return self.delta.signal_names or self.meta:get_string("signal_names")
end

local function parse_signal_list(str)
  local list = {}
  for token in str:gmatch("[^%s,]+") do
    local s = logistica.sanitize_signal_name(token)
    if s and s ~= "" then
      list[#list + 1] = s
    end
  end
  return list
end

-- Get a copy of the signal names as a list of sanitized signal name strings (stored internally as a single string).
function metadata_api:get_signal_names()
  local underlying_string = self:get_signal_names_raw()
  return parse_signal_list(underlying_string)
end

-- Set the signal names as a raw, unsanitized string. If it's the same as the existing one it will not do anything. 
function metadata_api:set_signal_names_raw(signal_names)
  if signal_names ~= self:get_signal_names_raw() then 
    self.delta.signal_names = signal_names
  end
end

-- Set the signal names from a list table. It should be noted that signal names are sanitized before being combined into a string 
-- (i.e. any non-[0-9a-z_] characters are removed ^.^)
function metadata_api:set_signal_names(signal_names)
  local fixed_signal_names = filter_map(signal_names, logistica.sanitize_signal_name)
  local combined_signal_names = table.concat(fixed_signal_names, ",")
  if combined_signal_names ~= self:get_signal_names_raw() then
    self.delta.signal_names = combined_signal_names
  end
end


-- Get access to the inventory, but only for reading. If you do modify the inventory (or just want to mark it as such) see the :modify_inv() method
function metadata_api:readonly_inventory()
  return self.meta:get_inventory()
end

-- Apply a modification to the inventory (marks it as modified). If you use this function at all, you *must* call `self:finalize()`!. Note that this can 
-- also be used to force-reset the cache anyway.
--
-- If the parameter is not supplied, then this just marks the inventory as modified. If the parameter _is_ supplied, then it should be a function 
-- taking an InvRef (see: https://api.luanti.org/class-reference/#nodemetaref). The function can return any values and those values will be 
-- forwarded as results of the outer method.
function metadata_api:modified_inventory(modifier_function)
  self.inventory_modified = true
  if modifier_function ~= nil then 
    return modifier_function(self.meta:get_inventory())
  end
end

function metadata_api:get_parse_as_table()
  return or_else_default(self.delta.parse_as_table, function() return self.meta:get_string("parse_as_table") == "1" end) and true or false
end

-- Update whether or not to parse the template as a table, passed in as a bool.
function metadata_api:set_parse_as_table(parse_as_table_bool)
  parse_as_table_bool = parse_as_table_bool and true or false
  if self:get_parse_as_table() ~= parse_as_table_bool then
    self.delta.parse_as_table = parse_as_table_bool and true or false
  end
end

-- Get the message template as a raw string
function metadata_api:get_message_template_raw()
  return self.delta.message or self.meta:get_string("message")
end


-- Set the message template as a raw string. May or may not be used with `set_parse_as_table`
function metadata_api:set_message_template_raw(raw_message_template) 
  if self:get_message_template_raw() ~= raw_message_template then
    self.delta.message = raw_message_template
  end
end



-- Set the message template. This clears all warnings, as warnings come from invalid message templates. Finalization is necessary after
-- doing this, and that will re-check templates. If you pass `true` as a second argument, it will keep all pending warnings on the construction, 
-- while still replacing the ones in the digilines sender.
function metadata_api:set_message_template(message_template, keep_pending_warnings)
  self:set_message_template_raw(message_template) 
  self:clear_warnings(keep_pending_warnings)
end


local function validate_template_v(template, signal_list, inventory, add_warning_fn) 
  for kind, nstr in template:gmatch("%%([sSiI])(%d+)") do
    local n = tonumber(nstr)
    if kind == "s" or kind == "S" then
      if not n or n < 1 or n > #signal_list then
        add_warning_fn("%s" .. nstr .. " needs signal " .. nstr .. " but only " .. #signal_list .. " configured")
      end
    else
      if not n or n < 1 or n > NUM_SLOTS then
        add_warning_fn("%i" .. nstr .. " is out of range (1-" .. NUM_SLOTS .. ")")
      elseif inventory:get_stack("filter", n):is_empty() then
        add_warning_fn("%i" .. nstr .. " slot " .. nstr .. " is empty")
      end
    end
  end
end

-- Revalidate the message template, adding any necessary warnings and such.
-- 
-- Is performed automatically upon finalisation (using any inventory modification and such) to add any needed warnings.
function metadata_api:revalidate_message_template()
  validate_template_v(self:get_message_template_raw(), self:get_signal_names(), self:readonly_inventory(), function(w) self:add_warning(w) end)
end

-- Create means of resolving a message and automatically adding warnings to something with the function.
local function resolve_message_raw_v(networkId, template, signals, inventory, add_warning_fn)  
  local network = networkId and logistica.get_network_by_id_or_nil(networkId)
  local result = template:gsub("%%([SsIi])(%d+)", function(kind, nstr)
    local n = tonumber(nstr)
    if kind == "s" or kind == "S" then
      local bool_mode = {
        s = false,
        S = true
      }
      if not n or n < 1 or n > #signals then
        add_warning_fn("%s" .. nstr .. " out of range")
        return "%s" .. nstr
      end
      local sigName = signals[n]
      local isOn = network and logistica.signal_get_state(networkId, sigName) or false
      if bool_mode[kind] then
        return isOn and "true" or "false" 
      else 
        return isOn and "On" or "Off"
      end
    else -- kind == "i" or "I"
      local respect_reserve = {
        i = false,
        I = true
      }

      if not n or n < 1 or n > NUM_SLOTS then
        add_warning_fn("%i" .. nstr .. " out of range")
        return "%i" .. nstr
      end
      local stack = inventory:get_stack("filter", n)
      if stack:is_empty() then
        add_warning_fn("%i" .. nstr .. " slot is empty")
        return "n/a"
      end
      local count = network
        and logistica.count_items_in_network(stack:get_name(), network, respect_reserve[kind])
        or 0
      return tostring(count)
    end
  end)
  return result
end 

-- Resolve the "typical" API message to send. Returns only the raw string version, and adds warnings as appropriate (you need to finalize() after
-- using this for the warnings to work).
function metadata_api:resolve_message_raw(networkId)
  return resolve_message_raw_v(networkId, self:get_message_template_raw(), self:get_signal_names(), self:readonly_inventory(), function(w) 
    self:add_warning(w)
  end)
end

-- Function to add a warning to the warnings of this construction (if there were some already on the digilines sender this will replace them)
function metadata_api:add_warning(warning_string)
  self.delta.warning = self.delta.warning or {}
  self.delta.warning[#self.delta.warning + 1] = core.formspec_escape(warning_string)
end

-- Reset the warnings stored in this construction. Be careful when using this. This will also prevent wiping the existing warnings on finalisation.
function metadata_api:remove_pending_warnings()
  self.delta.warning = nil
end

-- Clear any existing warnings in the existing digilines sender, and by-default in this construction too (if you pass `true` to this method it will keep 
-- the warnings in this construction and _replace_ the warnings in the digilines sender with them).
function metadata_api:clear_warnings(keep_pending_warnings)
  if keep_pending_warnings then
    self.delta.warning = self.delta.warning or {}
  else 
    self.delta.warning = {}
  end
end


local function try_parse_as_table(str)
  local s = str:match("^%s*(.-)%s*$")
  if s:sub(1, 6) ~= "return" then s = "return " .. s end
  return minetest.deserialize(s, true)
end

-- Create the actual message from relevant data. This may produce warnings, so you should finalize().
--
-- Argument is the network ID. This will return the message to send (either a string or parsed-to-table), returning _nil_ if the message is the 
-- same as the cached one  (unless `force` is set to true in which case the message is always built regardless). This will update the cache.
--
-- If the message fails to construct (in particular if it's to be parsed as a table and yet fails this), then nil will also be returned, 
-- and a warning will be added to the warning list.
function metadata_api:create_message_to_send_cached(networkId, force)
  local message_raw = self:resolve_message_raw(networkId)
  local hash = pos_hash(self.pos)
  if last_sent[hash] == message_raw and not force then return end

  -- Update cache.
  last_sent[hash] = message_raw
  if self:get_parse_as_table() then
    local parsed = try_parse_as_table(message_raw)
    if parsed == nil then
      self:add_warning("Table parse failed - check message syntax")
      return nil
    end
    return parsed
  else
    return message_raw
  end

end

-- Perform sending of the template data, calculating the message and so on.
--
-- This may produce warnings, so you should always finalise this also.
function metadata_api:send_template_message(networkId)
  if not minetest.get_modpath("digilines") then return end

  local channel = self:get_channel()
  if not channel or channel == "" then return end 
  local maybe_payload = self:create_message_to_send_cached(networkId, false)

  if maybe_payload ~= nil then
    digilines.receptor_send(self.pos, digilines.rules.default, channel, maybe_payload)
  end
end


-- Finalisation function. This performs all state changes and actions required to apply the relevant changes. It also returns the boolean 
-- on if it's changed (in particular, this is useful in formspecs to resend if necessary). The structure should be considered unusable after
-- calling this function (and in fact it will wipe it's own fields to ensure this).
-- 
-- Note that this makes some changes that may require resending messages. However, for now, the block is based upon polling, which means that 
-- this will happen automatically (but in future, full notification-based network queue systems are a possibility ^.^, in which case 
-- this function would also be where the logistica network is notified).
function metadata_api:finalize()
  -- Perform revalidation of template ^.^
  self:revalidate_message_template()

  -- Anything indicating a change will result in this being set to true.
  local has_changed = false
  has_changed = has_changed or self.inventory_modified
  -- Anything specific to messaging
  local has_message_changed = false
  local needs_infotext_update = false


  if self.delta.parse_as_table ~= nil then
    has_changed = true
    has_message_changed = true
    self.meta:set_string("parse_as_table", self.delta.parse_as_table and "1" or "0")
  end

  if self.delta.warning ~= nil then
    local final_warning = table.concat(self.delta.warning, "; ")
    if self.meta:get_string("warning") ~= final_warning then 
      has_changed = true
      self.meta:set_string("warning", final_warning)
    end
  end

  if self.delta.message ~= nil then
    has_changed = true
    has_message_changed = true
    self.meta:set_string("message", self.delta.message)
  end

  if self.delta.signal_names ~= nil then
    has_changed = true
    has_message_changed = true
    self.meta:set_string("signal_names", self.delta.signal_names)
  end

  if self.delta.channel ~= nil then
    has_changed = true
    has_message_changed = true
    needs_infotext_update = true
    self.meta:set_string("channel", self.delta.channel)
  end

  if needs_infotext_update then
    logistica.digiline_sender_update_infotext(self.pos)
  end

  if has_message_changed then
    last_sent[pos_hash(self.pos)] = nil
  end


  self.meta = nil
  self.pos = nil
  self.delta = nil
  self.inventory_modified = nil
  return has_changed
end

-- API table. These functions take a `metadata_api` structure and the raw message (and then dispatch to other functions that perform the relevant
-- actions). They finalize the metastruct themselves.
local api = {}

-- Process a new channel if non-nil (a string, warning will be given if it's not).
local function api_process_channel_modifier(metastruct, new_channel) 
  if new_channel == nil then return end
  if type(new_channel) ~= "string" then
    metastruct:add_warning("channel `" .. tostring(new_channel) .. "` was not a string")
    return
  end
  metastruct:set_channel(new_channel)
end

-- Process the enable/disable control if non-nil (a bool, if not a bool then warning will be given)
local function api_process_enable_modifier(metastruct, enable)
  if enable == nil then return end
  if type(enable) ~= "boolean" then 
    metastruct:add_warning("enable `" .. tostring(enable) .. "` was not a boolean")
    return
  end
  if logistica.is_machine_on(metastruct.pos) ~= enable then
    logistica.toggle_machine_on_off(metastruct.pos)
  end
end


-- Compilation of "common" fields processed by both the raw and structured APIs
--
-- Does not finalize the struct.
local function api_process_common(metastruct, dmsg)
  api_process_channel_modifier(metastruct, dmsg.channel)
  api_process_enable_modifier(metastruct, dmsg.enable)
end


local function api_process_parse_as_table_modifier(metastruct, parse_as_table)
  if parse_as_table == nil then return end 
  if type(parse_as_table) ~= "boolean" then 
    metastruct:add_warning("parse_as_table `" .. tostring(parse_as_table) .. "` was not a boolean")
    return
  end 
  metastruct:set_parse_as_table(parse_as_table)
end

-- Perform validation and normalization into `ItemStack` (including an empty stack) for use in the filter inventory.
--
-- Failures are attached as warnings to the metastack and result in returning `nil`. This means that this should induce total failure of the 
-- API to act.
--
-- The locator is a string to use in the warnings.
local function normalize_itemstack_for_filter_inv(metastruct, unvalidated_itemstring, locator)
  unvalidated_itemstring = unvalidated_itemstring or ""
  if type(unvalidated_itemstring) ~= "string" then 
    metastruct:add_warning(locator .. " = " .. tostring(unvalidated_itemstring) .. " was not a string or nil")
    return
  end
  local stack = ItemStack(unvalidated_itemstring)
  -- This avoids issues with giving "counts" to the "" stack, resulting in odd counted results.
  if not stack:is_empty() then
    stack:set_count(1)
    stack:set_wear(0)
  end
  return stack
end

local function api_process_items_modifier(metastruct, items)
  if items == nil then return end
  if type(items) ~= "table" then 
    metastruct:add_warning("items `" .. tostring(items) .."` was not a table of itemstrings")
    return
  end
  local new_itemstacks = {}
  for i = 1, NUM_SLOTS do
    local stack = normalize_itemstack_for_filter_inv(metastruct, items[i], "items[" .. tostring(i) .. "]")
    if stack == nil then return end
    new_itemstacks[i] = stack
  end
  metastruct:modified_inventory(function(inv) 
    for i = 1, NUM_SLOTS do 
      inv:set_stack("filter", i, new_itemstacks[i])
    end
  end)
end


local function api_process_signals_modifier(metastruct, signals)
  if signals == nil then return end
  if type(signals) == "string" then
    metastruct:set_signal_names_raw(signals)
  elseif type(signals) == "table" then
    for i, v in ipairs(signals) do
      if type(v) ~= "string" then 
        metastruct:add_warning("`signal name `signals[" .. tostring(i) .. "]` was not a string (was: `" .. tostring(v) .. "`)")
        return
      end
    end
    metastruct:set_signal_names(signals)
  else
    metastruct:add_warning("`signals` was not a string or a table (was: `" .. tostring(signals) .. "`)")
  end
end

-- Process a "raw message" modifier if not nil (should be a string :3)
local function api_process_message_modifier_raw(metastruct, message)
  if message == nil then return end
  if type(message) ~= "string" then
    metastruct:add_warning("`message` modifier was not a string (was: `" .. tostring(message) .. "`). If it was a table, maybe you wanted the structured configuration mode?")
    return
  end
  metastruct:set_message_template(message)
end


-- API method for configuring the thing "raw" - directly setting the string template, slots, and so on. This will provide validation of input to avoid 
-- crashes etc.
--
-- A "configure" method is also provided that does a lot more structured modification.
--
-- The message can take the form of a string (in which case it simply sets the message template), or it can take the form of 
-- a table with numerous fields - the presence of each indicating to overwrite that whole configuration state ^.^:
-- - `message` - the raw string message
-- - `signals` - the list of signals to make available, either as a string (the comma-separated list in the UI) or table of strings. Latter will be 
--   auto-sanitized :3
-- - `items` - A map of indices to itemstrings (e.g. "default:gold_ingot") to set in the slot. Must not be longer than the available slots or it 
--   will simply get cut off. Using `""` will result in an empty slot
-- - `parse_as_table` - boolean that if true indicates the message should be parsed as a table before sending and if false should be sent as a string.
-- - `enable` - boolean that, if specified, will enable or disable the digisender.
-- - `channel` - if specified, this allows writing to the channel the digisender uses. Note that this means that future messages to configure 
--   it need to be sent on the new channel (also an empty string will "permanently" until user reconfig prevent it sending/receiving messages)
--
--  Other fields (including the field used to determine the api method call) are ignored.
--`
--  This will finalise the metastruct.
function api.configure_raw(metastruct, dmsg)
  if type(dmsg) == "string" then
    dmsg = { message = dmsg }
  end
  if type(dmsg) ~= "table" then 
      metastruct:finalize()
      return 
  end
  api_process_common(metastruct, dmsg)
  api_process_parse_as_table_modifier(metastruct, dmsg.parse_as_table)
  api_process_items_modifier(metastruct, dmsg.items)
  api_process_signals_modifier(metastruct, dmsg.signals)
  api_process_message_modifier_raw(metastruct, dmsg.message)
  metastruct:finalize()
end

-- Adjustments and processing for structured table specification.
local structure_adjust = {}

-- Function that scans strings from structured specifications, and if they match the shorthand patterns, they are replaced with an appropriate table.
--
-- Returns `nil` and produces error in case of unrecognised prefix.
local function scan_structured_spec_string_translate(metastruct, spec_string)
  local prefix_mappers = {}
  prefix_mappers.item = function(remaining)
    return {
      ty = "item",
      name = remaining,
      respect_reserve = true
    }
  end
  prefix_mappers["item-all"] = function(remaining)
    return {
      ty = "item",
      name = remaining,
      respect_reserve = false
    }
  end
  prefix_mappers.signal = function(remaining)
    return {
      ty = "signal",
      name = remaining,
      bool_mode = true
    }
  end
  prefix_mappers["signal-str"] = function(remaining)
    return {
      ty = "signal",
      name = remaining,
      bool_mode = false
    }
  end
  prefix_mappers["lit"] = function(remaining) return remaining end

  local sep = "::"
  -- Find the raw separator if present, no magic characters (`plain` arg from the end ^.^), starting from the start.
  local found_start, found_end = string.find(spec_string, sep, 1, true)
  if found_start == nil then return spec_string end
  -- 1-based indexing makes this annoying. 
  --
  -- What helps in grokking this is that the `string.sub` function returns a prefix of the length of it's second index argument when the starting 
  -- arg is 1. So a match from index 2 onwards would need to subtract 1 to get the bit before it. 
  local prefix = string.sub(spec_string, 1, found_start - 1)
  local suffix = string.sub(spec_string, found_end + 1)
  local table_constructor = prefix_mappers[prefix]
  if not table_constructor then
    local allowed_prefixes = {}
    for k, _ in pairs(prefix_mappers) do
      allowed_prefixes[#allowed_prefixes + 1] = k
    end
    metastruct:add_warning(string.format(
      "unknown string shorthand prefix '%s' in string '%s' (allowed: %s)", 
      prefix, 
      spec_string, 
      table.concat(allowed_prefixes, ", ")
    ))
    return
  end
  return table_constructor(suffix)
end

-- This is the first stage of the two-stage structured specification process - allocation of slot-free table information, creating 
-- allocation data and then filling in the slots/signals. The item allocations and signals lists need to be provided as empty sets 
-- at the start (they will be both arrays and reverse-mapped arrays (indexed on names not tables like ItemStack used for the forward 
-- mapping), and can be used with the raw parsing). 
--
-- The recursion depth and existing allocations will be automatically initialized when needed and can prevent recursion beyond a certain point 
-- (which will result in a warning and returning nil, something that also happens with other parsing errors that then flow up the stack >.< 
--
-- This function will return a table like the one passed in, but with all the relevant dynamically allocated stuff replaced with a similar spec 
-- but with concrete slot numbers. It modifies the raw structured spec table directly. 
--
-- If the raw structured spec table is not actually a table, but is a bool, string, or number, then it's interpreted as a literal.
local function allocate_structured_specification(metastruct, raw_structured_spec, item_allocations, signals, recursion_depth)
  local allowed_non_table_types = {
    boolean = true,
    number = true,
    string = true,
  }

  -- Perform pre-processing of strings for shorthands.
  if type(raw_structured_spec) == "string" then
    raw_structured_spec = scan_structured_spec_string_translate(metastruct, raw_structured_spec)
    if raw_structured_spec == nil then return end
  end

  if type(raw_structured_spec) ~= "table" then
    if allowed_non_table_types[type(raw_structured_spec)] then
      return raw_structured_spec
    else
      metastruct:add_warning("disallowed structured spec type (not table/string/number/boolean), was: `" .. tostring(raw_structured_spec) .. "`")
      return
    end
  end
  local recursion_depth = recursion_depth or 0
  if recursion_depth > STRUCTURED_SPEC_RECURSION_LIMIT then
    metastruct:add_warning("Recursion limit of " .. tostring(STRUCTURED_SPEC_RECURSION_LIMIT) .. " exceeded by structured specification.")
    return
  end

  -- Default is nesting further down the tree :3
  local ty = raw_structured_spec.ty or "nest"
  if type(ty) ~= "string" then
    metastruct:add_warning("Invalid `ty` tag `" .. tostring(ty) .. "` in structured specification: not string")
    return
  end
  if not structure_adjust.allocation[ty] then
    local allowed_tags = {}
    for k, _ in pairs(structure_adjust.allocation) do
      allowed_tags[#allowed_tags + 1] = k
    end
    metastruct:add_warning("Invalid `ty` tag `" .. tostring(ty) .. "` in structured specification: must be one of: " .. table.concat(allowed_tags, ", "))
    return
  end
  return structure_adjust.allocation[ty](metastruct, raw_structured_spec, item_allocations, signals, recursion_depth + 1)
end


-- Create a valid textual representation of a _primitive_ table value that's allowed (i.e. only bool, number, or string). 
--
-- Returns nil and emits warnings in case of invalid types. 
local function represent_primitive_value_textual(metastruct, v)
    local value_repr = {}
    function value_repr.string(v)
      return string.format("%q", v)
    end
    function value_repr.boolean(v)
      return v and "true" or "false"
    end
    function value_repr.number(v)
      return tostring(v)
    end

    local proc = value_repr[type(v)]
    if proc then
      return proc(v)
    else
      metastruct:add_warning("Invalid value type: (value was: `" .. tostring(v) .. "`)")
      return
    end
end

-- This is the second stage of the two-stage structured specification process - creating the raw text message from the parsed-and-allocated structured
-- spec returned from `allocate_structured_specification`. 
--
-- See `structure_adjust.resolution` for what the arguments do.
local function build_structured_specification_message(metastruct, structured_spec, literal_mode, recursion_depth)
  if type(structured_spec) ~= "table" then
    return represent_primitive_value_textual(metastruct, structured_spec)
  end
  local recursion_depth = recursion_depth or 0
  if recursion_depth > STRUCTURED_SPEC_RECURSION_LIMIT then
    metastruct:add_warning("Recursion limit of " .. tostring(STRUCTURED_SPEC_RECURSION_LIMIT) .. " exceeded by structured specification.")
    return
  end
  -- If already in literal mode, we dive straight to literal transliteration, no messing with anything like tys or whatever. 
  if literal_mode then
    return structure_adjust.resolution.literal(metastruct, structured_spec, literal_mode, recursion_depth + 1)
  end
  -- Default is nesting further down the tree :3
  local ty = structured_spec.ty or "nest"
  return structure_adjust.resolution[ty](metastruct, structured_spec, literal_mode, recursion_depth + 1)
end

-- Adjustments for structures undergoing allocation of various types of slots and signals. Returns nil in case of failure, and the replacement 
-- table in case of success.
structure_adjust.allocation = {}

-- Transforms into the various matchable identifiers for the slots and signals that have now undergone allocation and replacement.
--
-- These take the metastruct (for error-reporting-while-returning_nil), the table spec itself (validated and allocated), literal_mode (
--  a boolean only ever true when recursing in the depths of literals and impossible to be true in anything other than the literals mechanism), 
--  and recursion_depth (the approximate depths of recursion, used in the main function to terminate if too deep).
structure_adjust.resolution = {}

-- Validate the non-name/non-ty fields of the item spec, returning back the table if successful or returning `nil` on failure
local function api_validate_structured_spec_item(metastruct, tbl)
  local validate = {}
  function validate.respect_reserve(metastruct, field)
    local field_value = or_default(field, true)
    if type(field_value) ~= "boolean" then
      metastruct:add_warning("non-boolean `respect_reserve` field not allowed, got: `" .. tostring(field) .. "`")
      return false
    else 
      return true
    end
  end
  function validate.name(metastruct, field)
    if type(field) ~= "string" then
      metastruct:add_warning("invalid itemname in structured specification: `" .. tostring(tbl.name) .. "`")
      return false
    else
      return true
    end
  end
  function validate.ty(_, _) return true end
  for k, v in pairs(tbl) do
    if not validate[k] then
      metastruct:add_warning("invalid field: `" .. tostring(k) .. "`")
      return
    elseif not validate[k](metastruct, v) then
      return
    end
  end
  return tbl
end

function structure_adjust.allocation.item(metastruct, tbl, item_allocations, _signals, _recursion_depth) 
  local tbl = api_validate_structured_spec_item(metastruct, tbl)
  if tbl == nil then return end 
  local filter_stack = normalize_itemstack_for_filter_inv(metastruct, tbl.name, "item in structured spec")
  local item_name = filter_stack:get_name()
  if filter_stack:is_empty() then
    metastruct:add_warning("empty item name/stack in structured specification")
    return 
  end
  local existing_slot = item_allocations[item_name]
  if existing_slot == nil then
    -- Now we allocate a new one.
    local next_slot = #item_allocations + 1
    item_allocations[next_slot] = filter_stack
    item_allocations[item_name] = next_slot
    existing_slot = next_slot
  end
  -- Wipe the "name" field - now unnecessary, replace with "slot" field nya ^.^
  tbl.name = nil
  tbl.slot = existing_slot
  return tbl
end

-- Perform emission of the correct string for the item slot and it's spec, delimited appropriately.
function structure_adjust.resolution.item(_metastruct, tbl, _literal_mode, _recursion_depth)
  if or_default(tbl.respect_reserve, true) then
    return string.format("%%I%u", tbl.slot)
  else
    return string.format("%%i%u", tbl.slot)
  end
end


-- Validate the fields of the signal spec, returning back the table if successful or returning `nil` on failure
local function api_validate_structured_spec_signal(metastruct, tbl)
  local validate = {}
  function validate.name(metastruct, field) 
    if type(field) ~= "string" then
      metastruct:add_warning("invalid signal name in structured specification, not string: `" .. tostring(tbl.name) .. "`")
      return false
    else
      return true
    end
  end
  function validate.ty(_, _) return true end
  function validate.bool_mode(metastruct, field)
    local field_value = or_default(field, true)
    if type(field_value) ~= "boolean" then
      metastruct:add_warning("non-boolean `bool_mode` field not allowed, got: `" .. tostring(field) .. "`")
      return false
    else 
      return true
    end
  end
  for k, v in pairs(tbl) do
    if not validate[k] then
      metastruct:add_warning("invalid field: `" .. tostring(k) .. "`")
      return
    elseif not validate[k](metastruct, v) then
      return
    end
  end
  return tbl
end


function structure_adjust.allocation.signal(metastruct, tbl, _item_allocations, signals, _recursion_depth)
  local tbl = api_validate_structured_spec_signal(metastruct, tbl)
  if tbl == nil then return end

  local sanitized_signal_name = logistica.sanitize_signal_name(tbl.name)
  if sanitized_signal_name == "" then
    metastruct:add_warning("invalid signal name `" .. tbl.name .. "` - sanitized to empty string")
    return
  end
  local existing_slot = signals[sanitized_signal_name]
  if existing_slot == nil then
    -- Allocate a new one ^.^
    local next_slot = #signals + 1
    signals[next_slot] = sanitized_signal_name
    signals[sanitized_signal_name] = next_slot
    existing_slot = next_slot
  end
  -- Wipe the name field and add the slot field
  tbl.name = nil
  tbl.slot = existing_slot
  return tbl
end

-- Perform emission of the correct string for the signal slot and it's spec, delimited appropriately.
function structure_adjust.resolution.signal(_metastruct, tbl, _literal_mode, _recursion_depth)
  if or_default(tbl.bool_mode, true) then
    return string.format("%%S%u", tbl.slot)
  else
    -- This is for insertion as a table field, so we _always_ want to wrap in a string as "On" and "Off" aren't exactly valid lua values on their own xD
    return string.format("\"%%s%u\"", tbl.slot)
  end
end

-- Create a valid textual representation of a table key (something that can be put _directly_ in front of the equals sign, including `[` and `]` ^.^). 
--
-- Returns nil and emits warnings in case of invalid types. 
local function represent_key_textual(metastruct, k)
    local key_repr = {}
    function key_repr.string(k)
      return string.format("[%q]", k)
    end
    function key_repr.boolean(k)
      return k and "[true]" or "[false]"
    end
    function key_repr.number(k)
      return string.format("[%s]", tostring(k))
    end

    local proc = key_repr[type(k)]
    if proc then
      return proc(k)
    else
      metastruct:add_warning("Invalid key type: (key was: `" .. tostring(k) .. "`)")
      return
    end
end

-- Special case - this induces literal conversion, leaving its contents entirely unprocessed (this also goes for the resolution step other 
-- then for the removal of the ty field).
function structure_adjust.allocation.literal(metastruct, tbl, _item_allocations, _signals, _recursion_depth)
  return tbl
end

-- Create the textual repr of `k = v` for building a table. Needs literal_mode and recursion_depth to pass down
local function represent_kv_pair_textual(metastruct, k, v, literal_mode, recursion_depth)
  -- Get textual representation of the key and the value
  local k_text = represent_key_textual(metastruct, k)
  if k_text == nil then 
    -- If the processed value is nil, that means there's an error in the spec! 
    --
    -- We actually want to report each key that failed. This should help in debugging tables.
    metastruct:add_warning("nested structured spec key `" .. tostring(k) .. "` failed to resolve")
    return
  end
  local v_text = build_structured_specification_message(metastruct, v, literal_mode, recursion_depth)
  if v_text == nil then 
    metastruct:add_warning("nested structured spec value `" .. tostring(v) .. "` failed to resolve")
    return
  end
  return string.format("%s = %s", k_text, v_text)
end

function structure_adjust.resolution.literal(metastruct, tbl, literal_mode, recursion_depth)
  -- In literal mode, we've already performed top-level literal trimming (in the first bit that goes literal, which is this function 
  -- while literal_mode = false), so no need to filter .ty fields unless top-level literal :)
  local kv_pairs_list = {}
  for k, v in pairs(tbl) do
    if literal_mode or k ~= "ty" then
      local kv_text = represent_kv_pair_textual(metastruct, k, v, true, recursion_depth)
      if kv_text == nil then return end
      kv_pairs_list[#kv_pairs_list + 1] = kv_text
    end
  end
  return string.format("{%s}", table.concat(kv_pairs_list, ", "))
end

-- The function used for general table recursion when there's no special type tag (tho could also be specified explicitly)
function structure_adjust.allocation.nest(metastruct, tbl, item_allocations, signals, recursion_depth)
  local result_tbl = {}
  -- Return the type to what it is meant to be (we filter out the ty key when doing further processing. 
  result_tbl.ty = tbl.ty
  for k, v in pairs(tbl) do
    if k ~= "ty" then
      local processed_value = allocate_structured_specification(metastruct, v, item_allocations, signals, recursion_depth)
      if processed_value == nil then
          -- If the processed value is nil, that means there's an error in the spec! 
          --
          -- We actually want to report each key that failed. This should help in debugging very nested tables nya.
          metastruct:add_warning("nested structured spec key `" .. tostring(k) .. "` failed to parse")
          return
      end
      result_tbl[k] = processed_value
    end
  end
  return result_tbl
end

-- Now we need to construct a table representation that will work. We explicitly refuse to represent any keys that are string, number, or bool ^.^
function structure_adjust.resolution.nest(metastruct, tbl, _literal_mode, recursion_depth)
  -- list of textual kv pairs
  local kv_pairs_list = {}
  for k, v in pairs(tbl) do
    -- We do not want to embed the `ty` key
    if k ~= "ty"  then
      local kv_text = represent_kv_pair_textual(metastruct, k, v, false, recursion_depth)
      if kv_text == nil then return end
      kv_pairs_list[#kv_pairs_list + 1] = kv_text
    end
  end
  return string.format("{%s}", table.concat(kv_pairs_list, ", "))
end

-- Process the structured messaging system. Sets up:
-- - signal names
-- - filter slots
-- - message template
-- - parse_as_table
-- simultaneously
function api_process_structured_message_modifier(metastruct, message)
  if message == nil then return end
  if type(message) ~= "table" then
    metastruct:add_warning("`message` modifier was not a structured spec table (was: `" .. tostring(message) .. "`). If it was a string, maybe you wanted the raw/unstructured configuration mode?")
    return
  end
  local item_allocations = {}
  local signal_names = {}

  local validated_structured_spec = allocate_structured_specification(metastruct, message, item_allocations, signal_names)
  if validated_structured_spec == nil then return end
  local final_message_string = build_structured_specification_message(metastruct, validated_structured_spec)
  -- Same early exit for errors ^.^
  if final_message_string == nil then return end
  -- We now have:
  -- - Item info allocations, 
  -- - signal names in a list
  -- - a message suitable for table conversion
  -- We can fill everything in in one go!
  metastruct:modified_inventory(function(inv) 
    for i = 1, NUM_SLOTS do 
      inv:set_stack("filter", i, item_allocations[i] or "")
    end
  end)
  metastruct:set_signal_names(signal_names)
  -- We only got to this point because of lack of errors, no need to keep any warnings.
  -- (we prepend return to avoid it being added every time the digiline_sender sends a message)
  metastruct:set_message_template("return " .. final_message_string)
  -- Finally mark "parse_as_table" as true. 
  metastruct:set_parse_as_table(true)
end

-- API method for configuring the digisender in a structured way, to produce tables.
--
-- This will finalise the metastruct.
function api.configure(metastruct, dmsg)
  if type(dmsg) ~= "table" then 
      metastruct:add_warning("invalid message type for `configure` method: (`" .. type(dmsg) .. "`). If it's a string, you might be looking for `configure_raw` instead.")
      metastruct:finalize()
      return 
  end
  api_process_common(metastruct, dmsg)
  api_process_structured_message_modifier(metastruct, dmsg.message)
  metastruct:finalize()
end

-- Entrypoint into the digilines API, assumed to be on correct channels and all that. This will finalize() the metastruct so you can't use it after
-- calling this.
function metadata_api:on_api_message(api_message)
  local normalized_message = api_message
  if type(api_message) == "string" then
    normalized_message = { method = "configure_raw", params = api_message }
  end
  if type(normalized_message) ~= "table" then 
    self:add_warning("api message must be a table or string")
    self:finalize()
    return
  end
  if type(normalized_message.method) ~= "string" then
    self:add_warning("api method must be a string, was (`" .. tostring(normalized_message.method) .. "`)")
    self:finalize()
    return
  end
  local api_fn = api[normalized_message.method]
  if api_fn == nil then
    local ks = {}
    for k, _ in pairs(api) do 
      ks[#ks + 1] = k
    end
    self:add_warning("api method must be one of: " .. table.concat(ks, ","))
    self:finalize()
    return
  end
  -- These finalize the structure
  local api_res = api_fn(self, normalized_message.params)
  return api_res
end

local function get_signal_names(pos)
  return minetest.get_meta(pos):get_string("signal_names")
end

local function get_channel(pos)
  return minetest.get_meta(pos):get_string("channel")
end


function logistica.digiline_sender_update_infotext(pos)
  local isOn = logistica.is_machine_on(pos)
  local channel = get_channel(pos)
  local state = isOn and ("Sending on: " .. (channel ~= "" and channel or "(no channel)")) or "Paused"
  minetest.get_meta(pos):set_string("infotext", "Digiline Sender\n" .. state)
end

function logistica.digiline_sender_after_place(pos, placer)
  local meta = minetest.get_meta(pos)
  meta:get_inventory():set_size("filter", NUM_SLOTS)
  logistica.digiline_sender_update_infotext(pos)
  logistica.on_digiline_sender_change(pos)
  if placer and placer:is_player() then
    logistica.digiline_sender_on_rightclick(pos, nil, placer, nil, nil)
  end
end

function logistica.digiline_sender_after_dig(pos, oldNode, oldMeta, _)
  last_sent[pos_hash(pos)] = nil
  logistica.on_digiline_sender_change(pos, oldNode, oldMeta)
end

function logistica.digiline_sender_on_rightclick(pos, _, player, _, _)
  if not player or not player:is_player() then return end
  local playerName = player:get_player_name()
  if logistica.should_hide_from_player(pos, playerName) then return end
  logistica.digiline_sender_show_formspec(playerName, pos)
end

function logistica.digiline_sender_allow_inv_put(pos, listname, index, stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  local meta = metadata_api.new(pos)
  local ro_inv = meta:readonly_inventory()
  -- We always want exactly one "item" in the filter, only bother changing it if we actually need to.
  if ro_inv:get_stack(listname, index):get_name() ~= stack:get_name() then
    meta:modified_inventory(function(inv) 
      -- "imagine" taking at most one item from the stack.
      local single_item_stack = stack:peek_item(1)
      inv:set_stack(listname, index, single_item_stack)
    end)
  end

  meta:finalize()
  logistica.digiline_sender_show_formspec(player:get_player_name(), pos)
  return 0
end

function logistica.digiline_sender_allow_inv_take(pos, listname, index, _stack, player)
  if not logistica.player_has_network_access(pos, player:get_player_name()) then return 0 end
  if listname ~= "filter" then return 0 end
  local meta = metadata_api.new(pos)
  meta:modified_inventory(function(inv) 
    -- We want to clear the relevant item slot on attempts to take.
    inv:set_stack(listname, index, "")
  end)
  meta:finalize()
  logistica.digiline_sender_show_formspec(player:get_player_name(), pos)
  return 0
end

function logistica.digiline_sender_allow_inv_move(_, _, _, _, _, _, _)
  return 0
end

function logistica.digiline_sender_on_inv_change(pos, listname, _index, _stack, player)
  if listname ~= "filter" then return end
  local meta = metadata_api.new(pos)
  meta:modified_inventory()
  local did_change = meta:finalize()
  if did_change then
    logistica.digiline_sender_show_formspec(player:get_player_name(), pos)
  end
end

--- API entrypoint
local function on_receive_digilines(pos, channel, message)
  if not logistica.settings.enable_digiline_sender_api then return end
  if minetest.get_meta(pos):get_string("api_enabled") ~= "1" then return end
  local our_channel = get_channel(pos)
  if our_channel == "" or our_channel ~= channel then return end
  local metastruct = metadata_api.new(pos)
  metastruct:on_api_message(message)
end


function logistica.digiline_sender_timer(pos)
  if not logistica.is_machine_on(pos) then return false end
  local networkId = logistica.get_network_id_or_nil(pos)
  if not networkId then return false end
  local meta = metadata_api.new(pos)
  meta:send_template_message(networkId)
  meta:finalize()
  minetest.get_node_timer(pos):start(POLL_INTERVAL)
  return false
end

function logistica.digiline_sender_on_connect(pos, _networkId)
  if logistica.is_machine_on(pos) then
    local jitter = math.random(0, 9) * 0.1
    minetest.get_node_timer(pos):start(POLL_INTERVAL + jitter)
  end
  logistica.digiline_sender_update_infotext(pos)
end

function logistica.digiline_sender_on_disconnect(pos, _networkId)
  minetest.get_node_timer(pos):stop()
  logistica.digiline_sender_update_infotext(pos)
end

function logistica.digiline_sender_on_power(pos, isOn)
  if isOn then
    local networkId = logistica.get_network_id_or_nil(pos)
    if networkId then
      minetest.get_node_timer(pos):start(POLL_INTERVAL)
    end
  else
    minetest.get_node_timer(pos):stop()
  end
  logistica.digiline_sender_update_infotext(pos)
end

function logistica.digiline_sender_set_parse_as_table(pos, asTable)
  local metastruct = metadata_api.new(pos)
  metastruct:set_parse_as_table(asTable)
  metastruct:finalize()
end


-- Called from formspec save to re-validate and store warning
function logistica.digiline_sender_on_save(pos, channel, signal_names, message)
  local meta = metadata_api.new(pos)
  meta:set_channel(channel)
  meta:set_signal_names_raw(signal_names)
  meta:set_message_template(message)
  if meta:get_parse_as_table() then
    local s = message:match("^%s*(.-)%s*$")
    if s:sub(1, 6) ~= "return" then s = "return " .. s end
    if minetest.deserialize(s, true) == nil then
      meta:add_warning("Table parse failed - check message syntax")
    end
  end
  meta:finalize()
end

function logistica.digiline_sender_on_receive_digilines_message(pos, _nodedef, channel, message) 
  on_receive_digilines(pos, channel, message)
end
