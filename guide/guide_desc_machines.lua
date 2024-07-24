local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

g.network_controller = [[
A Controller is the node required to create an active network. Exactly one controller can be connected to a network, and removing it will disconnect all other devices connected to the network.

Controllers allow you to rename the network, but this is for visual identification only, and naming two networks with the same name will not connect them together.
]]

g.access_point = [[
The Access Point provides easy access to all Storage devices connected to the Network.

It can both take and insert items into the network's storage. It provides a Crafting Grid built into it for convenience.

You can also access an Access Point and all its features remotely using a Wireless Access Pad synced to the Access Point.

# Searching by text

You can enter a search term to show items that term.

A special search can be done by adding the groups: prefix at the start. For example groups:flower will match only items that have flower group set, thus it will display all flowers added by any mod.

# Filtering

You can filter items by:

All items, Blocks only, Craft-items only, Tools only, Lights only

# Sorting

Items can also sorted by

- Name: alphabetically sorted by the item's localized description to sort
- Mod: alphabetically sorted by the item's technical name that is prefixed with the mod
- Count: sorts by total item count, with largest first.
- Wear: Sorts by item wear, with most uses remaining first (best used when filtering for Tools only)

# Use Metadata button

Some items, usually tools, have other information stored in them, like wear, descriptions or more complex metadata.

If "Use Metadata" is ON, the Access Point will display these items individually. If it's OFF, the Access Point will group items with the same name, but different metadata into 1 stack. When taking such an item when Use Metadata is OFF, you will still receive an actual item with the correct wear and metadata, but it will be picked at random from the network.

# Liquid Storage

Below the Metadata button is a small section where the Access Point will show any Reservoirs connected to the network.

You can use the two arrows to cycle through all liquids (if there are any).
To deposit a liquid, just put a full bucket into the slot below the liquid image. It does not matter which liquid is selected for this, the Access Point will attempt to deposit it into the fullest applicable Reservoir, or assign the next smallest empty reservoir, if one is available.
To withdraw a liquid, first select which liquid you want, then put an Empty Bucket into the slot below. The liquid will be taken from the least-full Reservoir holding that liquid type on the Network.

# Taking items from the Network

The Access Point shows a snapshot of available items, or items supplied by crafting suppliers. When you try to take an item, the Access Point makes a real request to the network. If the items are no longer available, you won't receive anything. In most cases the Access Point will try to show an error message informing what went wrong.
]]

g.optic_cable = [[
# Regular Cables

Cables are used to connect a controller to other machines, allowing the establishing of a network.

Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables.

Note that Cables are the only way to extend a network's reach - meaning, machines will not carry the network connection through them. If you connect a network cable to one side of a machine, and then place a 2nd cable on the other side of the machine, the 2nd cable will not carry the network connection.

# Toggleable Cables
The Toggleable Cable works exactly like a regular cable, but can be right-clicked (aka used) to disconnect it from all other surrounding cables or machines. This allows you to make parts of your network easy to disconnect when you don't want to use them (For example, a disconnecting an auto-furnace setup when you don't need it anymore)

#Embedded Cables
The Embedded Cable is a full block that acts like a regular Optic Cable, allowing cables to be run through walls without leaving visible gaps.
]]

g.wireless_upgrader = [[
The Wireless Upgrader is a machine used to upgrade the Wireless Access Pad's range.

To upgrade a Wireless Access Pad:

1. Craft the Wireless Upgrader
2. In the Wireless Upgrader put the Wireless Access Pad at the bottom slot, and 1 Wireless crystal in each top slot (see screenshot above)
3. You'll see two waves appear, one blue, one orange. The Orange wave is controlled by the buttons around the crystals.
4. Use the buttons around each Crystal to make the orange wave match the blue wave.
5. When they match, the wave turns Green and an Upgrade button appears.
6. Press the Upgrade button to increase your Wireless Access Pad's range.

The Wireless Upgrader also has a "Hard Mode" toggleable via settings - see the "Server Settings" page on the left for info.
]]

