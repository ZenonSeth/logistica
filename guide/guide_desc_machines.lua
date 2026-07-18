local S = logistica.TRANSLATOR

local g = logistica.Guide.Desc

g.network_controller = S([[
A Controller is the node required to create an active network. Exactly one controller can be connected to a network, and removing it will disconnect all other devices connected to the network.

Controllers allow you to rename the network, but this is for visual identification only, and naming two networks with the same name will not connect them together.
]])

g.access_point = S([[
The Access Point provides easy access to all Storage devices connected to the Network.

It can both take and insert items into the network's storage. It provides a Crafting Grid built into it for convenience.

You can also access an Access Point and all its features remotely using a Wireless Access Pad synced to the Access Point.

Searching by text
------------------------------
You can enter a search term to show items that term.

A special search can be done by adding the groups: prefix at the start. For example groups:flower will match only items that have flower group set, thus it will display all flowers added by any mod.

Filtering
------------------------------
You can filter items by:

All items, Blocks only, Craft-items only, Tools only, Lights only

Sorting
------------------------------
Items can also sorted by

- Name: alphabetically sorted by the item's localized description to sort
- Mod: alphabetically sorted by the item's technical name that is prefixed with the mod
- Count: sorts by total item count, with largest first.
- Wear: Sorts by item wear, with most uses remaining first (best used when filtering for Tools only)

Use Metadata button
------------------------------
Some items, usually tools, have other information stored in them, like wear, descriptions or more complex metadata.

If "Use Metadata" is ON, the Access Point will display these items individually. If it's OFF, the Access Point will group items with the same name, but different metadata into 1 stack. When taking such an item when Use Metadata is OFF, you will still receive an actual item with the correct wear and metadata, but it will be picked at random from the network.

Liquid Storage
------------------------------
Below the Metadata button is a small section where the Access Point will show any Reservoirs connected to the network.

You can use the two arrows to cycle through all liquids (if there are any).
To deposit a liquid, just put a full bucket into the slot below the liquid image. It does not matter which liquid is selected for this, the Access Point will attempt to deposit it into the fullest applicable Reservoir, or assign the next smallest empty reservoir, if one is available.
To withdraw a liquid, first select which liquid you want, then put an Empty Bucket into the slot below. The liquid will be taken from the least-full Reservoir holding that liquid type on the Network.

Taking items from the Network
------------------------------
The Access Point shows a snapshot of available items, or items supplied by crafting suppliers. When you try to take an item, the Access Point makes a real request to the network. If the items are no longer available, you won't receive anything. In most cases the Access Point will try to show an error message informing what went wrong.
]])

g.access_point_storage = S([[
The Storage Management tab on the Access Point lets you allocate and de-allocate slots on Mass Storage units across the entire network without having to visit each one individually.

Each Mass Storage on the network is shown with its name, position, and per-slot capacity. The 8 filter slots are displayed for each unit, with the current stored count shown below each assigned slot.

To allocate a slot, drag any item from your inventory into an empty filter slot. The item is used only as a type identifier - it is not consumed.

To de-allocate a slot, take the item out of a filter slot. This only works if that slot currently holds 0 stored items.

Use the Prev and Next buttons at the bottom to page through all Mass Storages on the network.
]])

