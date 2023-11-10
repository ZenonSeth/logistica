# Logistica
# WORK IN PROGRESS - PRE-ALPHA STATE

Logistica is an item transport, distribution and storage mod.

The core principle behind this mod is that item transportation is demand-driven: no item is moved unless it is needed somewhere.

# Machines

Almost all machines can connect to a network, unless otherwise stated, and can perform useful tasks when connected to an active network.

Machines that have inputs or outputs can be sneak + punched to show their i/o.

## Controller
A Controller is the node required to create an active network. Exactly one controller can be conneted to a network, and removing it will disconnect all other devices connected to the network. Controllers allow you to rename the network.

## Cables
Cables are used to connect a controller to other machines, allowing the establishing of a network. Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables. TODO Cables come in TODO variants, all being identical in function, but different variants do not connect to each other, allowing parallel networks.

## Request Inserter
A Request Inserter is a machine that Requests specific items from the Network and tries to insert them into another inventory. The Request Inserter tries to keep its target's inventory full of the specific items and the exact count its configured with. For example, a Request Inserter might be configured to target a Furnace's "fuel" inventory and always try to keep 2 coal in it.

There's two variation of the Request Inserter:
- Item Request Inserter: Moves 1 item at a time to fulfil the requested items.
- Stack Request Inserter: Moves up to 1 stack at a time to fulfil the requested items.

Request Inserters check network storage first to fulfil their demand, and if not, they will check any Passive Suppliers.

## Passive Supplier Chest
A Passive Supplier Chest acts as a source for specific items and must be configured. It makes any items added to its inventory available to any demand in the network. Passive Supplier Chests won't actively push items into the network, but Demanders and Storage nodes can both take items from Suppliers when needed. Since many machines can quickly access the Passive Supplier Chest's inventory, they are able to fulfil requests much quicker than Network Inserters.

Passive Supplier Chests, when filled by Item Movers, are usually better at supplying a network when the source inventory has many different types of items that need to be supplied (e.g. the output of an automted sieve)

## Network Importer
Network Importer scan another block's inventory one slot at a time and attempt to push items from it into the network. Network Importer thus can directly fulfil requests and add to storage. However, they do not act as suppliers that other requesters can check, so the rate at which they add items to the network is limited by the Importer itself. However, Network Importer can directly take items from another node's inventory, unlike Passive Supplier Chests.

Network Importer are usually better used for taking items from small inventories (e.g. the default Furnace's output inventory).

There's 2 version of the Network Importer:
- Item Network Importer: Takes 1 item from a slot at a time, and tries to insert it in the network.
- Stack Network Importer: Takes up to 99 items from a slot at a time, and tries to insert them in the network.

When finding places to add items to, Network Importer prioritize Requesters first, then Storage. Stack Importers can place exact number of requsted items in a Requester, and will then continue and attempt to insert any leftover of the stack into other Requesters and/or Storage nodes.

## Mass Storage
Mass Storage box provide mass-storage for items, and are the first place a Requester will look for to fulfil any requests. Mass Storage needs to be configured with the exact items to store, and can also be upgraded to store more items.
Features:
- Can be dug and keeps its inventory when placed again
- Can quickly deposit items by punching it with a stack or shift-punching it for deposit all stack items.
- Select Front Image: Selects a stored node to display on the front of the storage box
- Reserves a number of items per slot. Reserved items won't be taken by other machines on the network.
- Pull items on/off: On: This storage will also actively try to pull from Passive Suppliers

## Tool Box
The Tool Box provides a large number of storage slots -- but it can only store tools (specifically, items that have a max stack size of 1). Tool Box is also accessed by Requesters to provide items. Tool Box cannot be dug while it contains items (unlike Mass Storage, which will keep its inventory)

## Item Mover
The Item Mover is a simple node that moves items one inventory to inventory. It does not require a network, and in fact it cannot connect to a network.

The Item Mover's main use is to automatically add items into Passive Supplier Chests and Active Supplier Chests. It can be configured to only move certain types of items. It scans its source node's inventory one slot at a time, rotating which slot it takes from each time.

There's two types of Item Movers:
- Individual Item Mover: Moves 1 item at a time.
- Stack Item Mover: Moves up to 99 items at a time.

# Tools

## Network Info Tool
Whe used on a Logistica node it will show which network, if any, the node is part of.