g.mass_storage = [[
Mass Storage node provide 1024 item storage for up to 8 different item types by default. This capacity can be upgraded with 4 upgrade lots and 2 different upgrades. Mass Storage needs to be configured with the exact items to store.

You can collectively access all Mass Storage on a particular network from an Access Point/Wireless Access Pad.

- Can be dug and keeps its Inventory when placed again, allowing easy moving of stored items
- Can be upgraded to increase inventory size, up to maximum of 5120 items per slot
- Select Front Image: Selects a stored node to display on the front of the storage node
- Can Reserve a number of items per slot: Reserved items won't be taken by other machines on the network
- Can quickly deposit items by punching it with a stack or sneak-punching it for deposit all stack items from your inventory
- Pull items on/off: When On this storage will actively try to pull from any Supplier machines (e.g. Passive Supply Chests, Cobblegen Suppliers), except Crafting Suppliers.]]

g.tool_chest = [[
The Tool Chest provides a large number of storage slots -- but it can only store tools (specifically, items that have a max stack size of 1). The Tool Chest is also accessed by Requesters to provide items. Tool Chest cannot be dug while it contains items (unlike Mass Storage, which will keep its inventory)

You can also choose to sort the stored tools by Name, Mod or Wear.
]]

g.passive_supplier = [[
A Passive Supplier Chest acts as a regular chest, and a source for items for network requests.

It has a small inventory, as it is not meant to be used for regular storage, but any item can be put in it. Passive Supplier Chests won't actively push items into the network, but Demanders and Mass Storage nodes can both take items from Suppliers when needed. Passive Supplier Chests have a toggle if they should also accept items to be stored in them from Network Importers.
]]

g.network_importer = [[
Network Importer are used to automatically take items from other nodes (e.g. furnaces) and add them to the network.

To get a Network Importer working you must:

- Place it facing a node that has an inventory it can access. Sneak + punch an importer to see its input position.
- Select which inventory of the target node to take from - some nodes have multiple inventories, and one must be selected.
- Make sure you press the Enable button to enable its functionality.
- Optionally, you can configure the importer to only pull specific items by placing them in the Filter List. If the list is empty, the importer will indiscriminately attempt to pull any item, slot by slot, from its input node.

Network importers scan 1 slot, and rotate which slot they take from each time they tick.

Network Importers prioritize where they put their items in this order:

- Fill the requests of any Requesters on the network
- Fill any Mass Storage that can handle this item
- Fill any passive supply chests (if the chests are configured to accept items from the network)
- Trash the item if there's any Trashcans connected that accept this kind of item. (see Trashcan)

There's 2 version of the Network Importer:

- Slow Network Importer: Takes up to 10 items from a slot at a time, and tries to insert it in the network.
- Fast Network Importer: Takes up to 99 items from a slot at a time, and tries to insert them in the network.

Note that how many items can be sent at one time to a Requester is still limited by the Requester itself (meaning an Item Requester will only receive 1 item, while a Stack Requester will receive up to 99). However when sending to Mass Storage or Passive Supply chests, the full stack the importer is capable of taking will be sent.
]]

g.request_inserter = [[
The Request Inserter is used to put items in other nodes outside the network.

Note that while there item-wise and stack-wise Inserters, in ALMOST ALL you only need the item-wise Inserter.

To use an Inserter, you must:

- Place it facing a node that has an inventory it can target. Sneak + punching an inserter will show its output location.
- Pick an inventory to place items into. Some nodes have multiple input inventories (e.g. a furnace)
- Configure exactly which items to put in the target and how many - in the 4 upper slots. If not configured, nothing will be inserted.
- Make sure you press the Enable button to enable operation
- Request Inserters will request the configured items from the Network and try to keep its target's inventory full of at the minimum the specific items and the exact count. For example, a Request Inserter might be configured to target a Furnace's "fuel" inventory and always try to keep 2 Coal in it, while another request inserter targeting the same furnace, but it's "src" inventory can be configured to try and always keep 2 Iron Ore in it.
- You can also check the "Inf" (short for "Infinite") checkbox to make the Request Inserter always request the item

When the "Inf" checkbox below a slot is not checked, then the Inserter checks if the target inventory has at least as many items as the configured Inserter slot contains, and if there are fewer, then the requester will request the difference to try and reach the configured number.

When the "Inf" checkbox below a slot is checked, then the Inserter won't check how many of that item are contained in the target inventory, but instead will request that amount of items every time interval (roughly every 1 second) and will attempt to put them in the target inventory, until there is no more room in that inventory.

Request Inserters check for to obtain the items in the following order:

- Any Suppliers (e.g. Passive Supply Chest, Vaccuum Chest, Cobble Gen Supplier or Crafting Supplier)
- Mass Storage or Tool Box nodes (depending on the item needed)

There's two variation of the Request Inserter, and as mentioned above in almost all cases you only need the item-wise Inserter.

- Item Request Inserter: Moves 1 item at a time to fulfil the requested items.
- Stack Request Inserter: Moves up to 99 items at a time to fulfil the requested items. Note that this does not mean it will insert 99 items, but rather it can insert up to 99 - it will still only insert as many as are necessary to meet the target number set by the filter list.
]]

