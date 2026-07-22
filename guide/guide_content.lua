local S = logistica.TRANSLATOR
local function L(s) return "logistica:"..s end
local GUIDE_NAME = "logistica_guide"

local PAGE_WHATS_NEW_2_0 = "whatsnew20"
local PAGE_INTRO = "intro"
local PAGE_START = "start"

local PAGE_CREATE_NET = "crtnet"
local PAGE_MOVE_ITEMS = "mvitms"

local PAGE_NET_CONTROLLER = "mnetcon"
local PAGE_ACCESS_POINT = "maccpt"
local PAGE_ACCESS_POINT_STORAGE = "maccptst"
local PAGE_ACCESS_POINT_CRAFTING = "maccptcr"
local PAGE_OPTIC_CABLE = "moptcab"
local PAGE_MASS_STORAGE = "mmasstr"
local PAGE_TOOL_CHEST = "mtoolch"
local PAGE_PASSIVE_SUPPLIER = "mpasssp"
local PAGE_NETWORK_IMPORTER = "mnetimp"
local PAGE_REQUEST_INSERTER = "mreqins"
local PAGE_RESERVOIR = "mreservoir"
local PAGE_PUMP = "mpump"
local PAGE_BUCKET_EMPTIER = "mbckemp"
local PAGE_BUCKET_FILLER = "mbckfil"
local PAGE_WIRELESS_UPGRADER = "mwrlup"
local PAGE_CRAFTING_SUPPLIER = "mcrftsup"
local PAGE_COOKING_SUPPLIER = "mcooksup"
local PAGE_AUTOCRAFTER = "mautocrf"
local PAGE_VACCUUM_CHEST = "mvacchs"
local PAGE_REQUESTER_PROGRAMMER = "mreqprog"
local PAGE_FARMING_SUPPLIER = "mfarmsup"
local PAGE_SPRINKLER_UPGRADE = "isprinkup"
local PAGE_WOODCUTTER = "mwoodcut"
local PAGE_LEAVES_UPGRADE = "ileavesup"
local PAGE_LAVA_FUELER = "mlvfuel"
local PAGE_ROCK_MELTER = "mrockmelt"
local PAGE_COBBLE_GENERATOR = "mcobgen"
local PAGE_TRASHCAN = "mtrash"
local PAGE_DISASSEMBLER = "mdisasm"
local PAGE_ITEM_MONITOR = "mitmoni"
local PAGE_WIRELESS_TRANSMITTER = "wrltrn"
local PAGE_WIRELESS_RECEIVER = "wrlrec"
local PAGE_WIRELESS_ANTENNA = "wrlant"

local PAGE_MASS_STORAGE_UPGR = "msstup"
local PAGE_COBBLE_GENERATOR_UPGR = "cbgnup"

local PAGE_WIRELESS_ACCESS_PAD = "iwrlap"
local PAGE_HYPERSPANNER = "ihyper"
local PAGE_STATE_COPIER = "istatcp"
local PAGE_INF_WAND = "iinfwnd"
local PAGE_WAND = "iinvwnd"

local PAGE_SILVERIN_CRYSTAL = "isilcry"
local PAGE_SILVERIN_SLICE = "isilsli"
local PAGE_SILVERIN_CIRCUIT = "isilcir"
local PAGE_SILVERIN_MIRRORBOX = "isilmbx"
local PAGE_SILVERIN_PLATE = "isilplt"
local PAGE_HARDENED_SILVERIN_BLOCK = "ihardsilblk"
local PAGE_COMPRESSION_TANK = "icomptnk"
local PAGE_PHOTONIZERS = "iphtns"
local PAGE_WAVE_FUN_MAIN = "iwvfnm"
local PAGE_WIRELESS_CRYSTAL = "iwrcry"

local PAGE_SERVER_SETTINGS = "servset"

local PAGE_SIGNALS_OVERVIEW       = "sigover"
local PAGE_SIGNAL_RELAY           = "sigrelay"
local PAGE_SIGNAL_BUTTON          = "sigbtn"
local PAGE_SIGNAL_SWITCH          = "sigsw"
local PAGE_SIGNAL_LAMP            = "siglmp"
local PAGE_SIGNAL_LAMP_2C         = "siglmp2c"
local PAGE_SIGNAL_TOGGLER         = "sigtgl"
local PAGE_SIGNAL_NOT_GATE        = "signot"
local PAGE_SIGNAL_TOGGLE          = "sigtoggle"
local PAGE_SIGNAL_LOGIC_GATE      = "siglg"
local PAGE_MESECON_SIG_RECEIVER   = "mesrcv"
local PAGE_MESECON_SIG_SENDER     = "messnd"
local PAGE_SIGNAL_ITEM_COUNTER    = "sigitmcnt"
local PAGE_SIGNAL_LIQUID_COUNTER  = "sigliqcnt"
local PAGE_SIGNAL_EXT_READER      = "sigextrd"
local PAGE_SIGNAL_TIMER           = "sigtimer"
local PAGE_SIGNAL_NODE_DETECTOR   = "signodedet"
local PAGE_SIGNAL_NODE_PLACER     = "signodeplacer"
local PAGE_SIGNAL_NODE_DIGGER     = "signodedigger"
local PAGE_DIGILINE_SENDER        = "diglsnd"
local PAGE_DIGILINE_RECEIVER      = "diglrecv"
local PAGE_SIGNAL_MONITOR         = "sigmonitor"
local PAGE_SIGNAL_DELAYER         = "sigdelayer"

local getrec = logistica.GuideApi.convert_minetest_items_recipes_to_guide_recipes

local allLavaFurnRecipes = logistica.get_lava_furnace_internal_recipes()

