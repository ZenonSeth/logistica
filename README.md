# Logistica
# WORK IN PROGRESS - PRE-ALPHA STATE

Logistica is an item transport, distribution and storage mod.

The core principle behind this mod is that item transportation is demand-driven: no item is moved unless it is needed somewhere.

# Machines

All machines require to be connected to an active network to perform their tasks. Nodes without a network, or nodes with conflicting network connections will not do anything.

## Controller
A Controller is the node required to create an active network. Exactly one controller can be conneted to a network, and removing it will disconnect all other devices connected to the network. Controllers allow you to rename the network.

## Cables
Cables are used to connect a controller to other machines, allowing the establishing of a network. Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables. TODO Cables come in TODO variants, all being identical in function, but different variants do not connect to each other, allowing parallel networks.

## Request Inserter (technical name: demander)
A Request Inserter is a machine that inserts items into almost any other node that has an inventory. The Request Inserter takes items from the network and tries to keep its target's inventory full of the specific items and the exact count it's configured with. For example, a Request Inserter might be configured to target a Furnace's "fuel" inventory and always try to keep 2 coal in it.

There's two variation of the Request Inserter:
- Item Request Inserter: Moves 1 item at a time to fulfil the requested items.
- Stack Request Inserter: Moves up to 1 stack at a time to fulfil the requested items.

Request Inserters check network storage first to fulfil their demand, and if not, they will check any Passive Suppliers.

## Passive Supplier
A Passive Supplier acts as a source for specific items and must be configured. It takes items from other nodes' inventories (e.g. chests, furnaces) and makes them available to any demand in the network. Suppliers won't actively push items into the network, but Demanders and Storage nodes can both take items from Suppliers when needed. Note that if no items are configured in the Supplier's filter, suppliers will not provide any items at all.

Passive Suppliers are ideal for fulfiling demand when you know exactly what kind of items you want to supply to the network.

## Active Supplier
Active Supplier try to push items into the network, first checking if an item is needed by demanders and then checking storage. Active Suppliers iterate over the source's node's chosen inventory slot by slot.

There's 2 version of the Storage Injectors:
- Item Storage Injector: Takes 1 item at a time from each slot it scans.
- Stack Storage Injector: Injects one stack at a time from each slot it scans.

Active suppliers are ideal for cases where there might be many different items in an inventory. However because they check one inventory slot at a time, they may take a bit longer to fulfil demand if the source's inventory has many different types of items.

## Mass Storage
Mass Storage box provide mass-storage for items, and are the first place a Demander will look for to fulfil any demand. Mass Storage needs to be configured with the exact items to store, and can also be upgraded to store more items.
Features:
- Can be dug and keeps its inventory when placed again
- Can quickly deposit items by punching it with a stack or shift-punching it for deposit all stack items.
- Select Front Image: Selects a stored node to display on the front of the storage box
- Reserves a number of items per slot. Reserved items won't be taken by other machines on the network.
- Pull items on/off: On: This storage will also actively try to pull from Passive Suppliers

## Item Storage
The Item Storage box provides a large number of storage slots, spread over 2 pages -- but it can only store tools (specifically, items that have a max stack size of 1). Item storage is also accessed by Demanders to provide items.

# Tools

## Network Info Tool
Whe used on a Logistica node it will show which network, if any, the node is part of.