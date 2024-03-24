local S = logistica.TRANSLATOR
local function L(s) return "logistica:"..s end
local GUIDE_NAME = "logistica_guide"

local PAGE_INTRO = "intro"
local PAGE_START = "start"

local PAGE_CREATE_NET = "crtnet"
local PAGE_MOVE_ITEMS = "mvitms"

local PAGE_NET_CONTROLLER = "mnetcon"
local PAGE_ACCESS_POINT = "maccpt"
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
local PAGE_AUTOCRAFTER = "mautocrf"
local PAGE_VACCUUM_CHEST = "mvacchs"
local PAGE_LAVA_FUELER = "mlvfuel"
local PAGE_COBBLE_GENERATOR = "mcobgen"
local PAGE_TRASHCAN = "mtrash"

local PAGE_MASS_STORAGE_UPGR = "msstup"
local PAGE_COBBLE_GENERATOR_UPGR = "cbgnup"

local PAGE_WIRELESS_ACCESS_PAD = "iwrlap"
local PAGE_HYPERSPANNER = "ihyper"

local PAGE_SILVERIN_CRYSTAL = "isilcry"
local PAGE_SILVERIN_SLICE = "isilsli"
local PAGE_SILVERIN_CIRCUIT = "isilcir"
local PAGE_SILVERIN_MIRRORBOX = "isilmbx"
local PAGE_SILVERIN_PLATE = "isilplt"
local PAGE_COMPRESSION_TANK = "icomptnk"
local PAGE_PHOTONIZERS = "iphtns"
local PAGE_WAVE_FUN_MAIN = "iwvfnm"
local PAGE_WIRELESS_CRYSTAL = "iwrcry"

local PAGE_SERVER_SETTINGS = "servset"

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
local RECIPE_OPTICCBL = getrec({L("optic_cable"), L("optic_cable_toggleable_off"), L("optic_cable_block")})
local RECIPE_MASSSTOR = getrec({L("mass_storage_basic")})
local RECIPE_TOOLCHST = getrec({L("item_storage")})
local RECIPE_PASSSUPP = getrec({L("passive_supplier")})
local RECIPE_NETIMPRT = getrec({L("injector_slow"), L("injector_fast")})
local RECIPE_REQINSRT = getrec({L("requester_item"), L("requester_stack")})
local RECIPE_RESERVOR = getrec({L("reservoir_obsidian_empty"), L("reservoir_silverin_empty")})
local RECIPE_RESERPMP = getrec({L("pump")})
local RECIPE_WRLUPGRD = getrec({L("wireless_synchronizer")})
local RECIPE_CRAFTSUP = getrec({L("crafting_supplier")})
local RECIPE_AUTOCRFT = getrec({L("autocrafter")})
local RECIPE_BUCKFILL = getrec({L("bucket_filler")})
local RECIPE_BUCKEMPT = getrec({L("bucket_emptier")})
local RECIPE_VACCUUMC = getrec({L("vaccuum_chest")})
local RECIPE_LVFRFUEL = getrec({L("lava_furnace_fueler")})
local RECIPE_COBBLGEN = getrec({L("cobblegen_supplier")})
local RECIPE_TRASHCAN = getrec({L("trashcan")})

local RECIPE_MASSUPGR = getrec({L("storage_upgrade_1"), L("storage_upgrade_2")})
local RECIPE_COBGENUP = getrec({L("cobblegen_upgrade")})
local RECIPE_HYPERSPN = getrec({L("hyperspanner")})
local RECIPE_PHOTONIZ = getrec({L("photonizer"), L("photonizer_reversed")})
local RECIPE_STANDWAV = getrec({L("standing_wave_box")})
local RECIPE_WIRLSSAP = getrec({L("wireless_access_pad")})
local RECIPE_COMPTANK = getrec({L("compression_tank")})
local RECIPE_SILVSLIC = getrec({L("silverin_slice")})

local RECIPE_SILVERIN = getlavarec(L("silverin"))
local RECIPE_SILVPLAT = getlavarec(L("silverin_plate"))
local RECIPE_SILVCIRC = getlavarec(L("silverin_circuit"))
local RECIPE_SILVMIRR = getlavarec(L("silverin_mirror_box"))
local RECIPE_WRLSCRYS = getlavarec(L("wireless_crystal"))