g.access_point_crafting = S([[
The Easy Crafting tab on the Access Point lets you search for any craftable item and craft it directly from your network's stored items.

To unlock this tab, insert an Access Point Crafting Upgrade (for basic crafting) or a Recursive Crafting Upgrade (for basic crafting and recursive crafting) into the upgrade slot in the top-right corner of the tab.

Searching
------------------------------
Type at least 2 characters into the search field and press Search. Results match on item name parts and description words. For example, "logis" finds all Logistica items, and "no br" finds Node Breaker.

Click a result on the left to view its recipe on the right.

Recipe view
------------------------------
The 3x3 recipe grid shows each ingredient. Each slot is highlighted:

- Blue: enough of this ingredient is available in the network (or player inventory if enabled)
- Red: not enough available

The "Can craft: N" label shows how many times the recipe can currently be completed.

Crafting
------------------------------
Use the [Craft] button to craft one batch, or [x10] to craft ten at once.

If "Also use player inventory" is checked, items are first drawn from the network and the remainder taken from your inventory.

Recursive Crafting
------------------------------
The Recursive Crafting Upgrade works the same as the regular Access Point Crafting Upgrade, but also enables recursive (deep) crafting.

With recursive crafting enabled, you can craft an item even when its direct ingredients are not all in storage - as long as the ingredients needed to make those ingredients are available. The system plans the full crafting chain automatically, crafting any missing sub-components from the network first, then assembling the final item.

Handles normal crafting grid recipes only. It is most useful when crafting complex machines whose ingredients themselves have multi-step crafting recipes.

The Recursive Crafting Upgrade can replace the regular Access Point Crafting Upgrade; you do not need both.

Synchronizing the Recursive Upgrade
------------------------------
The Recursive Crafting Upgrade can be Synchronized using the Wireless Upgrader. A Synchronized upgrade allows the Easy Crafting tab to be used remotely through a Wireless Access Pad. Without synchronization, the Easy Crafting tab is only available when opening the Access Point directly.

Synchronizing requires two separate upgrades in the Wireless Upgrader - match the waves once to partially synchronize, and a second time to fully synchronize the upgrade.

History navigation
------------------------------
The [ < ] and [ > ] buttons navigate back and forward through recipes you have viewed, similar to browser history. Clicking an ingredient in the recipe grid also navigates to that ingredient's own recipe.

Wireless Access Pad
------------------------------
When accessing the Easy Crafting tab through a Wireless Access Pad, the upgrade slot is hidden. The upgrade must be inserted by opening the Access Point directly.

The Easy Crafting tab is only available via Wireless Access Pad if the Access Point has a Synchronized Recursive Crafting Upgrade installed.

Recipe limitations
------------------------------
Recipes that use group ingredients (e.g. "group:wood") are supported, but only if the recipe uses at most one type of group. Recipes that require two or more different group ingredients are not available in Easy Crafting due to CPU and memory limitations.
]])

g.optic_cable = S([[
Regular Cables
------------------------------
Cables are used to connect a controller to other machines, allowing the establishing of a network.

Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables.

Note that Cables are the only way to extend a network's reach - meaning, machines will not carry the network connection through them. If you connect a network cable to one side of a machine, and then place a 2nd cable on the other side of the machine, the 2nd cable will not carry the network connection.

Toggleable Cables
------------------------------
The Toggleable Cable works exactly like a regular cable, but can be right-clicked (aka used) to disconnect it from all other surrounding cables or machines. This allows you to make parts of your network easy to disconnect when you don't want to use them (For example, a disconnecting an auto-furnace setup when you don't need it anymore)

Embedded Cables
------------------------------
The Embedded Cable is a full block that acts like a regular Optic Cable, allowing cables to be run through walls without leaving visible gaps.

Insulated Cables
------------------------------
Insulated Cables are directional cables that only carry the network connection along specific faces. All other faces are blocked, even if another cable or machine is touching them. This lets you run cables past machines or junctions without accidentally connecting them.

The Insulated Optic Cable (straight) connects front-to-back only. Place it so its front and back faces align with the cable run you want.

The Insulated Optic Cable (L-Shape) connects the front face to the right face, allowing a 90-degree turn while still insulating the remaining four faces.

Both insulated cable types can be cycled from a regular Optic Cable by crafting them alone (shapeless). Crafting: Optic Cable -> Straight -> L-Shape -> back to Optic Cable.
]])

g.wireless_upgrader = S([[
The Wireless Upgrader is a machine used to upgrade the Wireless Access Pad's range.

To upgrade a Wireless Access Pad:

1. Craft the Wireless Upgrader
2. In the Wireless Upgrader put the Wireless Access Pad at the bottom slot, and 1 Wireless crystal in each top slot
3. You'll see two waves appear, one blue, one orange. The Orange wave is controlled by the wave icon buttons around the crystals. Note: the wave icons are clickable buttons, not just pictures.
4. Use the wave buttons around each Crystal to make the orange wave match the blue wave.
5. When they match, the wave turns Green and an Upgrade button appears.
6. Press the Upgrade button to increase your Wireless Access Pad's range.

The Wireless Upgrader can also synchronize a Recursive Crafting Upgrade. Place the upgrade in the bottom slot instead of a Wireless Access Pad, match the waves twice to fully synchronize it. A Synchronized upgrade allows Easy Crafting to be used remotely via a Wireless Access Pad.

The Wireless Upgrader also has a "Hard Mode" toggleable via settings - see the "Server Settings" page on the left for info.
]])

