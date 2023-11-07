# Logistica
# WORK IN PROGRESS - PRE-ALPHA STATE

Logistica is a item transport, distribution and storage mod.

The core principle behind this mod is that item transportation is demand-driven: no item is moved unless it is requested somewhere.

# Machines

All machines require to be connected to an active network to perform their tasks. Nodes without a network, or nodes with conflicting network connections will not do anything.

## Controller
A Controller is the node required to create an active network. Exactly one controller can be conneted to a network, and removing it will disconnect all other devices connected to the network. Controllers allow you to rename the network.

## Cables
Cables are used to connect a controller to other machines, allowing the establishing of a network. Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables. TODO Cables come in TODO variants, all being identical in function, but different variants do not connect to each other, allowing parallel networks.

## Demander
A Demander is a machine that inserts items into almost any other node that has an inventory. The Demander takes items from the network and tries to keep its target's inventory full of the specific items and the exact count it's configured with. For example, a demander might be configured to target a Furnace's "fuel" inventory and always try to keep 2 coal in it.

There's two variation of the Demander:
- Basic Demander: Moves 1 item at a time to fulfil the requested items.
- Stack Demander: Moves up to 1 stack at a time to fulfil the requested items.

Demanders check network storage first to fulfil their demand, and if not, they will check any suppliers.

## Supplier
A Supplier acts as a source for specific items that must be configured. It takes items from other nodes' inventories (e.g. chests, furnaces) and makes them available to any demand in the network. Suppliers won't actively push items into the network, but Demanders and Storage nodes can both take items from Suppliers when needed.

## Storage Injectors
Storage Injectors take items from other nodes' inventories and make them available only to Mass Storage on the network. Just as with Suppliers, they won't push items into the network, but the difference is that Storage Injectors don't need to be configured for any items and instead will act as a source of items for any Mass Storage boxes that is pulling in items. Storage Injectors do not interact with Demanders

## Mass Storage
Mass Storage box provide mass-storage for items, and are the first place a Demander will look for to fulfil any demand. Mass Storage needs to be configured with the exact items to store, and can also be upgraded to store more items. Mass Storage can also be set to actively pull items in from Suppliers and Storage Injectors.

Mass Storage boxes also keep their inventory when they are dug, allowing them to be easily moved. 

You can punch Mass Storage boxes with a stack of items and it will be deposited if the mass storage can store that type of item, or sneak + punch it to deposit all items in your inventory to it.

## Item Storage
The Item Storage box provides a large number of storage slots, spread over 2 pages -- but it can only store tools (specifically, items that have a max stack size of 1). Item storage is also accessed by Demanders to provide items.

# Tools

## Network Info Tool
Whe used on a Logistica node it will show which network, if any, the node is part of.