local RECIPE_LINKS = {
  -- items
  [L("lava_furnace")] = PAGE_START,
  [L("silverin")] = PAGE_SILVERIN_CRYSTAL,
  [L("silverin_slice")] = PAGE_SILVERIN_SLICE,
  [L("silverin_mirror_box")] = PAGE_SILVERIN_MIRRORBOX,
  [L("silverin_plate")] = PAGE_SILVERIN_PLATE,
  [L("compression_tank")] = PAGE_COMPRESSION_TANK,
  [L("photonizer")] = PAGE_PHOTONIZERS,
  [L("photonizer_reversed")] = PAGE_PHOTONIZERS,
  [L("standing_wave_box")] = PAGE_WAVE_FUN_MAIN,
  [L("wireless_crystal")] = PAGE_WIRELESS_CRYSTAL,
  [L("wireless_access_pad")] = PAGE_WIRELESS_ACCESS_PAD,
  [L("hyperspanner")] = PAGE_HYPERSPANNER,
  [L("optic_cable")] = PAGE_OPTIC_CABLE,
  [L("optic_cable_toggleable_off")] = PAGE_OPTIC_CABLE,
  [L("optic_cable_block")] = PAGE_OPTIC_CABLE,
  [L("storage_upgrade_1")] = PAGE_MASS_STORAGE_UPGR,
  [L("storage_upgrade_2")] = PAGE_MASS_STORAGE_UPGR,
  [L("cobblegen_upgrade")] = PAGE_COBBLE_GENERATOR_UPGR,
  [L("silverin_circuit")] = PAGE_SILVERIN_CIRCUIT,

  -- machines
  [L("lava_furnace_fueler")] = PAGE_LAVA_FUELER,
  [L("reservoir_silverin_empty")] = PAGE_RESERVOIR,
  [L("reservoir_obsidian_empty")] = PAGE_RESERVOIR,
  [L("wireless_synchronizer")] = PAGE_WIRELESS_UPGRADER,
  [L("simple_controller")] = PAGE_NET_CONTROLLER,
  [L("injector_slow")] = PAGE_NETWORK_IMPORTER,
  [L("requester_item")] = PAGE_REQUEST_INSERTER,
  [L("pump")] = PAGE_PUMP,
  [L("mass_storage_basic")] = PAGE_MASS_STORAGE,
  [L("cobblegen_supplier")] = PAGE_COBBLE_GENERATOR,

}

--------------------------------
-- Registration
--------------------------------

local function header(str)
  return "#CCFF66"..str
end

local desc = logistica.Guide.Desc