g.mass_storage = S([[
Mass Storage nodes provide 1024 item storage for up to 8 different item types by default. This capacity can be upgraded with 4 upgrade slots and 2 different upgrades. Mass Storage needs to be configured with the exact items to store.

You can collectively access all Mass Storage on a particular network from an Access Point/Wireless Access Pad.

- Can be dug and keeps its inventory when placed again, allowing easy moving of stored items
- Can be upgraded to increase inventory size, up to a maximum of 65,535 per slot
- Select Front Image: selects a stored item to display on the front of the storage node
- Can quickly deposit items by punching it with a stack, or sneak-punching to deposit all matching stacks from your inventory
- A Deposit button appears when at least one filter slot is configured, allowing you to deposit all matching items from your inventory into the storage

Each storage slot has a Configure button (the small button below each slot). Pressing it opens the slot config:

- Reserve: items the network will not take from this slot. Useful to keep a buffer for personal use.
- Demand: if the stored count is below this number, the storage will actively pull from Supplier machines until it is reached. Set to 0 to disable pulling for that slot.
- Include Crafting Suppliers: if checked, the Demand pull will also request items from Crafting Suppliers for this slot.

You can swap upgrades by pressing the Swap button under each upgrade slot.
Note that there is a multiplier upgrade, but only one can be inserted into a machine, making the maximum stack size 65,535 per slot.

]])

g.tool_chest = S([[
The Tool Chest provides a large number of storage slots -- but it can only store tools (specifically, items that have a max stack size of 1). The Tool Chest is also accessed by Requesters to provide items. Tool Chest cannot be dug while it contains items (unlike Mass Storage, which will keep its inventory)

You can also choose to sort the stored tools by Name, Mod or Wear.
]])

g.passive_supplier = S([[
A Passive Supplier Chest acts as a regular chest and a source of items for network requests.

Any item can be placed in it. Passive Supplier Chests won't actively push items into the network, but Demanders and Mass Storage nodes can pull items from them when needed.

Two toggles control what may store items into the chest:

- Allow Storing from Machines: when enabled, Network Importers and other automated machines can deposit items into this chest.
- Allow Storing from Access Point: when enabled, items inserted via an Access Point are stored here if there is no other suitable storage.

Both are enabled by default. Disabling both effectively makes the chest read-only from the network's point of view, supplying items out but accepting nothing in automatically.

A filter list of 8 slots controls which items are allowed to be stored into the chest. If the filter is empty, any item is accepted. If one or more items are placed in the filter, only those items can be stored - both by machines and by the Access Point.

When the filter is not empty, a Deposit button appears. Clicking it will move all matching items from your inventory into the chest.
]])

g.network_importer = S([[
Network Importer are used to automatically take items from other nodes (e.g. furnaces) and add them to the network.

To get a Network Importer working you must:

- Place it facing a node that has an inventory it can access. Sneak + punch an importer to see its input position.
- Select which inventory of the target node to take from - some nodes have multiple inventories, and one must be selected.
- Make sure you press the Enable button to enable its functionality.
- Optionally, you can configure the importer to only pull specific items by placing them in the Filter List. If the list is empty, the importer will indiscriminately attempt to pull any item, slot by slot, from its input node.
- Optionally, select which machine types the importer will try to insert items into.

Network importers scan 1 slot, and rotate which slot they take from each time they tick.

Network Importers prioritize where they put their items in this order, assuming the type of machine to import into is enabled in the Importer's interface:

- Fill the requests of any Requesters on the network
- Fill any Mass or Item Storages (depending on whether item is stackable or not) that can handle this item
- Fill any passive supply chests (if the chests are configured to accept items from the network)
- Trash the item if there's any Trashcans connected that accept this kind of item. (see Trashcan)

Using the Importer's GUI, you can enable or disable each of the 4 types of machines to import items into, and any disabled won't be added into. If no machine type is enabled to import into, then the Importer won't add any items at all. Note that even when a machine type is enabled, the Importer obeys the configuration of those machines, e.g. if a Passive Supply Chest is marked as "Don't allow storing from network" then the importer won't add into it.

There's 2 version of the Network Importer:

- Slow Network Importer: Takes up to 10 items from a slot at a time, and tries to insert it in the network.
- Fast Network Importer: Takes up to 99 items from a slot at a time, and tries to insert them in the network.

Note that how many items can be sent at one time to a Requester is still limited by the Requester itself (meaning an Item Requester will only receive 1 item, while a Stack Requester will receive up to 99). However when sending to Mass Storage or Passive Supply chests, the full stack the importer is capable of taking will be sent.
]])

