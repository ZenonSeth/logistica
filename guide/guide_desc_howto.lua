local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

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

# Taking Items

To take items from machines of other mods, or storage of other mods, you can use a Network Importer - see button above for details. 

In the rare case where the network importer cannot access the inventory of a machine or storage, try to use machines from the other mod to put all the items in a regular Chest, then use the Network Importer to take items from the Chest.

# Placing Items

To place items into other mahcines, ues a Request Inserter - see button above for details. 

# What NOT to do

Don't try to use Passive Supply chests as outputs of other mod's machines. Passive Supply chests have no direct compatibility with other mods, and are just a utility for personal storage.
]])