g.reservoir = [[
Reservoirs are portable nodes capable of storing liquids.

To use one, place it on the ground, then right-click with a full or empty bucket to put or take liquid from it. Each reservoir stores only 1 liquid type.

You can dig a reservoir and it will keep its liquid content when you place it again, which is why reservoirs are non-stackable items.

Reservoirs also connect to a Logistic Network and can thus be accessed via both the Access Point and Wireless Access Pad.

Reservoirs come in 2 variations:
- Silverin: Stores up to 32 buckets of liquid
- Obsidian: Stores up to 128 buckets of liquid
]]

g.reservoir_pump = [[
The Pump is a machine that can automatically collect liquid nodes from the world and fill up Reservoirs.

To use a Pump:

- Place it directly above the liquid level, as in screenshot above, (no air gaps or solid blocks between - it there are gaps/nodes it won't work!)
- Connect reservoirs by one of 2 methods:
- Place Reservoirs directly adjacent to it, up to 4, one on each side - no Network connection required
- Connect the Pump to a network on which Reservoirs are also connected
- Enable the machine via its GUI

The Pump will first fill out any adjacent Reservoirs before attempting to fill any Network-connected Reservoirs

The Max Level setting tells the pump when to stop pumping liquid into a network. For example, if it's set to 30 and the pump is pumping water, once there are 30 buckets of water available in the network, the pump will not add more to the network reservoirs. If the amount on the network goes below 30, the pump will once again start pumping liquid until it reaches 30. Setting the Max to 0 will make the pump continuously pump liquid into the network without caring how much is already available.

Note that the Max only applies to pumping into network reservoirs. Reservoirs that are directly connected to the pump (by being adjacent to it) will be filled to max capacity, regardless of the Max setting.

Note that Renewable liquids (like Water) are not taken by the pump, allowing you to essentially have an unlimited supply of Water in your Logistics Network.
]]

g.bucket_filler = [[
The Bucket Filler machine connects to a network and can provide the specified filled bucket On-Demand (meaning only when something on the network needs it), much like crafting suppliers provide items on-demand.

To use it:

- Place Bucket Filler so it connects to network
- Either provide empty buckets in its inventory, or ensure empty buckets are available as a supply on the network
- Select the type of filled Bucket you want the machine to provide
- You can also take filled buckets from it, or from an Access Point/Wireless Access Pad on the same network
]]

g.bucket_emptier = [[
The Bucket Emptier accepts filled buckets into its inventory and attempts to empty them into any applicable reservoirs connected to the network. The resulting Empty Buckets are put in its output slot, and become available as a passive supply of empty buckets to the connected network

Notes:

- The Bucket Emptier's input inventory (where filled buckets go) is accessible by a Requester, which can insert items into it.
- The machine has to be turned on to start processing filled buckets.
- If no reservoir can accept the liquid, it will cycle to the next slot in its input.
]]

g.crafting_supplier = [[
The Crafting Supplier is a powerful on-demand supplier that crafts items on the fly, meaning it only crafts when asked for an item it can produce.

For example: do you want to store only Steel Blocks in your network storage, but some of your machines need Steel Ingots? Put one of these machines on your network and it will automatically craft only as many Steel Ingots as your machines need!

These machines also work recursively: if you have multiple Crafting Suppliers set up on your network, they can use each other to get materials they need. For example you can set up one Crafting Supplier to craft Mese Crystals from Mese Blocks, and another to craft Mese Shards from Mese Crystals. Then only store Mese Blocks in your Network storage and if any machine needs a Mese Shard, it will be crafted for you!

These machines also interface with the Access Point and Wireless Access Pad, so you can take items that aren't stored on your network and they will be crafted by the Crafting Supplier for you!
]]

g.autocrafter = [[
The Autocrafter is simple a non-network machine that simply crafts from its input to the output. It does not interface directly with a network but can be accessed by both Network Importers and Request Inserters to feed it to/from the network.
]]

g.vaccuum_chest = [[
The Vaccuum Supply Chest acts like a regular Supply chest, providing items to the network when there's requests or storage pulls items. There are two differences:

- As the name indicates, the Vaccuum chest will collect nearby dropped items, up to a distance of 3 blocks, into its inventory, automatically making them available for the Network.
- It cannot be used by the Network to store items in it (unlike regular Supply Chests which can be configured to allow storing from the Network)

The on/off switch in the Vaccuum Chests's inventory enables whether the chest will be collecting nearby items or not.
]]

g.lava_furnace_fueler = [[
The Lava Furnace Fueler is a Network-connected machine that will attempt to re-fuel a Lava Furnace from any Reservoirs containing Lava that are connected to the network, thus allowing Automation of the Lava Furnace.

When configured with a minimum level, it will refuel the Lava Furnace it points to by 1 bucket if the Lava Furnace's level drops below the set minimum fuel level. Note that you must have Reservoirs containing Lava connected to the same network and that the Fueler will take 1 bucket at a time each time it refuels a Lava Furnace.
]]

g.cobblegen_supplier = [[
The Cobble Generator Supplier acts as a supplier that generates Cobble and stores a small buffer in its inventory, providing it as a passive supply to the Network its connected to. By default it produces 1 Cobble every 2 seconds, but can be upgraded to produce up to 4 every 2 seconds.

Why a Cobble Generator when it's possible to make one with Lava and Water and a Node Breaker?

The answer is: to reduce lag. Breaking a node causes a rather expensive update to the world, recalculating lighting and getting lava or water flowing updates to trigger. Instead, the Cobble Gen provides a far less intensive way to generate Cobble while still requiring the same materials - lava and water.
]]

g.trashcan = [[
The trashcan is a node that deletes items. You can use it stand-alone without connecting it to a network - any time you delete an item it goes into the Last Deleted Item slot, allowing you to recover the very last item you deleted.

Alternatively, you can also connect the Trashcan to a network. When connected it will delete any items that Network Importers push into the network that cannot be stored elsewhere.

If you only want to delete specific items from the network (instead of all excess items) you can configure that with the filter slot - the the Trashcan will delete only items configured in its filter list.
]]

g.wireless_transmitter = [[
The Wireless Transmitter is a node that allows a network to be extended wirelessly, by connecting to a Wireless Receiver. It isn't necessary to use a Wireless Access Pad, as that synchronizes to an Access Point instead.

Each network can only have 1 and only 1 Wireless Transmitter. In order to function, the Wireless Transmitter must be placed directly on top of the Network Controller. Once placed, it automatically starts to transmit the network, over an unlimited distance.

If a Wireless Transmitter is dug or destroyed, or if the Network Controller below it is dug or destroyed, all connected Wireless Receivers will be disconnected, and must manually be re-connected once the Transmitter is placed.

A wireless Transmitter has a limit of how many Receivers can be connected to it. This setting is configured by server, see the Server Settings guide page at the bottom of the list on the left.
]]

g.wireless_receiver = [[
The Wireless Receiver allows a network to be extended wirelessly, by connecting to a Wireless Transmitter.

To use a Receiver, first place a Transmitter in a valid position (see its page for info) to allow the network to be wirelessly transmitted.

Then place a Receiver in a valid position, such that it doesn't connect to an existing network. Then right click it and from the dropdown select the corresponding Network to connect to by name. Note that Networks can be renamed from their Network Controllers. Then press Connect - if successful, you will get a green "Connected" message.

You can then connect Optic Cables to the Receiver and they will carry the network the Receiver was connected to.

If you place a Receiver, and you cannot see your Network name (can happen after server/game restarts), first make sure the Network has a Wireless Transmitter attached to its controller. Then go and right click the Network Controller, which will make sure the network is active.
]]