g.request_inserter = S([[
The Request Inserter is used to put items in other nodes outside the network.

Note that while there are item-wise and stack-wise Inserters, in ALMOST ALL cases you only need the item-wise Inserter.

To use an Inserter, you must:

- Place it facing a node that has an inventory it can target. Sneak + punching an inserter will show its output location.
- Pick an inventory to place items into. Some nodes have multiple input inventories (e.g. a furnace).
- Place items in the 8 filter slots to set which item types to request. Each slot holds 1 item to identify the type.
- Set the "Request up to" amount below each filter slot. This is the target count to keep in the destination inventory. Setting it to 0 disables that slot.
- Make sure you press the Enable button to enable operation.

The Inserter checks how many of the configured item are already in the target inventory. If fewer than the "Request up to" amount are present, it requests the difference from the network and inserts them.

For example, configure a slot with Coal and amount 4, pointing at a furnace's fuel inventory: the Inserter will keep requesting Coal until there are 4 in the furnace, then stop until some are consumed.

Request Inserters obtain items in the following order:

- Any Suppliers (e.g. Passive Supply Chest, Vacuum Chest, Cobble Gen Supplier or Crafting Supplier)
- Mass Storage or Tool Box nodes (depending on the item needed)

There are two variations of the Request Inserter, and in almost all cases you only need the item-wise Inserter.

- Item Request Inserter: Moves 1 item at a time to fulfil the requested amounts.
- Stack Request Inserter: Moves up to 99 items at a time to fulfil the requested amounts.
]])

g.reservoir = S([[
Reservoirs are portable nodes capable of storing liquids.

To use one, place it on the ground, then right-click with a full or empty bucket to put or take liquid from it. Each reservoir stores only 1 liquid type.

You can dig a reservoir and it will keep its liquid content when you place it again, which is why reservoirs are non-stackable items.

Reservoirs also connect to a Logistic Network and can thus be accessed via both the Access Point and Wireless Access Pad.

Reservoirs come in 2 variations:
- Silverin: Stores up to 32 buckets of liquid
- Obsidian: Stores up to 128 buckets of liquid
]])