local function getlavarec(itemName)
  local ret = {}
  for _, recipes in pairs(allLavaFurnRecipes) do
    for _, recipe in pairs(recipes) do
      local itemStack = ItemStack(recipe.output)
      if itemStack:get_name() == itemName then
        local outRec = {
          output = itemName,
          width = 2,
          height = 1,
          icon = "logistica_lava_furnace_front_off.png",
          iconText = S("Lava Furnace"),
          input = {{recipe.input, recipe.additive}}
        }
        table.insert(ret, outRec)
      end
    end
  end
  return ret
end

local RECIPE_LAVAFURN = getrec({L("lava_furnace")})
local RECIPE_NETCONTR = getrec({L("simple_controller")})
local RECIPE_ACCESSPT = getrec({L("access_point")})
local RECIPE_OPTICCBL = getrec({L("optic_cable"), L("optic_cable_toggleable_off"), L("optic_cable_block"), L("cable_insulating"), L("cable_insulating_l")})
local RECIPE_MASSSTOR = getrec({L("mass_storage_basic")})
local RECIPE_TOOLCHST = getrec({L("item_storage")})
local RECIPE_PASSSUPP = getrec({L("passive_supplier")})
local RECIPE_NETIMPRT = getrec({L("injector_slow"), L("injector_fast")})
local RECIPE_REQINSRT = getrec({L("requester_item"), L("requester_stack")})
local RECIPE_RESERVOR = getrec({L("reservoir_obsidian_empty"), L("reservoir_silverin_empty")})
local RECIPE_RESERPMP = getrec({L("pump")})
local RECIPE_WRLUPGRD = getrec({L("wireless_synchronizer")})
local RECIPE_CRAFTSUP = getrec({L("crafting_supplier")})
local RECIPE_COOKSUP = getrec({L("cooking_supplier")})
local RECIPE_AUTOCRFT = getrec({L("autocrafter")})
local RECIPE_BUCKFILL = getrec({L("bucket_filler")})
local RECIPE_BUCKEMPT = getrec({L("bucket_emptier")})
local RECIPE_VACCUUMC = getrec({L("vaccuum_chest")})
local RECIPE_REQPROGRAMMER = getrec({L("requester_programmer_on")})
local RECIPE_FARMSUP = getrec({L("farming_supplier")})
local RECIPE_SPRINKUP = getrec({L("sprinkler_upgrade")})
local RECIPE_WOODCUT  = getrec({L("woodcutter")})
local RECIPE_LEAVESUP = getrec({L("leaves_upgrade")})
local RECIPE_LVFRFUEL = getrec({L("lava_furnace_fueler")})
local RECIPE_ROCKMELT = getrec({L("rock_melter")})
local RECIPE_COBBLGEN = getrec({L("cobblegen_supplier")})
local RECIPE_TRASHCAN = getrec({L("trashcan")})
local RECIPE_DISASSEMBLER = getrec({L("disassembler")})
local RECIPE_ITEM_MONITOR = getrec({L("item_monitor")})
local RECIPE_ACUPGRD = getrec({L("autocrafting_upgrade"), L("autocrafting_recursive_upgrade")})
local RECIPE_WRLSTRNS = getrec({L("wireless_transmitter")})
local RECIPE_WRLSRECV = getrec({L("wireless_receiver")})

local RECIPE_MASSUPGR = getrec({L("storage_upgrade_1"), L("storage_upgrade_2"), L("storage_upgrade_multiplier")})
local RECIPE_COBGENUP = getrec({L("cobblegen_upgrade")})
local RECIPE_HYPERSPN = getrec({L("hyperspanner")})
local RECIPE_STATECPY = getrec({L("state_copier")})
local RECIPE_PHOTONIZ = getrec({L("photonizer"), L("photonizer_reversed")})
local RECIPE_STANDWAV = getrec({L("standing_wave_box")})
local RECIPE_WIRLSSAP = getrec({L("wireless_access_pad")})
local RECIPE_COMPTANK = getrec({L("compression_tank")})
local RECIPE_SILVSLIC = getrec({L("silverin_slice")})
local RECIPE_WRLSANTN = getrec({L("wireless_antenna")})

local RECIPE_SILVERIN = getlavarec(L("silverin"))
local RECIPE_SILVPLAT = getlavarec(L("silverin_plate"))
local RECIPE_HARDSILBLK = getlavarec(L("hardened_silverin_block"))
local RECIPE_SILVCIRC = getlavarec(L("silverin_circuit"))
local RECIPE_SILVMIRR = getlavarec(L("silverin_mirror_box"))
local RECIPE_WRLSCRYS = getlavarec(L("wireless_crystal"))

local RECIPE_SIG_RELAY   = getrec({L("signal_relay")})
local RECIPE_SIG_BUTTON  = getrec({L("signal_button")})
local RECIPE_SIG_SWITCH  = getrec({L("signal_switch")})
local RECIPE_SIG_LAMP    = getrec({L("signal_lamp_white"), L("signal_lamp_red"), L("signal_lamp_yellow"), L("signal_lamp_green"), L("signal_lamp_cyan"), L("signal_lamp_blue"), L("signal_lamp_purple")})
local RECIPE_SIG_LAMP2C  = getrec({L("signal_lamp_2c_br")})
local RECIPE_SIG_TOGGLER = getrec({L("signal_toggler")})
local RECIPE_SIG_NOT     = getrec({L("signal_not_gate")})
local RECIPE_SIG_TOGGLE  = getrec({L("signal_toggle")})
local RECIPE_SIG_LOGIC   = getrec({L("signal_logic_gate")})
local RECIPE_SIG_MESR    = getrec({L("mesecon_signaler")})
local RECIPE_SIG_MESS    = getrec({L("mesecon_sender")})
local RECIPE_SIG_COUNTER  = getrec({L("signal_item_counter")})
local RECIPE_SIG_LIQCNT   = getrec({L("signal_liquid_counter")})
local RECIPE_SIG_EXTRD    = getrec({L("signal_ext_reader")})
local RECIPE_SIG_TIMER    = getrec({L("signal_timer")})
local RECIPE_SIG_NODEDET  = getrec({L("signal_node_detector")})
local RECIPE_SIG_NODEPLACER = getrec({L("signal_node_placer")})
local RECIPE_SIG_NODEDIGGER = getrec({L("signal_node_digger")})
local RECIPE_DIGILINE_SENDER   = getrec({L("digiline_sender")})
local RECIPE_DIGILINE_RECEIVER = getrec({L("digiline_receiver")})
local RECIPE_SIG_MONITOR       = getrec({L("signal_monitor")})
local RECIPE_SIG_DELAYER       = getrec({L("signal_delayer")})

