local S = logistica.TRANSLATOR
local HistoryStack = logistica.HistoryStack
local RECIPE_ARROW_IMG = "logistica_lava_furnace_arrow_bg.png^[transformFYR90"
local EXIT_BUTTON_TEXTURE = "logistica_icon_cancel.png"

local Guide = {}
local guidesData = {}
local formsData = {}

local DEFAULT_TOC_WIDTH = 3
local DEFAULT_CONTENT_WIDTH = 12
local DEFAULT_TOTAL_HEIGHT = 10
local PAGE_TITLE_COLOR = "#CCDDFF"

local GUIDE_BCKSTK_NAME = "logguide"

local FORMSPEC_NAME = "guideYJDTRYNSR"
local GUI_TABLE_OF_CONTENT = "tblcon"
local GUI_PREV_BTN = "prev"
local GUI_NEXT_BTN = "next"
local GUI_NEXT_RECIPE_BTN = "NEXT_RECIPE"
local PREFIX_RECIPE_BTN = "reclnk"
local PREFIX_RECIPE_BTN_LEN = string.len(PREFIX_RECIPE_BTN)
local RECIPE_BTN_SEP = "|"

local PREFIX_RELATED = "relbtn"
local PREFIX_RELATED_BTN_LEN = string.len(PREFIX_RELATED)

local RECIPE_GUIDE_HEIGHT = 3.3 -- since coords are hardcoded, so is this
local RELATED_HEIGHT = 0.9

-- Utility