g.reservoir_pump = S([[
The Pump is a machine that can automatically collect liquid nodes from the world and fill up Reservoirs.

To use a Pump:

- Place it directly above the liquid level (no air gaps or solid blocks between - if there are gaps/nodes it won't work!)
- Connect reservoirs by one of 2 methods:
- Place Reservoirs directly adjacent to it, up to 4, one on each side - no Network connection required
- Connect the Pump to a network on which Reservoirs are also connected
- Enable the machine via its GUI

The Pump will first fill out any adjacent Reservoirs before attempting to fill any Network-connected Reservoirs

The Max Level setting tells the pump when to stop pumping liquid into a network. For example, if it's set to 30 and the pump is pumping water, once there are 30 buckets of water available in the network, the pump will not add more to the network reservoirs. If the amount on the network goes below 30, the pump will once again start pumping liquid until it reaches 30. Setting the Max to 0 will make the pump continuously pump liquid into the network without caring how much is already available.

Note that the Max only applies to pumping into network reservoirs. Reservoirs that are directly connected to the pump (by being adjacent to it) will be filled to max capacity, regardless of the Max setting.

Note that Renewable liquids (like Water) are not taken by the pump, allowing you to essentially have an unlimited supply of Water in your Logistics Network.
]])

g.bucket_filler = S([[
The Bucket Filler machine connects to a network and can provide the specified filled bucket On-Demand (meaning only when something on the network needs it), much like crafting suppliers provide items on-demand.

To use it:

- Place Bucket Filler so it connects to network
- Either provide empty buckets in its inventory, or ensure empty buckets are available as a supply on the network
- Select the type of filled Bucket you want the machine to provide
- You can also take filled buckets from it, or from an Access Point/Wireless Access Pad on the same network
]])

g.bucket_emptier = S([[
The Bucket Emptier accepts filled buckets into its inventory and attempts to empty them into any applicable reservoirs connected to the network. The resulting Empty Buckets are put in its output slot, and become available as a passive supply of empty buckets to the connected network

Notes:

- The Bucket Emptier's input inventory (where filled buckets go) is accessible by a Requester, which can insert items into it.
- The machine has to be turned on to start processing filled buckets.
- If no reservoir can accept the liquid, it will cycle to the next slot in its input.
]])

g.crafting_supplier = S([[
The Crafting Supplier is a powerful on-demand supplier that crafts items on the fly, meaning it only crafts when asked for an item it can produce.

For example: do you want to store only Steel Blocks in your network storage, but some of your machines need Steel Ingots? Put one of these machines on your network and it will automatically craft only as many Steel Ingots as your machines need!

These machines also work recursively: if you have multiple Crafting Suppliers set up on your network, they can use each other to get materials they need. For example you can set up one Crafting Supplier to craft Mese Crystals from Mese Blocks, and another to craft Mese Shards from Mese Crystals. Then only store Mese Blocks in your Network storage and if any machine needs a Mese Shard, it will be crafted for you!

These machines also interface with the Access Point and Wireless Access Pad, so you can take items that aren't stored on your network and they will be crafted by the Crafting Supplier for you!
]])

g.autocrafter = S([[
The Autocrafter is simple a non-network machine that simply crafts from its input to the output. It does not interface directly with a network but can be accessed by both Network Importers and Request Inserters to feed it to/from the network.
]])

g.farming_supplier = S([[
The Farming Supplier automatically harvests fully-grown crops in an area around it and supplies the collected items to the network, acting like a passive supply chest that fills itself.

It scans for nodes in the "plant" group and only harvests those that are at their final growth stage. After harvesting, it replants each crop at stage 1. All drops from the harvested crop (including seeds) are collected into the node's inventory.

Configuration options:
- Farm Range: how many blocks in each horizontal direction to scan (1-3).
- Height Mode: controls which vertical layer(s) to scan.
  - Farm At Level: scans only at the same height as the farming node.
  - Farm Below: scans 1-2 nodes below the farming node.

The Enable button turns harvesting on or off. When enabled, the node runs on a fixed timer. Harvesting pauses if the inventory is full.

The upgrade slot accepts a Sprinkler Upgrade. See the Sprinkler Upgrade page for details.

Requires Lava in the Network to function. Uses roughly 1/1000th of a bucket of lava per crop harvested, and 1/1000th of the lava reserve as fuel for a watering cycle when the Sprinkler Upgrade is active (the sprinkler also consumes 1 bucket of water from the network as the water it sprays).
]])

g.sprinkler_upgrade = S([[
The Sprinkler Upgrade is inserted into the upgrade slot of a Farming Supplier. When installed, each time the Farming Supplier runs it will attempt to consume 1 bucket of water from any Reservoir connected to the same network.

If water is available, each plant in the scan area has a small chance to be advanced one growth stage before the harvest check. This means crops can go from seed to fully grown faster, and crops that were not yet mature may become harvestable in the same cycle they were watered.

If no water is available in the network, the grow pass is skipped entirely for that cycle and harvesting proceeds as normal.

Note: the Sprinkler Upgrade consumes exactly 1 bucket of water per machine cycle, regardless of how many plants are in range.
]])

g.woodcutter = S([[
The Wood Supplier automatically harvests the tree directly in front of it and supplies all collected wood (and optionally leaves) to the network, acting like a passive supply chest that fills itself.

Face the machine toward the base trunk of the tree you want to harvest. Sneak and punch the machine to see a highlight on the target position.

When enabled, the machine will scan upward from the target trunk, collecting all connected trunk nodes of the same type. It works top-down, cutting one node at a time with a short delay between each cut. This prevents the tree from dropping as fallen nodes, and gives time for the inventory to be drained by the network between cuts.

Limits: if the tree is too tall or has too many connected nodes in total, the operation is cancelled and the status field in the inventory shows the reason. The machine will automatically retry on the next cycle.

The inventory is output-only. Items are supplied passively to the network the same way a Passive Supply Chest would. If the inventory fills up mid-cut, cutting stops and the machine shows an "Inventory full" status.

The upgrade slot accepts a Leafcutter Upgrade. When installed, the machine will also harvest the leaves of the tree. It detects the leaf type by checking above the topmost trunk nodes, picks the most common leaf type found, and flood-fills all connected leaves of that type. Leaves are cut before the trunk, also top-down.

Requires Lava in the Network to function. Uses roughly 1/1000th of a bucket of lava per trunk node cut, and 1/1000th per every 10 leaf nodes cut.
]])

g.leaves_upgrade = S([[
The Leafcutter Upgrade is inserted into the upgrade slot of a Wood Supplier. When installed, each time the Wood Supplier harvests a tree it will also harvest the tree's leaves.

The upgrade detects the leaf type by checking the nodes directly above the highest points of the trunk. It picks the most common leaf type found and collects all connected leaf nodes of that type. Leaves are cut top-down before the trunk is cut.

If no leaves are detected above the trunk, the cutting proceeds normally with only the trunk being harvested.
]])

g.vaccuum_chest = S([[
The Vacuum Supply Chest acts like a regular Supply chest, providing items to the network when there's requests or storage pulls items. There are two differences:

- As the name indicates, the Vacuum chest will collect nearby dropped items, at a configurable distance of up to 3 blocks, into its inventory, automatically making them available for the Network.
- It cannot be used by the Network to store items in it (unlike regular Supply Chests which can be configured to allow storing from the Network)

The on/off switch in the Vacuum Chests's inventory enables whether the chest will be collecting nearby items or not.

The Vacuum Chest also has a filter row. If any filter slots are filled, the chest will only pick up items matching those filters. If all filter slots are empty, the chest will pick up all nearby items.
]])

g.rock_melter = S([[
The Rock Melter is a network-connected machine that melts stone-type blocks into Lava, storing up to 16 buckets in its internal tank. The stored Lava is available to the network as a read-only Reservoir - any machine on the same network can draw Lava from it (for example, a Lava Furnace Fueler). Unlike regular Reservoirs, the network cannot store Lava into the Rock Melter; it only provides Lava outward.

Place any full-block stone-type item (such as Cobblestone or Stone) in the Input slot and a valid fuel in the Fuel slot. The machine burns through fuel while slowly melting the stone. Lava Buckets can also be used as fuel.

To collect Lava manually, place an Empty Bucket in the slot below the tank - it will be filled automatically once enough Lava is available.

The Fuel and Input slots can be automated with a Request Inserter, and the Output slot can be automated with a Network Importer.

Requires a Hardened Silverin Block to craft, which is produced in the Lava Furnace.
]])

g.lava_furnace_fueler = S([[
The Lava Furnace Fueler is a Network-connected machine that will attempt to re-fuel a Lava Furnace from any Reservoirs containing Lava that are connected to the network, thus allowing Automation of the Lava Furnace.

When configured with a minimum level, it will refuel the Lava Furnace it points to by 1 bucket if the Lava Furnace's level drops below the set minimum fuel level. Note that you must have Reservoirs containing Lava connected to the same network and that the Fueler will take 1 bucket at a time each time it refuels a Lava Furnace.
]])

g.cobblegen_supplier = S([[
The Cobble Generator Supplier acts as a supplier that generates Cobble and stores a small buffer in its inventory, providing it as a passive supply to the Network its connected to. By default it produces 1 Cobble every 2 seconds, but can be upgraded to produce up to 4 every 2 seconds.

Why a Cobble Generator when it's possible to make one with Lava and Water and a Node Breaker?

The answer is: to reduce lag. Breaking a node causes a rather expensive update to the world, recalculating lighting and getting lava or water flowing updates to trigger. Instead, the Cobble Gen provides a far less intensive way to generate Cobble while still requiring the same materials - lava and water.
]])

g.trashcan = S([[
The trashcan is a node that deletes items. You can use it stand-alone without connecting it to a network - any time you delete an item it goes into the Last Deleted Item slot, allowing you to recover the very last item you deleted.

Alternatively, you can also connect the Trashcan to a network. When connected it will delete any items that Network Importers push into the network that cannot be stored elsewhere.

If you only want to delete specific items from the network (instead of all excess items) you can configure that with the filter slot - the the Trashcan will delete only items configured in its filter list.
]])

g.disassembler = S([[
The Logistica Machine Disassembler breaks down Logistica machines back into their base ingredients. It does not connect to a network, but its input and output slots are accessible by Network Importers and Request Inserters.

To use it, place a Logistica machine into the input slot. The preview grid on the right shows the ingredients you will receive. Press Disassemble to recover them into the output slots below.

A few things to keep in mind:
- Only Logistica machines can be placed in the input slot. Other items are rejected.
- If the output slots are full, the Disassemble button does nothing - clear some space first.
- Ingredients are calculated per output item: if a recipe produces 3 of something, disassembling 1 of it returns one third of the ingredients (rounded down).
- Items with multiple crafting recipes will always use the base recipe when calculating what to return.
- Can be automated: a Request Inserter can feed machines into the input slot, and a Network Importer can collect the recovered ingredients.
]])

g.item_monitor = S([[
The Item Monitor is a network-connected machine that records item counts over time and displays them as a graph.

Up to 8 items can be tracked simultaneously, each shown in a distinct color. Drag any item into a filter slot to start tracking it - the item is used only as a type identifier and is not consumed. Removing an item from a slot clears that slot's recorded history.

The recording interval can be set to 5 seconds, 1 minute, 10 minutes, or 1 hour using the button in the formspec. Up to 60 data points are kept per item; older readings are discarded as new ones are recorded.

The graph automatically scales its Y axis to the range of the recorded data, so small fluctuations are visible even when counts are large. The current min and max values are shown on the left edge of the graph.

Use the Refresh button to update the graph display with the latest data, or Clear History to wipe all recorded data and start fresh.
]])

g.wireless_transmitter = S([[
The Wireless Transmitter is a node that allows a network to be extended wirelessly, by connecting to a Wireless Receiver. It isn't necessary to use a Wireless Access Pad, as that synchronizes to an Access Point instead.

Each network can only have 1 and only 1 Wireless Transmitter. In order to function, the Wireless Transmitter must be placed directly on top of the Network Controller. Once placed, it automatically starts to transmit the network, over an unlimited distance.

If a Wireless Transmitter is dug or destroyed, or if the Network Controller below it is dug or destroyed, all connected Wireless Receivers will be disconnected, and must manually be re-connected once the Transmitter is placed.

A wireless Transmitter has a limit of how many Receivers can be connected to it. This setting is configured by server, see the Server Settings guide page at the bottom of the list on the left.
]])

g.wireless_receiver = S([[
The Wireless Receiver allows a network to be extended wirelessly, by connecting to a Wireless Transmitter.

To use a Receiver, first place a Transmitter in a valid position (see its page for info) to allow the network to be wirelessly transmitted.

Then place a Receiver in a valid position, such that it doesn't connect to an existing network. Then right click it and from the dropdown select the corresponding Network to connect to by name. Note that Networks can be renamed from their Network Controllers. Then press Connect - if successful, you will get a green "Connected" message.

You can then connect Optic Cables to the Receiver and they will carry the network the Receiver was connected to.

If you place a Receiver, and you cannot see your Network name (can happen after server/game restarts), first make sure the Network has a Wireless Transmitter attached to its controller. Then go and right click the Network Controller, which will make sure the network is active.
]])