local RECIPE_LINKS = {
  -- items
  [L("lava_furnace")] = PAGE_START,
  [L("silverin")] = PAGE_SILVERIN_CRYSTAL,
  [L("silverin_slice")] = PAGE_SILVERIN_SLICE,
  [L("silverin_mirror_box")] = PAGE_SILVERIN_MIRRORBOX,
  [L("silverin_plate")] = PAGE_SILVERIN_PLATE,
  [L("hardened_silverin_block")] = PAGE_HARDENED_SILVERIN_BLOCK,
  [L("compression_tank")] = PAGE_COMPRESSION_TANK,
  [L("photonizer")] = PAGE_PHOTONIZERS,
  [L("photonizer_reversed")] = PAGE_PHOTONIZERS,
  [L("standing_wave_box")] = PAGE_WAVE_FUN_MAIN,
  [L("wireless_crystal")] = PAGE_WIRELESS_CRYSTAL,
  [L("wireless_access_pad")] = PAGE_WIRELESS_ACCESS_PAD,
  [L("hyperspanner")] = PAGE_HYPERSPANNER,
  [L("state_copier")] = PAGE_STATE_COPIER,
  [L("optic_cable")] = PAGE_OPTIC_CABLE,
  [L("optic_cable_toggleable_off")] = PAGE_OPTIC_CABLE,
  [L("optic_cable_block")] = PAGE_OPTIC_CABLE,
  [L("cable_insulating")] = PAGE_OPTIC_CABLE,
  [L("cable_insulating_l")] = PAGE_OPTIC_CABLE,
  [L("storage_upgrade_1")] = PAGE_MASS_STORAGE_UPGR,
  [L("storage_upgrade_2")] = PAGE_MASS_STORAGE_UPGR,
  [L("storage_upgrade_multiplier")] = PAGE_MASS_STORAGE_UPGR,
  [L("cobblegen_upgrade")] = PAGE_COBBLE_GENERATOR_UPGR,
  [L("autocrafting_upgrade")] = PAGE_ACCESS_POINT_CRAFTING,
  [L("autocrafting_recursive_upgrade")] = PAGE_ACCESS_POINT_CRAFTING,
  [L("silverin_circuit")] = PAGE_SILVERIN_CIRCUIT,
  [L("wireless_antenna")] = PAGE_WIRELESS_ANTENNA,

  -- signals
  [L("signal_relay")]        = PAGE_SIGNAL_RELAY,
  [L("signal_button")]       = PAGE_SIGNAL_BUTTON,
  [L("signal_switch")]       = PAGE_SIGNAL_SWITCH,
  [L("signal_lamp_white")]   = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_red")]     = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_yellow")]  = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_green")]   = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_cyan")]    = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_blue")]    = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_purple")]  = PAGE_SIGNAL_LAMP,
  [L("signal_lamp_2c_br")]   = PAGE_SIGNAL_LAMP_2C,
  [L("signal_toggler")]      = PAGE_SIGNAL_TOGGLER,
  [L("signal_not_gate")]     = PAGE_SIGNAL_NOT_GATE,
  [L("signal_logic_gate")]   = PAGE_SIGNAL_LOGIC_GATE,
  [L("signal_toggle")]       = PAGE_SIGNAL_TOGGLE,
  [L("mesecon_signaler")]    = PAGE_MESECON_SIG_RECEIVER,
  [L("mesecon_sender")]      = PAGE_MESECON_SIG_SENDER,
  [L("signal_item_counter")]   = PAGE_SIGNAL_ITEM_COUNTER,
  [L("signal_liquid_counter")] = PAGE_SIGNAL_LIQUID_COUNTER,
  [L("signal_ext_reader")]     = PAGE_SIGNAL_EXT_READER,
  [L("signal_timer")]          = PAGE_SIGNAL_TIMER,
  [L("signal_node_detector")]  = PAGE_SIGNAL_NODE_DETECTOR,
  [L("signal_node_placer")]    = PAGE_SIGNAL_NODE_PLACER,
  [L("signal_node_digger")]    = PAGE_SIGNAL_NODE_DIGGER,
  [L("digiline_sender")]       = PAGE_DIGILINE_SENDER,
  [L("digiline_receiver")]     = PAGE_DIGILINE_RECEIVER,
  [L("signal_monitor")]        = PAGE_SIGNAL_MONITOR,
  [L("signal_delayer")]        = PAGE_SIGNAL_DELAYER,

  -- machines
  [L("lava_furnace_fueler")] = PAGE_LAVA_FUELER,
  [L("rock_melter")] = PAGE_ROCK_MELTER,
  [L("reservoir_silverin_empty")] = PAGE_RESERVOIR,
  [L("reservoir_obsidian_empty")] = PAGE_RESERVOIR,
  [L("wireless_synchronizer")] = PAGE_WIRELESS_UPGRADER,
  [L("simple_controller")] = PAGE_NET_CONTROLLER,
  [L("injector_slow")] = PAGE_NETWORK_IMPORTER,
  [L("requester_item")] = PAGE_REQUEST_INSERTER,
  [L("pump")] = PAGE_PUMP,
  [L("mass_storage_basic")] = PAGE_MASS_STORAGE,
  [L("cobblegen_supplier")] = PAGE_COBBLE_GENERATOR,
  [L("wireless_transmitter")] = PAGE_WIRELESS_TRANSMITTER,
  [L("wireless_receiver")] = PAGE_WIRELESS_RECEIVER,
  [L("woodcutter")] = PAGE_WOODCUTTER,
  [L("leaves_upgrade")] = PAGE_LEAVES_UPGRADE,
  [L("farming_supplier")] = PAGE_FARMING_SUPPLIER,
  [L("disassembler")] = PAGE_DISASSEMBLER,
  [L("item_monitor")] = PAGE_ITEM_MONITOR,
  [L("requester_programmer_on")] = PAGE_REQUESTER_PROGRAMMER,

}