local function convert_item_recipes(items)
  if not items or type(items) ~= "table" then return nil end
  local res = {}
  for _, itemName in ipairs(items) do
    local inputs = minetest.get_all_craft_recipes(itemName)
    if inputs then
      for _, input in ipairs(inputs) do
        local width = input.width or 3
        if width == 0 then width = 3 end -- 0 width is shapeless
        local recipe = {
          output = itemName,
          width = width,
          iconText = S("Crafting"),
          input = {}
        }
        local row = 1
        local currRowTbl = {}
        local numItems = width * 3
        for i = 1, numItems do
          local newRow = math.ceil(i / width)
          if newRow ~= row then
            table.insert(recipe.input, currRowTbl)
            currRowTbl = {}
            row = newRow
          end
          local stack = input.items[i]
          if stack then
            table.insert(currRowTbl, stack)
          else
            table.insert(currRowTbl, "")
          end
      end
        -- insert last row
        table.insert(recipe.input, currRowTbl)
        recipe.height = math.max(width, #recipe.input)
        table.insert(res, recipe)
      end
    end
  end
  return res
end

-- formspec def

local function get_history(playerName)
  return HistoryStack.get(playerName, GUIDE_BCKSTK_NAME, 30)
end

local function make_recipe_button_name(a,b)
  return PREFIX_RECIPE_BTN..a..RECIPE_BTN_SEP..b
end

-- returns table {a = a, b = b} which are crafting grid coords
local function get_recipe_button_a_b_from_name(recipeBtnName)
  local substr = string.sub(recipeBtnName, PREFIX_RECIPE_BTN_LEN + 1)
  local splitStr = string.split(substr, RECIPE_BTN_SEP)
  if not splitStr[1] or not splitStr[2] then return {a = 0, b = 0} end
  local a = tonumber(splitStr[1])
  local b = tonumber(splitStr[2])
  if not a or not b then return {a = 0, b = 0} end
  return { a = a, b = b }
end

local function make_related_button_name(idx)
  return PREFIX_RELATED..idx
end

local function get_related_button_index_from_name(relatedButtonName)
  local idxStr = string.sub(relatedButtonName, PREFIX_RELATED_BTN_LEN + 1)
  return tonumber(idxStr) or 0
end


local function get_guide_common_formspec(guideData, history)
  local selIndex = 0
  local currPageId = history.get_current()
  local itemsTbl = {}
  for i, entry in ipairs(guideData.tableOfContent) do
    itemsTbl[i] = entry.name
    if entry.id == currPageId then
      selIndex = i
    end
  end

  local tocWidth = guideData.tableOfContentWidth
  local contentWidth = guideData.contentWidth
  local formWidth = tocWidth + contentWidth
  local formHeight = guideData.totalHeight

  local pnXOff = tocWidth / 2 - 1.4
  local pnY = formHeight - 1
  local itemsStr = table.concat(itemsTbl, ",")
  local prevBtn = ""
  local nextBtn = ""
  if history.has_prev() then
    prevBtn = "image_button["..(pnXOff)..","..pnY..";1,0.8;logistica_icon_highlight.png;"..GUI_PREV_BTN..";<;false;true]"..
              "tooltip["..GUI_PREV_BTN..";"..S("Go back").."]"
  end
  if history.has_next() then
    nextBtn = "image_button["..(pnXOff + 2)..","..pnY..";1,0.8;logistica_icon_highlight.png;"..GUI_NEXT_BTN..";>;false;true]"..
              "tooltip["..GUI_NEXT_BTN..";"..S("Go forward").."]"

  end

  return
    "formspec_version[4]"..
    "size["..formWidth..","..formHeight.."]"..
    (guideData.formspecBackgroundStr or "")..
    "label["..(tocWidth + 3.9)..",0.4;"..(guideData.title or "").."]"..
    "textlist[0.2,0.8;"..tocWidth..","..(pnY - 1)..";"..GUI_TABLE_OF_CONTENT..";"..itemsStr..";"..selIndex..";false]"..
    "image_button_exit["..(formWidth - 1)..",0.2;0.8,0.8;"..EXIT_BUTTON_TEXTURE..";;;false;false;]"..
    prevBtn..nextBtn
end

local function itm_img_grid(x, y, a, b, recipeData, recipeLinks)
  if not recipeData.input or not recipeData.input[a] or not recipeData.input[a][b] then return "" end
  if b > recipeData.width or a > recipeData.height then return "" end

  local item = recipeData.input[a][b]
  local itemDescription = ItemStack(item):get_description()
  local tooltip = "tooltip["..x..","..y..";1,1;"..itemDescription.."]"
  if not recipeLinks or not recipeLinks[item] then -- no link, just show an image
    return "item_image["..x..","..y..";1,1;"..item.."]"..tooltip
  else -- we have a link, show a button
    return "item_image_button["..x..","..y..";1,1;"..item..";"..make_recipe_button_name(a, b)..";]"..tooltip
  end
end


-- returns a string for the recipes, or an empty string if there isn't one
local function get_crafting_grid(pageData, playerName, tocWidth, formWidth)
  if not pageData.recipes or #pageData.recipes == 0 then return "" end

  local numRecipes = #pageData.recipes
  local currRecipeIndex = formsData[playerName].currRecipeIndex or 1
  if currRecipeIndex > numRecipes then currRecipeIndex = 1 ; formsData[playerName].currRecipeIndex = 1 end

  local xAdj = tocWidth + (formWidth - tocWidth - DEFAULT_CONTENT_WIDTH) / 2

  local nextRecipeBtn = ""
  if numRecipes > 1 then
    nextRecipeBtn = "button["..(xAdj + 4.8)..",3.7;3,0.8;"..GUI_NEXT_RECIPE_BTN..";"..S("Recipe: @1 of @2", currRecipeIndex, numRecipes).."]"
  end

  local recipeData = pageData.recipes[currRecipeIndex]

  local iconCraftType = ""
  if recipeData.icon then
    iconCraftType = "image["..(xAdj + 5.8)..",1.5;1,1;"..recipeData.icon.."]"
  end
  local iconCraftText = ""
  if recipeData.iconText then
    iconCraftText = "label["..(xAdj + 5.0)..",3.4;"..recipeData.iconText.."]"
  end

  local outputTooltipText = ItemStack(recipeData.output):get_description()
  local recipeLinks = pageData.recipeLinks

  return
    "item_image["..(xAdj + 8.7)..",1.5;3,3;"..recipeData.output.."]"..
    "tooltip["..(xAdj + 8.7)..",1.5;3,3;"..outputTooltipText.."]"..
    itm_img_grid(xAdj + 0.6, 1.5, 1, 1, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 1.7, 1.5, 1, 2, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 2.8, 1.5, 1, 3, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 0.6, 2.5, 2, 1, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 1.7, 2.5, 2, 2, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 2.8, 2.5, 2, 3, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 0.6, 3.5, 3, 1, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 1.7, 3.5, 3, 2, recipeData, recipeLinks)..
    itm_img_grid(xAdj + 2.8, 3.5, 3, 3, recipeData, recipeLinks)..
    "image["..(xAdj + 4.8)..",2.5;3,1;"..RECIPE_ARROW_IMG.."]"..
    iconCraftType..
    iconCraftText..
    nextRecipeBtn
end

local function get_related_items(pageData, tocWidth, vertOffset)
  if not pageData.relatedItems or not type(pageData.relatedItems) == "table" then return "" end
  local x = tocWidth + 1.7
  local sz = 0.8
  local items = {}
  local label = "label["..(tocWidth + 0.6)..","..(vertOffset + 1.8)..";"..S("Related:").."]"

  for i, item in ipairs(pageData.relatedItems) do
    local posSize = ""..x..","..(vertOffset + 1.4)..";"..sz..","..sz
    local itemStack = ItemStack(item)
    local tooltip = "tooltip["..posSize..";"..itemStack:get_description().."]"
    local itemBtn = "item_image_button["..posSize..";"..item..";"..make_related_button_name(i)..";]"
    items[i] = itemBtn..tooltip
    x = x + sz + 0.2
  end

  return label..table.concat(items)
end

local function get_page_header(pageData, tocWidth)
  return "label["..(tocWidth + 0.6)..",1.1;"..minetest.colorize(PAGE_TITLE_COLOR, (pageData.title or "")).."]"
end

local function get_page_text(pageData, verticaOffset, tocWidth, formWidth, formHeight)
  local y = 1.5 + verticaOffset
  local width = formWidth - tocWidth - 0.8
  return "textarea["..(tocWidth + 0.6)..","..y..";"..width..","..(formHeight - y - 0.2)..";;;"..pageData.description.."]"
end

local function get_curr_page_formspec(guideName, playerName)
  local guideData = guidesData[guideName]
  local history = get_history(playerName)
  local currPageName = history.get_current()
  if currPageName == "" then
    currPageName = guideData.tableOfContent[1].id
    history.push_new(currPageName)
  end
  local pageData = guideData.pageText[currPageName]
  if not pageData then return "" end

  local tocWidth = guideData.tableOfContentWidth
  local contentWidth = guideData.contentWidth
  local formWidth = contentWidth + tocWidth
  local formHeight = guideData.totalHeight

  local commonFormspec = get_guide_common_formspec(guideData, history)

  local pageHeader = get_page_header(pageData, tocWidth)

  local craftingGrid = get_crafting_grid(pageData, playerName, tocWidth, formWidth)

  local vertOffset = 0

  if craftingGrid ~= "" then vertOffset = vertOffset + RECIPE_GUIDE_HEIGHT end
  local relatedItems = get_related_items(pageData, tocWidth, vertOffset)

  if relatedItems ~= "" then vertOffset = vertOffset + RELATED_HEIGHT end
  local description = get_page_text(pageData, vertOffset, tocWidth, formWidth, formHeight)

  return commonFormspec..pageHeader..craftingGrid..relatedItems..description
end

local function show_guide(playerName, guideName)
  if not guideName or not playerName or not guidesData[guideName] then return end
  if not formsData[playerName] then formsData[playerName] = { guideName = guideName } end
  minetest.show_formspec(
    playerName,
    FORMSPEC_NAME,
    get_curr_page_formspec(guideName, playerName)
  )
end

-- handling of buttons on guide

local function handle_table_of_content_clicked(playerName, textListString)
  local eventTable = minetest.explode_textlist_event(textListString)
  if eventTable.type == "CHG" then
    local formData = formsData[playerName] ; if not formsData then return end
    formData.currRecipeIndex = 1
    local guideName = formData.guideName
    local guideData = guidesData[guideName] ; if not guideData then return end

    local history = get_history(playerName)

    local selectedPageInfo = guideData.tableOfContent[eventTable.index] or {}
    local pageId = selectedPageInfo.id
    local currId = history.get_current()
    if not pageId then return end
    if pageId == currId then return end
    local pageData = guideData.pageText[pageId]
    if not pageData then return end

    history.push_new(pageId)
    show_guide(playerName, guideName)
  end
end

local function handle_recipe_button_click(playerName, a, b)
  if a <= 0 or b <= 0 then return end
  local formData = formsData[playerName] ; if not formData then return end
  local guideName = formData.guideName
  local guideData = guidesData[guideName] ; if not guideData then return end
  local history = get_history(playerName)
  local currPageId = history.get_current() ; if currPageId == "" then return end

  local pageData = guideData.pageText[currPageId] ; if not pageData then return end
  local recipe = pageData.recipes and pageData.recipes[formData.currRecipeIndex or 1] ; if not recipe then return end

  local item = recipe.input[a] ; if item then item = item[b] end ; if not item then return end

  local link = pageData.recipeLinks and pageData.recipeLinks[item] ; if not link then return end

  if not guideData.pageText[link] then return end

  history.push_new(link)
  show_guide(playerName, guideName)
  return true
end

local function handle_related_button_click(playerName, idx)
  if idx <= 0 then return end
  local formData = formsData[playerName] ; if not formData then return end
  local guideName = formData.guideName
  local guideData = guidesData[guideName] ; if not guideData then return end
  local history = get_history(playerName)
  local currPageId = history.get_current() ; if currPageId == "" then return end

  local pageData = guideData.pageText[currPageId] ; if not pageData then return end
  local relatedItem = pageData.relatedItems and pageData.relatedItems[idx] ; if not relatedItem then return end
  local link = pageData.recipeLinks and pageData.recipeLinks[relatedItem] ; if not link then return end
  if not guideData.pageText[link] then return end

  history.push_new(link)
  show_guide(playerName, guideName)
  return true
end

local function on_player_receive_fields(player, formname, fields)
  if not player or not player:is_player() then return false end
  if formname ~= FORMSPEC_NAME then return false end
  local playerName = player:get_player_name()
  if not formsData[playerName] then return false end

  if fields.quit then
    formsData[playerName] = nil
  elseif fields[GUI_TABLE_OF_CONTENT] then
    handle_table_of_content_clicked(playerName, fields[GUI_TABLE_OF_CONTENT])
  elseif fields[GUI_NEXT_BTN] then
    get_history(playerName).go_forward()
    show_guide(playerName, formsData[playerName].guideName)
  elseif fields[GUI_PREV_BTN] then
    get_history(playerName).go_back()
    show_guide(playerName, formsData[playerName].guideName)
  elseif fields[GUI_NEXT_RECIPE_BTN] then
    formsData[playerName].currRecipeIndex = (formsData[playerName].currRecipeIndex or 1) + 1 -- the displaying handles overflows
    show_guide(playerName, formsData[playerName].guideName)
  else
    for fieldName, _ in pairs(fields) do
      if string.sub(fieldName, 1, PREFIX_RECIPE_BTN_LEN) == PREFIX_RECIPE_BTN then
        local tb = get_recipe_button_a_b_from_name(fieldName)
        if handle_recipe_button_click(playerName, tb.a, tb.b) then return end
      elseif string.sub(fieldName, 1, PREFIX_RELATED_BTN_LEN) == PREFIX_RELATED then
        local idx = get_related_button_index_from_name(fieldName)
        if handle_related_button_click(playerName, idx) then return end
      end
    end
  end
end

--------------------------------
-- API
--------------------------------

--[[
  guideDef = {
    
    title = "Title of Guide",

    formspecBackgroundStr = "valid formspec background (e.g. bgcolor[#0000;true;#0008] etc)" or nil,

    tableOfContentWidth = 4 -- or nil. If nil, assumed 3. No minimum, 0 will hide the TOC.

    contentWidth = 14 -- or nil. If nil, assumed 12. 12 is the minimum even if specified.
    
    totalHeight = 12 -- or nil. If nil, assumed 10. 10 is the minimum even if specified.
    
    tableOfContent = {
      {
        name = "Page Name"
        id = "pageid" --or nil. If nil, item is used as divider only
      }, -- repated, adds table of content rows in order
    },

    pageText = {
      "pageid" = {
        title = "Title of the page, shown when opened" -- or nil,
        recipes = {
          {
            output = "output_item_string",
            input = { {"minetest", "crafting", "recipe"}, {"with", "rows"}},
            icon = "craft_icon.png" or nil,
            iconText = "Icon description" or nil,
            width = int or nil (assumed to be 3 if nil),
            height = int or nil (assumed to be 3 if nil),
          }
        } or nil,
        relatedItems = {itemName, itemName} or nil,
        recipeLinks = {
          "input_item_name" = "pageidToLinkTo",
        } or nil,
        description = "lines of text to be shown" or nil,
      }
    }
  }
  <br>
  returns true if guide registration successful, or false if not (e.g. guide by name already exists)
]]
function Guide.register(guideName, guideDef)
  if guidesData[guideName] then return false end
  if not guideDef or not guideDef.tableOfContent or not guideDef.pageText then return false end

  if type(guideDef.tableOfContent) ~= "table" then return false end
  if type(guideDef.pageText) ~= "table" then return false end

  guideDef.tableOfContentWidth = math.max(0, guideDef.tableOfContentWidth or DEFAULT_TOC_WIDTH)
  guideDef.contentWidth = math.max(DEFAULT_CONTENT_WIDTH, guideDef.contentWidth or DEFAULT_CONTENT_WIDTH)
  guideDef.totalHeight = math.max(DEFAULT_TOTAL_HEIGHT, guideDef.totalHeight or DEFAULT_TOTAL_HEIGHT)

  -- sanitize everything that can be displayed
  for _, pgInfo in ipairs(guideDef.tableOfContent) do
    pgInfo.name = minetest.formspec_escape(pgInfo.name or "")
  end
  for _, pgTextInfo in pairs(guideDef.pageText) do
    pgTextInfo.title = minetest.formspec_escape(pgTextInfo.title) or ""
    pgTextInfo.description = minetest.formspec_escape(pgTextInfo.description) or ""
    if pgTextInfo.recipes then
      for _, recipe in ipairs(pgTextInfo.recipes) do
        recipe.iconText = minetest.formspec_escape(recipe.iconText) or ""
        recipe.width = recipe.width or 3
        recipe.height = recipe.height or recipe.width
      end
    end
  end

  -- store the sanitized guide info
  guidesData[guideName] = guideDef

  return true
end

function Guide.show_guide(playerName, guideName)
  show_guide(playerName, guideName)
end

-- Accepts a list of one or more minetest items, e.g. { "default:pick_steel", "default:pick_stone" } and
-- converts them to a format for the list accepted by `Guide.register`'s pageText.recipes
function Guide.convert_minetest_items_recipes_to_guide_recipes(listOfMinetestItems)
  return convert_item_recipes(listOfMinetestItems)
end

-- export it
logistica.GuideApi = Guide

-- register to listen for form fields
minetest.register_on_player_receive_fields(on_player_receive_fields)
minetest.register_on_leaveplayer(function(objRef, _)
  if objRef:is_player() then
    local playerName = objRef:get_player_name()
    formsData[playerName] = nil
    logistica.HistoryStack.on_player_leave(playerName)
  end
end)