logistica.GuideApi.register(GUIDE_NAME, {
  title = S("Logistica Guide"),

  formspecBackgroundStr = logistica.ui.background,

  tableOfContentWidth = 4.5,
  contentWidth = 15,
  totalHeight = 14,

  tableOfContent = {
    { name = header(S("Intro")), id = PAGE_INTRO },
    { name = header(S("How To:"))},
    { name = S("  Get Started: The Lava Furnace"), id = PAGE_START },
    { name = S("  Create a Logistic Network"), id = PAGE_CREATE_NET },
    { name = S("  Move items from/to other mods"), id = PAGE_MOVE_ITEMS },
    { name = header(S("General Machines:"))},
    { name = S("  Network Controller"), id = PAGE_NET_CONTROLLER },
    { name = S("  Access Point"), id = PAGE_ACCESS_POINT },
    { name = S("  Optic Cables"), id = PAGE_OPTIC_CABLE },
    { name = S("  Wireless Upgrader"), id = PAGE_WIRELESS_UPGRADER },
    { name = header(S("Storage:"))},
    { name = S("  Mass Storage"), id = PAGE_MASS_STORAGE },
    { name = S("  Tool Chest"), id = PAGE_TOOL_CHEST },
    { name = S("  Passive Supplier Chest"), id = PAGE_PASSIVE_SUPPLIER },
    { name = header(S("Moving Items:"))},
    { name = S("  Network Importer"), id = PAGE_NETWORK_IMPORTER },
    { name = S("  Request Inserter"), id = PAGE_REQUEST_INSERTER },
    { name = header(S("Liquid Storage:"))},
    { name = S("  Reservoirs"), id = PAGE_RESERVOIR },
    { name = S("  Reservoir Pump"), id = PAGE_PUMP },
    { name = S("  Bucket Filler"), id = PAGE_BUCKET_FILLER },
    { name = S("  Bucket Emptier"), id = PAGE_BUCKET_EMPTIER },
    { name = header(S("Autocrafting:"))},
    { name = S("  Crafting Supplier"), id = PAGE_CRAFTING_SUPPLIER },
    { name = S("  Autocrafter"), id = PAGE_AUTOCRAFTER },
    { name = header(S("Utility Machines:"))},
    { name = S("  Vaccuum Chest"), id = PAGE_VACCUUM_CHEST },
    { name = S("  Lava Furnace Fueler"), id = PAGE_LAVA_FUELER },
    { name = S("  Cobble Generator"), id = PAGE_COBBLE_GENERATOR },
    { name = S("  Trashcan"), id = PAGE_TRASHCAN },
    { name = header(S("Machine Upgrades:"))},
    { name = S("  Mass Storage Upgrades"), id = PAGE_MASS_STORAGE_UPGR },
    { name = S("  Cobble Generator Upgrades"), id = PAGE_COBBLE_GENERATOR_UPGR },
    { name = header(S("Tools:"))},
    { name = S("  Wireless Access Pad"), id = PAGE_WIRELESS_ACCESS_PAD },
    { name = S("  Hyperspanner"), id = PAGE_HYPERSPANNER },
    { name = header(S("Items:"))},
    { name = S("  Silverin Crystal"), id = PAGE_SILVERIN_CRYSTAL },
    { name = S("  Silverin Slice"), id = PAGE_SILVERIN_SLICE },
    { name = S("  Silverin Circuit"), id = PAGE_SILVERIN_CIRCUIT },
    { name = S("  Silverin Mirror Box"), id = PAGE_SILVERIN_MIRRORBOX },
    { name = S("  Silverin Plate"), id = PAGE_SILVERIN_PLATE },
    { name = S("  Compression Tank"), id = PAGE_COMPRESSION_TANK },
    { name = S("  Photonizer/Reverse Polarity"), id = PAGE_PHOTONIZERS },
    { name = S("  Wave Function Maintainer"), id = PAGE_WAVE_FUN_MAIN },
    { name = S("  Wireless Crystal"), id = PAGE_WIRELESS_CRYSTAL },
    { name = header(S("Misc:"))},
    { name = S("  Server Settings"), id = PAGE_SERVER_SETTINGS },
  },

  pageText = {

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

    [PAGE_OPTIC_CABLE] = {
      title = S("Optic cables"),
      relatedItems = {L("simple_controller")},
      recipes = RECIPE_OPTICCBL,
      recipeLinks = RECIPE_LINKS,
      description = desc.optic_cable,
    },

    [PAGE_WIRELESS_UPGRADER] = {
      title = S("Wireless Upgrader"),
      relatedItems = {L("wireless_access_pad")},
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
      title = S("Optic cables"),
      recipes = RECIPE_TOOLCHST,
      recipeLinks = RECIPE_LINKS,
      description = desc.tool_chest,
    },

    [PAGE_PASSIVE_SUPPLIER] = {
      title = S("Wireless Upgrader"),
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

    -- liquids

    [PAGE_RESERVOIR] = {
      title = S("Liquid Reservoirs"),
      relatedItems = {L("pump")},
      recipes = RECIPE_RESERVOR,
      recipeLinks = RECIPE_LINKS,
      description = desc.reservoir,
    },

    [PAGE_PUMP] = {
      title = S("Resevoir Pump"),
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
      title = S("Crafting Supplierr"),
      recipes = RECIPE_CRAFTSUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.crafting_supplier,
    },

    [PAGE_AUTOCRAFTER] = {
      title = S("Autocrafter"),
      recipes = RECIPE_AUTOCRFT,
      recipeLinks = RECIPE_LINKS,
      description = desc.autocrafter,
    },

    -- utiltiy nodes

    [PAGE_VACCUUM_CHEST] = {
      title = S("Vaccuum Chest"),
      recipes = RECIPE_VACCUUMC,
      recipeLinks = RECIPE_LINKS,
      description = desc.vaccuum_chest,
    },

    [PAGE_LAVA_FUELER] = {
      title = S("Lava Furnace Fueler"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_LVFRFUEL,
      recipeLinks = RECIPE_LINKS,
      description = desc.lava_furnace_fueler,
    },

    [PAGE_COBBLE_GENERATOR] = {
      title = S("Cobblestone Generator"),
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

    -- node upgrades

    [PAGE_MASS_STORAGE_UPGR] = {
      title = S("Mass Storage Upgrades"),
      relatedItems = {L("mass_storage_basic")},
      recipes = RECIPE_MASSUPGR,
      recipeLinks = RECIPE_LINKS,
      description = desc.mass_storage_upgrade,
    },

    [PAGE_COBBLE_GENERATOR_UPGR] = {
      title = S("Cobblestone Generator Upgrades"),
      relatedItems = {L("cobblegen_supplier")},
      recipes = RECIPE_COBGENUP,
      recipeLinks = RECIPE_LINKS,
      description = desc.cobblegen_upgrade,
    },

    -- tools

    [PAGE_WIRELESS_ACCESS_PAD] = {
      title = S("The Wireless Access Pad"),
      relatedItems = {L("wireless_synchronizer")},
      recipes = RECIPE_WIRLSSAP,
      recipeLinks = RECIPE_LINKS,
      description = desc.wireless_access_pad,
    },

    [PAGE_HYPERSPANNER] = {
      title = S("Hyperspanner"),
      recipes = RECIPE_HYPERSPN,
      recipeLinks = RECIPE_LINKS,
      description = desc.hyperspanner,
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
      title = S("Silvrin Silce"),
      relatedItems = {L("silverin")},
      recipes = RECIPE_SILVSLIC,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_slice,
    },

    [PAGE_SILVERIN_CIRCUIT] = {
      title = S("Silvrin Circuit"),
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
      title = S("Silvrin Plate"),
      relatedItems = {L("lava_furnace")},
      recipes = RECIPE_SILVPLAT,
      recipeLinks = RECIPE_LINKS,
      description = desc.silverin_plate,
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
    
    -- Settings

    [PAGE_SERVER_SETTINGS] = {
      title = S("Server Settings"),
      description = desc.server_settings,
    },
  }
})
