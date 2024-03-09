local S = logistica.TRANSLATOR
local T = minetest.get_translated_string

local FORMSPEC = "lavafunguide"
local NEXT_BTN = "nextbtn"
local PREV_BTN = "prevbtn"

local forms = {}

local internalRecipes = {}
local numInternalRecipes = 0

local function on_mods_loaded()
   local rec = logistica.get_lava_furnace_internal_recipes()
   local count = 0
   for k, defs in pairs(rec) do
    for _, v in ipairs(defs) do
      count = count + 1
      internalRecipes[count] = {name = k, recipe = v}
    end
   end
   numInternalRecipes = count
end

local function get_guide_formspec(currPage, langCode)
  currPage = logistica.clamp(currPage, 1, numInternalRecipes)
  local recipe = internalRecipes[currPage]
  local srcItem = ItemStack(recipe.name)
  local addItem = ItemStack(recipe.recipe.additive or "")
  local dstItem = ItemStack(recipe.recipe.output)
  return "formspec_version[4]" ..
    "size[10.5,7.5]" ..
      logistica.ui.background_lava_furnace..
      "item_image[0.4,4.5;1,1;"..logistica.itemstrings.lava_bucket.."]"..
      "tooltip[0.4,0.8;1,5.1;"..S("Lava Furnace can only use Lava as fuel").."]"..
      "item_image[2.2,2.3;1,1;"..recipe.name.."]"..--src
      "tooltip[2.2,2.3;1,1;"..T(langCode, srcItem:get_short_description()).."]"..
      "item_image[7.8,2.3;1,1;"..tostring(recipe.recipe.output).."]"..--dst
      "tooltip[7.8,2.3;1,1;"..T(langCode, dstItem:get_short_description()).."]"..
      "item_image[4.3,0.9;1,1;"..tostring(recipe.recipe.additive).."]"..--add
      "tooltip[4.3,0.9;1,1;"..T(langCode, addItem:get_short_description()).."]"..
      "image[4,2.3;3,1;logistica_lava_furnace_arrow_bg.png^[transformR270]"..
      "image[0.4,1.4;1,3;logistica_lava_furnace_tank_bg.png]"..
      "label[0.7,1.1;"..S("Lava").."]"..
      "label[4.2,0.5;"..S("Additives").." : "..S("Use Chance: ")..tostring(recipe.recipe.additive_use_chance).."%]"..
      "label[2.4,2.0;"..S("Input").."]"..
      "label[8.0,2.0;"..S("Output").."]"..
      "button[0.5,6.0;1,1;"..PREV_BTN..";<]"..
      "button[9.0,6.0;1,1;"..NEXT_BTN..";>]"..
      "label[4.4,5.5;"..S("Lava Furnace Recipes").."]"..
      "label[4.8,6.5;"..S("Page: ")..tostring(currPage).." / "..tostring(numInternalRecipes).."]"
end

local function guide_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC then return false end
  local playerName = player:get_player_name()
  if not forms[playerName] then return true end
  local page = forms[playerName].page
  if not page then return true end

  if fields.quit then
    forms[playerName] = nil
  elseif fields[PREV_BTN] then
    forms[playerName].page = (forms[playerName].page or 1) - 1
    if forms[playerName].page < 1 then forms[playerName].page = numInternalRecipes end
    logistica.lava_furnace_show_guide(player:get_player_name())
  elseif fields[NEXT_BTN] then
    forms[playerName].page = (forms[playerName].page or 1) + 1
    if forms[playerName].page > numInternalRecipes then forms[playerName].page = 1 end
    logistica.lava_furnace_show_guide(player:get_player_name())
  end
  return true
end

----------------------------------------------------------------
-- registration stuff
----------------------------------------------------------------

minetest.register_on_player_receive_fields(guide_receive_fields)

minetest.register_on_leaveplayer(function(objRef, timed_out)
  if objRef:is_player() then
    forms[objRef:get_player_name()] = nil
  end
end)

minetest.register_on_mods_loaded(on_mods_loaded)

----------------------------------------------------------------
-- public funcs
----------------------------------------------------------------

function logistica.lava_furnace_show_guide(playername)
  local page = 1
  if forms[playername] then page = forms[playername].page or 1
  else forms[playername] = { page = 1 } end
  local langCode = minetest.get_player_information(playername).lang_code or "en"
  minetest.show_formspec(playername, FORMSPEC, get_guide_formspec(page, langCode))
end