--------------------------------
-- Registration
--------------------------------

local function header(str)
  return "#CCFF66"..str
end

local RECIPE_LINKS_WHATS_NEW = setmetatable(
  { [L("signal_relay")] = PAGE_SIGNALS_OVERVIEW },
  { __index = RECIPE_LINKS }
)

local desc = logistica.Guide.Desc

logistica.GuideApi.register(GUIDE_NAME, {
  title = S("Logistica Guide"),

  formspecBackgroundStr = logistica.ui.background,

  tableOfContentWidth = 4.5,
  contentWidth = 15,
  totalHeight = 14,

  tableOfContent = {
    { name = header(S("Logistica 2.0")), id = PAGE_WHATS_NEW_2_0 },
    { name = header(S("Intro")), id = PAGE_INTRO },
    { name = header(S("How To:"))},
    { name = S("  Get Started: The Lava Furnace"), id = PAGE_START },
    { name = S("  Create a Logistic Network"), id = PAGE_CREATE_NET },
    { name = S("  Move items from/to other mods"), id = PAGE_MOVE_ITEMS },
    { name = header(S("General Machines:"))},
    { name = S("  Network Controller"), id = PAGE_NET_CONTROLLER },
    { name = S("  Access Point"), id = PAGE_ACCESS_POINT },
    { name = S("  Access Point Mass Storage"), id = PAGE_ACCESS_POINT_STORAGE },
    { name = S("  Access Point Crafting"), id = PAGE_ACCESS_POINT_CRAFTING },
    { name = S("  Optic Cables"), id = PAGE_OPTIC_CABLE },
    { name = header(S("Storage:"))},
    { name = S("  Mass Storage"), id = PAGE_MASS_STORAGE },
    { name = S("  Tool Chest"), id = PAGE_TOOL_CHEST },
    { name = S("  Passive Supplier Chest"), id = PAGE_PASSIVE_SUPPLIER },
    { name = header(S("Moving Items:"))},
    { name = S("  Network Importer"), id = PAGE_NETWORK_IMPORTER },
    { name = S("  Request Inserter"), id = PAGE_REQUEST_INSERTER },
    { name = header(S("Wireless Network")) },
    { name = S("  Wireless Transmitter"), id = PAGE_WIRELESS_TRANSMITTER },
    { name = S("  Wireless Receiver"), id = PAGE_WIRELESS_RECEIVER },
    { name = S("  Wireless Access Pad"), id = PAGE_WIRELESS_ACCESS_PAD },
    { name = S("  Wireless Upgrader"), id = PAGE_WIRELESS_UPGRADER },
    { name = header(S("Liquid Storage:"))},
    { name = S("  Reservoirs"), id = PAGE_RESERVOIR },
    { name = S("  Reservoir Pump"), id = PAGE_PUMP },
    { name = S("  Bucket Filler"), id = PAGE_BUCKET_FILLER },
    { name = S("  Bucket Emptier"), id = PAGE_BUCKET_EMPTIER },
    { name = header(S("Autocrafting:"))},
    { name = S("  Crafting Supplier"), id = PAGE_CRAFTING_SUPPLIER },
    { name = S("  Cooking Supplier"), id = PAGE_COOKING_SUPPLIER },
    { name = S("  Autocrafter"), id = PAGE_AUTOCRAFTER },
    { name = header(S("Signals:"))},
    { name = S("  Signals Overview"), id = PAGE_SIGNALS_OVERVIEW },
    { name = S("  Signal Button"), id = PAGE_SIGNAL_BUTTON },
    { name = S("  Signal Switch"), id = PAGE_SIGNAL_SWITCH },
    { name = S("  Signal Lamp"), id = PAGE_SIGNAL_LAMP },
    { name = S("  Signal Lamp (2-Color)"), id = PAGE_SIGNAL_LAMP_2C },
    { name = S("  Signal Network Switch"), id = PAGE_SIGNAL_TOGGLER },
    { name = S("  Signal NOT Gate"), id = PAGE_SIGNAL_NOT_GATE },
    { name = S("  Signal Logic Gate"), id = PAGE_SIGNAL_LOGIC_GATE },
    { name = S("  Signal Item Count Sender"), id = PAGE_SIGNAL_ITEM_COUNTER },
    { name = S("  Signal Liquid Count Sender"), id = PAGE_SIGNAL_LIQUID_COUNTER },
    { name = S("  External Content Reader"), id = PAGE_SIGNAL_EXT_READER },
    { name = S("  Signal Timer Sender"), id = PAGE_SIGNAL_TIMER },
    { name = S("  Signal Toggle"), id = PAGE_SIGNAL_TOGGLE },
    { name = S("  Signal Delayer"), id = PAGE_SIGNAL_DELAYER },
    { name = S("  Signal Node Detector"), id = PAGE_SIGNAL_NODE_DETECTOR },
    { name = S("  Signal Node Placer"),   id = PAGE_SIGNAL_NODE_PLACER },
    { name = S("  Signal Node Digger"),   id = PAGE_SIGNAL_NODE_DIGGER },
    { name = S("  Digiline Signal Sender"),             id = PAGE_DIGILINE_SENDER },
    { name = S("  Digiline to Signal Converter"),      id = PAGE_DIGILINE_RECEIVER },
    { name = S("  Signal Monitor"),                    id = PAGE_SIGNAL_MONITOR },
    { name = S("  Mesecon Signal Receiver"), id = PAGE_MESECON_SIG_RECEIVER },
    { name = S("  Mesecon Signal Sender"), id = PAGE_MESECON_SIG_SENDER },
    { name = header(S("Resource Gathering:"))},
    { name = S("  Farming Supplier"), id = PAGE_FARMING_SUPPLIER },
    { name = S("  Sprinkler Upgrade"), id = PAGE_SPRINKLER_UPGRADE },
    { name = S("  Wood Supplier"), id = PAGE_WOODCUTTER },
    { name = S("  Leafcutter Upgrade"), id = PAGE_LEAVES_UPGRADE },
    { name = header(S("Utility Machines:"))},
    { name = S("  Vacuum Chest"), id = PAGE_VACCUUM_CHEST },
    { name = S("  Requester Programmer"), id = PAGE_REQUESTER_PROGRAMMER },
    { name = S("  Lava Furnace Fueler"), id = PAGE_LAVA_FUELER },
    { name = S("  Rock Melter"), id = PAGE_ROCK_MELTER },
    { name = S("  Cobble Generator"), id = PAGE_COBBLE_GENERATOR },
    { name = S("  Trashcan"), id = PAGE_TRASHCAN },
    { name = S("  Machine Disassembler"), id = PAGE_DISASSEMBLER },
    { name = S("  Item Monitor"), id = PAGE_ITEM_MONITOR },
    { name = header(S("Machine Upgrades:"))},
    { name = S("  Mass Storage Upgrades"), id = PAGE_MASS_STORAGE_UPGR },
    { name = S("  Cobble Generator Upgrades"), id = PAGE_COBBLE_GENERATOR_UPGR },
    { name = header(S("Tools:"))},
    { name = S("  Hyperspanner"), id = PAGE_HYPERSPANNER },
    { name = S("  State Copy Tool"), id = PAGE_STATE_COPIER },
    { name = header(S("Admin Tools:")), requiredPrivs = {"give", "server"} },
    { name = S("  Infinite Wand"), id = PAGE_INF_WAND, requiredPrivs = {"give", "server"} },
    { name = S("  Inv List Scanner"), id = PAGE_WAND, requiredPrivs = {"give", "server"} },
    { name = header(S("Items:"))},
    { name = S("  Silverin Crystal"), id = PAGE_SILVERIN_CRYSTAL },
    { name = S("  Silverin Slice"), id = PAGE_SILVERIN_SLICE },
    { name = S("  Silverin Circuit"), id = PAGE_SILVERIN_CIRCUIT },
    { name = S("  Silverin Mirror Box"), id = PAGE_SILVERIN_MIRRORBOX },
    { name = S("  Silverin Plate"), id = PAGE_SILVERIN_PLATE },
    { name = S("  Hardened Silverin Block"), id = PAGE_HARDENED_SILVERIN_BLOCK },
    { name = S("  Compression Tank"), id = PAGE_COMPRESSION_TANK },
    { name = S("  Photonizer/Reverse Polarity"), id = PAGE_PHOTONIZERS },
    { name = S("  Wave Function Maintainer"), id = PAGE_WAVE_FUN_MAIN },
    { name = S("  Wireless Crystal"), id = PAGE_WIRELESS_CRYSTAL },
    { name = S("  Wireless Antenna"), id = PAGE_WIRELESS_ANTENNA },
    { name = S("  Signal Relay"), id = PAGE_SIGNAL_RELAY },
    { name = header(S("Misc:"))},
    { name = S("  Server Settings"), id = PAGE_SERVER_SETTINGS },
  },

  pageText = {

    [PAGE_WHATS_NEW_2_0] = {
      title = S("What's New in Logistica 2.0"),
      is_markup = true,
      relatedItems = {L("signal_relay"), L("farming_supplier"), L("woodcutter"), L("rock_melter"), L("disassembler"), L("item_monitor")},
      recipeLinks = RECIPE_LINKS_WHATS_NEW,
      description = desc.whats_new_2_0,
    },

    -- intro

    [PAGE_INTRO] = {
      title = S("Intro to Logistica"),
      relatedItems = {L("lava_furnace")},
      recipeLinks = RECIPE_LINKS,
      description = desc.intro,
    },

    [PAGE_START] = {
      title = S("Getting started with Logistica"),
      relatedItems = {L("silverin"), L("lava_furnace_fueler")},
      recipes = RECIPE_LAVAFURN,
      recipeLinks = RECIPE_LINKS,
      description = desc.get_started,
    },

    [PAGE_CREATE_NET] = {
      title = S("Create a Logistic Network"),
      relatedItems = {L("simple_controller"), L("optic_cable")},
      recipeLinks = RECIPE_LINKS,
      description = desc.create_network,
    },

    [PAGE_MOVE_ITEMS] = {
      title = S("Moving items from/to other mod's machines or storage"),
      relatedItems = {L("injector_slow"), L("requester_item")},
      recipeLinks = RECIPE_LINKS,
      description = desc.move_items,
    },

    -- general machines

    [PAGE_NET_CONTROLLER] = {
      title = S("Network Controller"),
      recipes = RECIPE_NETCONTR,
      recipeLinks = RECIPE_LINKS,
      description = desc.network_controller,
    },

    [PAGE_ACCESS_POINT] = {
      title = S("Access Point"),
      recipes = RECIPE_ACCESSPT,
      recipeLinks = RECIPE_LINKS,
      description = desc.access_point,
    },

    [PAGE_ACCESS_POINT_STORAGE] = {
      title = S("Access Point Mass Storage"),
      recipes = RECIPE_ACCESSPT,
      recipeLinks = RECIPE_LINKS,
      description = desc.access_point_storage,
    },

    [PAGE_ACCESS_POINT_CRAFTING] = {
      title = S("Access Point Crafting"),
      relatedItems = {L("autocrafting_upgrade"), L("autocrafting_recursive_upgrade"), L("wireless_synchronizer")},
      recipes = RECIPE_ACUPGRD,
      recipeLinks = RECIPE_LINKS,
      description = desc.access_point_crafting,
    },

    [PAGE_OPTIC_CABLE] = {
      title = S("Optic cables"),
      relatedItems = {L("simple_controller")},
      recipes = RECIPE_OPTICCBL,
      recipeLinks = RECIPE_LINKS,
      description = desc.optic_cable,
    },

    [PAGE_WIRELESS_UPGRADER] = {
      title = S("Wireless Upgrader"),
      relatedItems = {L("wireless_access_pad"), L("autocrafting_recursive_upgrade")},
      recipes = RECIPE_WRLUPGRD,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_upgrader,
    },

    -- storage

    [PAGE_MASS_STORAGE] = {
      title = S("Mass Storage"),
      recipes = RECIPE_MASSSTOR,
      relatedItems = {L("storage_upgrade_1")},
      recipeLinks = RECIPE_LINKS,
      description = desc.mass_storage,
    },

    [PAGE_TOOL_CHEST] = {
      title = S("Tool Chest"),
      recipes = RECIPE_TOOLCHST,
      recipeLinks = RECIPE_LINKS,
      description = desc.tool_chest,
    },

    [PAGE_PASSIVE_SUPPLIER] = {
      title = S("Passive Supplier Chest"),
      recipes = RECIPE_PASSSUPP,
      recipeLinks = RECIPE_LINKS,
      description = desc.passive_supplier,
    },

    -- moving items

    [PAGE_NETWORK_IMPORTER] = {
      title = S("Network Importer"),
      recipes = RECIPE_NETIMPRT,
      recipeLinks = RECIPE_LINKS,
      description = desc.network_importer,
    },

    [PAGE_REQUEST_INSERTER] = {
      title = S("Request Inserter"),
      recipes = RECIPE_REQINSRT,
      recipeLinks = RECIPE_LINKS,
      description = desc.request_inserter,
    },

    -- wireless network

    [PAGE_WIRELESS_ACCESS_PAD] = {
      title = S("The Wireless Access Pad"),
      relatedItems = {L("wireless_synchronizer")},
      recipes = RECIPE_WIRLSSAP,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_access_pad,
    },

    [PAGE_WIRELESS_TRANSMITTER] = {
      title = S("Wireless Transmitter"),
      relatedItems = {L("wireless_receiver")},
      recipes = RECIPE_WRLSTRNS,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_transmitter,
    },

    [PAGE_WIRELESS_RECEIVER] = {
      title = S("Wireless Receiver"),
      relatedItems = {L("wireless_transmitter")},
      recipes = RECIPE_WRLSRECV,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_receiver,
    },

    -- liquids

    [PAGE_RESERVOIR] = {
      title = S("Liquid Reservoirs"),
      relatedItems = {L("pump")},
      recipes = RECIPE_RESERVOR,
      recipeLinks = RECIPE_LINKS,
      description = desc.reservoir,
    },

    [PAGE_PUMP] = {
      title = S("Reservoir Pump"),
      relatedItems = {L("reservoir_silverin_empty")},
      recipes = RECIPE_RESERPMP,
      recipeLinks = RECIPE_LINKS,
      description = desc.reservoir_pump,
    },

    [PAGE_BUCKET_EMPTIER] = {
      title = S("Bucket Emptier"),
      relatedItems = {L("reservoir_silverin_empty")},
      recipes = RECIPE_BUCKEMPT,
      recipeLinks = RECIPE_LINKS,
      description = desc.bucket_emptier,
    },

    [PAGE_BUCKET_FILLER] = {
      title = S("Bucket Filler"),
      relatedItems = {L("reservoir_silverin_empty")},
      recipes = RECIPE_BUCKFILL,
      recipeLinks = RECIPE_LINKS,
      description = desc.bucket_filler,
    },

    -- autocrafting

    [PAGE_CRAFTING_SUPPLIER] = {
      title = S("Crafting Supplier"),
      recipes = RECIPE_CRAFTSUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.crafting_supplier,
    },

    [PAGE_COOKING_SUPPLIER] = {
      title = S("Cooking Supplier"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_COOKSUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.cooking_supplier,
    },

    [PAGE_AUTOCRAFTER] = {
      title = S("Autocrafter"),
      recipes = RECIPE_AUTOCRFT,
      recipeLinks = RECIPE_LINKS,
      description = desc.autocrafter,
    },

    -- utiltiy nodes

    [PAGE_VACCUUM_CHEST] = {
      title = S("Vacuum Chest"),
      recipes = RECIPE_VACCUUMC,
      recipeLinks = RECIPE_LINKS,
      description = desc.vaccuum_chest,
    },

    [PAGE_REQUESTER_PROGRAMMER] = {
      title = S("Requester Programmer"),
      relatedItems = {L("requester_item"), L("requester_stack")},
      recipes = RECIPE_REQPROGRAMMER,
      recipeLinks = RECIPE_LINKS,
      description = desc.requester_programmer,
    },

    [PAGE_FARMING_SUPPLIER] = {
      title = S("Farming Supplier"),
      recipes = RECIPE_FARMSUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.farming_supplier,
    },

    [PAGE_SPRINKLER_UPGRADE] = {
      title = S("Sprinkler Upgrade"),
      relatedItems = {L("farming_supplier")},
      recipes = RECIPE_SPRINKUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.sprinkler_upgrade,
    },

    [PAGE_WOODCUTTER] = {
      title = S("Wood Supplier"),
      relatedItems = {L("leaves_upgrade")},
      recipes = RECIPE_WOODCUT,
      recipeLinks = RECIPE_LINKS,
      description = desc.woodcutter,
    },

    [PAGE_LEAVES_UPGRADE] = {
      title = S("Leafcutter Upgrade"),
      relatedItems = {L("woodcutter")},
      recipes = RECIPE_LEAVESUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.leaves_upgrade,
    },

    [PAGE_LAVA_FUELER] = {
      title = S("Lava Furnace Fueler"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_LVFRFUEL,
      recipeLinks = RECIPE_LINKS,
      description = desc.lava_furnace_fueler,
    },

    [PAGE_ROCK_MELTER] = {
      title = S("Rock Melter"),
      relatedItems = {L("lava_furnace_fueler"), L("hardened_silverin_block")},
      recipes = RECIPE_ROCKMELT,
      recipeLinks = RECIPE_LINKS,
      description = desc.rock_melter,
    },

    [PAGE_COBBLE_GENERATOR] = {
      title = S("Cobble Generator"),
      relatedItems = {L("cobblegen_upgrade")},
      recipes = RECIPE_COBBLGEN,
      recipeLinks = RECIPE_LINKS,
      description = desc.cobblegen_supplier,
    },

    [PAGE_TRASHCAN] = {
      title = S("Trashcan"),
      recipes = RECIPE_TRASHCAN,
      recipeLinks = RECIPE_LINKS,
      description = desc.trashcan,
    },

    [PAGE_DISASSEMBLER] = {
      title = S("Logistica Machine Disassembler"),
      recipes = RECIPE_DISASSEMBLER,
      recipeLinks = RECIPE_LINKS,
      description = desc.disassembler,
    },

    [PAGE_ITEM_MONITOR] = {
      title = S("Item Monitor"),
      recipes = RECIPE_ITEM_MONITOR,
      recipeLinks = RECIPE_LINKS,
      description = desc.item_monitor,
    },

    -- node upgrades

    [PAGE_MASS_STORAGE_UPGR] = {
      title = S("Mass Storage Upgrades"),
      relatedItems = {L("mass_storage_basic")},
      recipes = RECIPE_MASSUPGR,
      recipeLinks = RECIPE_LINKS,
      description = desc.mass_storage_upgrade,
    },

    [PAGE_COBBLE_GENERATOR_UPGR] = {
      title = S("Cobble Generator Upgrades"),
      relatedItems = {L("cobblegen_supplier")},
      recipes = RECIPE_COBGENUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.cobblegen_upgrade,
    },

    -- tools

    [PAGE_HYPERSPANNER] = {
      title = S("Hyperspanner"),
      recipes = RECIPE_HYPERSPN,
      recipeLinks = RECIPE_LINKS,
      description = desc.hyperspanner,
    },

    [PAGE_STATE_COPIER] = {
      title = S("State Copy Tool"),
      recipes = RECIPE_STATECPY,
      recipeLinks = RECIPE_LINKS,
      description = desc.state_copier,
    },

    -- admin tools

    [PAGE_INF_WAND] = {
      title = S("Infinite Wand"),
      description = desc.inf_wand,
    },

    [PAGE_WAND] = {
      title = S("Inv List Scanner"),
      description = desc.wand,
    },

    -- items

    [PAGE_SILVERIN_CRYSTAL] = {
      title = S("Silverin Crystal"),
      relatedItems = {L("lava_furnace"), L("silverin_slice")},
      recipes = RECIPE_SILVERIN,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_crystal,
    },

    [PAGE_SILVERIN_SLICE] = {
      title = S("Silverin Slice"),
      relatedItems = {L("silverin")},
      recipes = RECIPE_SILVSLIC,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_slice,
    },

    [PAGE_SILVERIN_CIRCUIT] = {
      title = S("Silverin Circuit"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_SILVCIRC,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_circuit,
    },

    [PAGE_SILVERIN_MIRRORBOX] = {
      title = S("Mirror Box"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_SILVMIRR,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_mirror_box,
    },

    [PAGE_SILVERIN_PLATE] = {
      title = S("Silverin Plate"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_SILVPLAT,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_plate,
    },

    [PAGE_HARDENED_SILVERIN_BLOCK] = {
      title = S("Hardened Silverin Block"),
      relatedItems = {L("rock_melter"), L("lava_furnace")},
      recipes = RECIPE_HARDSILBLK,
      recipeLinks = RECIPE_LINKS,
      description = desc.hardened_silverin_block,
    },

    [PAGE_COMPRESSION_TANK] = {
      title = S("Compression Tank"),
      relatedItems = {L("reservoir_silverin_empty")},
      recipes = RECIPE_COMPTANK,
      recipeLinks = RECIPE_LINKS,
      description = desc.compression_tank,
    },

    [PAGE_PHOTONIZERS] = {
      title = S("Photonizer and Reverse Polarity Photonizer"),
      recipes = RECIPE_PHOTONIZ,
      recipeLinks = RECIPE_LINKS,
      description = desc.photonizers,
    },

    [PAGE_WAVE_FUN_MAIN] = {
      title = S("Wave Function Maintainer"),
      recipes = RECIPE_STANDWAV,
      recipeLinks = RECIPE_LINKS,
      description = desc.wave_func_main,
    },

    [PAGE_WIRELESS_CRYSTAL] = {
      title = S("Wireless Crystal"),
      relatedItems = {L("wireless_access_pad"), L("wireless_synchronizer"), L("lava_furnace")},
      recipes = RECIPE_WRLSCRYS,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_crystal,
    },

    [PAGE_WIRELESS_ANTENNA] = {
      title = S("Wireless Antenna"),
      relatedItems = {L("wireless_transmitter"), L("wireless_receiver") },
      recipes = RECIPE_WRLSANTN,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_antenna,
    },

    -- signals

    [PAGE_SIGNALS_OVERVIEW] = {
      title = S("Signals"),
      relatedItems = {L("signal_button"), L("signal_switch"), L("signal_lamp_white"), L("signal_lamp_2c_br"), L("signal_toggler"), L("signal_not_gate"), L("signal_logic_gate"), L("mesecon_signaler"), L("mesecon_sender"), L("signal_item_counter"), L("signal_liquid_counter"), L("signal_ext_reader"), L("signal_timer"), L("signal_delayer")},
      recipeLinks = RECIPE_LINKS,
      description = desc.signals_overview,
    },

    [PAGE_SIGNAL_RELAY] = {
      title = S("Signal Relay"),
      recipes = RECIPE_SIG_RELAY,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_relay,
    },

    [PAGE_SIGNAL_BUTTON] = {
      title = S("Signal Button"),
      recipes = RECIPE_SIG_BUTTON,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_button,
    },

    [PAGE_SIGNAL_SWITCH] = {
      title = S("Signal Switch"),
      recipes = RECIPE_SIG_SWITCH,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_switch,
    },

    [PAGE_SIGNAL_LAMP] = {
      title = S("Signal Lamp"),
      recipes = RECIPE_SIG_LAMP,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_lamp,
    },

    [PAGE_SIGNAL_LAMP_2C] = {
      title = S("Signal Lamp (2-Color)"),
      recipes = RECIPE_SIG_LAMP2C,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_lamp_2c,
    },

    [PAGE_SIGNAL_TOGGLER] = {
      title = S("Signal Network Switch"),
      recipes = RECIPE_SIG_TOGGLER,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_toggler,
    },

    [PAGE_SIGNAL_NOT_GATE] = {
      title = S("Signal NOT Gate"),
      recipes = RECIPE_SIG_NOT,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_not_gate,
    },

    [PAGE_SIGNAL_LOGIC_GATE] = {
      title = S("Signal Logic Gate"),
      recipes = RECIPE_SIG_LOGIC,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_logic_gate,
    },

    [PAGE_SIGNAL_TOGGLE] = {
      title = S("Signal Toggle"),
      recipes = RECIPE_SIG_TOGGLE,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_toggle,
    },

    [PAGE_SIGNAL_ITEM_COUNTER] = {
      title = S("Signal Item Count Sender"),
      recipes = RECIPE_SIG_COUNTER,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_item_counter,
    },

    [PAGE_SIGNAL_LIQUID_COUNTER] = {
      title = S("Signal Liquid Count Sender"),
      recipes = RECIPE_SIG_LIQCNT,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_liquid_counter,
    },

    [PAGE_SIGNAL_EXT_READER] = {
      title = S("External Content Reader"),
      recipes = RECIPE_SIG_EXTRD,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_ext_reader,
    },

    [PAGE_SIGNAL_TIMER] = {
      title = S("Signal Timer Sender"),
      recipes = RECIPE_SIG_TIMER,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_timer,
    },

    [PAGE_SIGNAL_NODE_DETECTOR] = {
      title = S("Signal Node Detector"),
      recipes = RECIPE_SIG_NODEDET,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_node_detector,
    },

    [PAGE_SIGNAL_NODE_PLACER] = {
      title = S("Signal Node Placer"),
      recipes = RECIPE_SIG_NODEPLACER,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_node_placer,
    },

    [PAGE_SIGNAL_NODE_DIGGER] = {
      title = S("Signal Node Digger"),
      recipes = RECIPE_SIG_NODEDIGGER,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_node_digger,
    },

    [PAGE_DIGILINE_SENDER] = {
      title = S("Digiline Signal Sender"),
      recipes = RECIPE_DIGILINE_SENDER,
      recipeLinks = RECIPE_LINKS,
      description = desc.digiline_sender,
    },

    [PAGE_DIGILINE_RECEIVER] = {
      title = S("Digiline to Signal Converter"),
      recipes = RECIPE_DIGILINE_RECEIVER,
      recipeLinks = RECIPE_LINKS,
      description = desc.digiline_receiver,
    },

    [PAGE_SIGNAL_MONITOR] = {
      title = S("Signal Monitor"),
      recipes = RECIPE_SIG_MONITOR,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_monitor,
    },

    [PAGE_SIGNAL_DELAYER] = {
      title = S("Signal Delayer"),
      recipes = RECIPE_SIG_DELAYER,
      recipeLinks = RECIPE_LINKS,
      description = desc.signal_delayer,
    },

    [PAGE_MESECON_SIG_RECEIVER] = {
      title = S("Mesecon Signal Receiver"),
      recipes = RECIPE_SIG_MESR,
      recipeLinks = RECIPE_LINKS,
      description = desc.mesecon_signal_receiver,
    },

    [PAGE_MESECON_SIG_SENDER] = {
      title = S("Mesecon Signal Sender"),
      recipes = RECIPE_SIG_MESS,
      recipeLinks = RECIPE_LINKS,
      description = desc.mesecon_signal_sender,
    },

    -- Settings

    [PAGE_SERVER_SETTINGS] = {
      title = S("Server Settings"),
      description = desc.server_settings,
    },
  }
})
