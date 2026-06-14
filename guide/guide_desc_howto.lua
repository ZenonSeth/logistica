local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

do
  local H = "#CCFF66"
  local function h(t) return "<style color=" .. H .. "><b>" .. t .. "</b></style>" end
  local n = "\n\n"

  g.whats_new_2_0 =
    h("Signals") .. "\n" ..
    "Signals are named on/off states that travel within a single Logistica network via the regular cables." .. n ..
    "- <b>Senders:</b> Signal Switch, Signal Button, Signal Timer, Signal Item Counter, Signal Liquid Counter, External Content Reader, Node Detector, Mesecon Signal Receiver.\n" ..
    "- <b>Receivers:</b> Signal Lamp, Signal Lamp (2-Color), Signal Network Switch, Mesecon Signal Sender, Node Placer, Node Digger.\n" ..
    "- <b>Logic:</b> Signal NOT Gate, Signal Logic Gate (AND/OR/XOR/ADDER).\n" ..
    "- <b>Experimental:</b> Digiline Signal Sender - polls the network and sends item counts as digiline messages on a configurable channel.\n" ..
    "- <b>Experimental:</b> Digiline to Signal Converter - listens on a digiline channel and broadcasts a named Logistica signal based on the received message." .. n ..

    h("Access Point Autocrafting") .. "\n" ..
    "The Access Point has a new Crafting tab. With the Autocrafting Upgrade installed you can search recipes, view ingredients, and craft to an output slot. The Recursive Crafting Upgrade adds a queue that chains crafting steps automatically." .. n ..

    h("Access Point Storage Management") .. "\n" ..
    "A new tab in the Access Point lets you configure Mass Storage slots directly: set reserve amounts, demand targets, and whether to include crafting suppliers in demand." .. n ..

    h("New Machines") .. "\n" ..
    "- <b>Farming Supplier:</b> harvests and replants crops in a configurable area. Add the Sprinkler Upgrade to accelerate growth.\n" ..
    "- <b>Wood Supplier:</b> chops trees in a configurable area and replants saplings. Add the Leafcutter Upgrade to also collect leaves.\n" ..
    "- <b>Rock Melter:</b> a passive lava source on the network. Provides a read-only lava reservoir that other machines can draw from.\n" ..
    "- <b>Machine Disassembler:</b> converts Logistica machines back into their component materials.\n" ..
    "- <b>Item Monitor:</b> tracks up to 8 items over time and displays a rolling graph with per-point tooltips. Polling interval is configurable." .. n ..

    h("Network Access Control") .. "\n" ..
    "The Network Controller now tracks an owner (set on placement). The owner can grant access to other players by name and optionally hide network contents from players who lack area protection. Players without owner status, area rights, or access list entry cannot move or take items." .. n ..

    h("Mass Storage") .. "\n" ..
    "Reserve and Demand are now per-slot input fields. Each slot can optionally include crafting suppliers in its demand calculation. A new Multiplexer Upgrade multiplies a unit's storage capacity by 16." .. n ..

    h("Other Changes") .. "\n" ..
    "- Passive Supply Chest inventory expanded from 16 to 32 slots. Storing from machines and from the access point are now separately toggleable.\n" ..
    "- Request Inserter filter slots now use numeric quantity fields (up to 9999) instead of item stacks.\n" ..
    "- Vacuum Chest pickup range is configurable from 1 to 3 nodes.\n" ..
    "- Upgrade recipes added for the Network Importer and Request Inserter.\n" ..
    "- Access Point displays large item counts in K and M notation." ..
    "\n\n\n\n\n"
end

g.intro = S([[
Logistica is an item storage and transportation mod.

It provides easy to use storage that can be used standalone, or connected to a logistic network.

The Logistic network is able to transport items - both taking from other mod's machines and inserting items into them. The network transportation works on-demand: only the exact amount of items needed are moved. 

Logistica also provides a way to access all your storage remotely, from potentially unlimited distance (configured per server).

To see how to get started, click the 'Get Started' entry in the list on the left.
]])

g.get_started = S([[
In order to construct all other Logistica machines, you need a unique material: Silverin Crystals, which are made in a Lava Furnace.

The Lava Furnace can only be fueled by Lava. Place lava buckets in the lower left slot to fuel it manually, or later construct a Lava Fueler.

The Lava Furnace has a built-in recipe guide, accessed by clicking the [?] button in the upper right corner.

There are 2 recipes for Silverin Crystals, one that uses Snow as the additive, one that uses Ice. Both recipes use 25 milibuckets of Lava (that's 25/1000 of a full bucket) so 1 bucket of fuel can make 40 Silverin Crystals.

The Lava Furnace can also cook regular recipes in half the regular cooking time, but at the cost of using a bit of lava. For normal items it uses 5 milibuckets (0.005 buckets) of lava per second of cooking time.
]])

g.create_network = S([[
You can use all storages as stand-alone nodes. 

However if you want to access all your storage from one place OR you want to import items from other machines or distribute items to other machines, you need to create a Logistic Network and connect your storages to it.

To create a Logistic Network you need a Network Controller (click button above for more info). A network can have at most 1 Network Controller, trying to connect more will disable the newly connected ones.

Once you have a Network Controller, use Optic Cables to connect the controller to all machines: storage, injectors, importers, etc can all be connected to a network. There are only a few machines that are not network connectable, such as the Autocrafter, but in those cases you can use Network Importers and Request Inserters to interact with them.
]])

g.move_items = S([[
Logistica allows you to access the inventories of machines or storage from other mods - both to take and insert items.

Taking Items
------------------------------
To take items from machines of other mods, or storage of other mods, you can use a Network Importer - see button above for details.

In the rare case where the network importer cannot access the inventory of a machine or storage, try to use machines from the other mod to put all the items in a regular Chest, then use the Network Importer to take items from the Chest.

Placing Items
------------------------------
To place items into other machines, use a Request Inserter - see button above for details. 

What NOT to do
------------------------------
Don't try to use Passive Supply chests as outputs of other mod's machines. Passive Supply chests have no direct compatibility with other mods, and are just a utility for personal storage.
]])
