# Logistica

Logistica is an item transport, distribution and storage mod.

The core principle behind this mod is that item transportation is demand-driven: no item is moved unless it is needed somewhere.

# Machines

All machines, except the Lava Furnace can connect to a network and can perform extra useful tasks when connected to an active network

Machines that have inputs or outputs can be sneak + punched to show their i/o.

# Getting Started

## Lava Furnace
The Lava Furnace is a lava-powered furnace that can cook regular items at an increased speed, but more importantly, can make Logistica specific items. The Lava Furnace has a built-in recipe guide about the Logistica-specific items it can make.

It is crafted in the regular crafting grid like this:
```
[Clay Block ] [Obsidian Brick] [Clay Block ]
[Steel Ingot] [ Empty Bucket ] [Steel Ingot]
[Steel Ingot] [ Empty Bucket ] [Steel Ingot]
```

The most useful item it can make, and the material required for all other machines is the `Silverin Crystal`

## Silverin Crystal

A crystal made from melting Silver Sand in the Lava Furnace and then rapidly cooling it with Ice (see Lava Furance in-game recipe guide). Silverin Crystals are the backbone of all Logistica machines due to their useful photonic properties.

Silverin Crystals can be broken into 8 `Silverin Slice`s by simply putting them on the crafting grid. The slices are used as basis for many other materials, many made in the Lava Furnace, which are then used to build the rest of the machines.

# Creating a Network

## Controller
A Controller is the node required to create an active network. Exactly one controller can be conneted to a network, and removing it will disconnect all other devices connected to the network. Controllers allow you to rename the network.

## Cables
Cables are used to connect a controller to other machines, allowing the establishing of a network. Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables. TODO Cables come in TODO variants, all being identical in function, but different variants do not connect to each other, allowing parallel networks.

# Network Storage

Storage nodes don't need a network to store items, and can be used standalone.

## Mass Storage
Mass Storage is the main way stackable items can be stored in the network.

Mass Storage box provide 1024 item storage for up to 8 different item types. They are the first place a Requester will look for to fulfil item requests. Mass Storage needs to be configured with the exact items to store.

Features:
- Can be dug and keeps its inventory when placed again
- Can be upgraded to increase inventory size and pull speed
- Select Front Image: Selects a stored node to display on the front of the storage box
- Can Reserve a number of items per slot: reserved items won't be taken by other machines on the network
- Can quickly deposit items by punching it with a stack or shift-punching it for deposit all stack items
- Pull items on/off: When On this storage will actively try to pull from Passive Supplier Chests

## Tool Box
The Tool Box provides a large number of storage slots -- but it can only store tools (specifically, items that have a max stack size of 1). Tool Box is also accessed by Requesters to provide items. Tool Box cannot be dug while it contains items (unlike Mass Storage, which will keep its inventory)

## Passive Supplier Chest
A Passive Supplier Chest acts as a regular chest, and a source for items. It has a small inventory, but any item can go in it. Passive Supplier Chests won't actively push items into the network, but Demanders and Storage nodes can both take items from Suppliers when needed. Passive Supplier Chests have a toggle if they should also accept items from Network Importers

# Moving Items in/out the Network

## Request Inserter
The Request Inserter is the only way to put items in other nodes outside the network.

Request Inserters request specific items from the Network and adds them into another node's inventory. The Request Inserter tries to keep its target's inventory full of the specific items and the exact count its configured with. For example, a Request Inserter might be configured to target a Furnace's "fuel" inventory and always try to keep 2 coal in it.

Request Inserters check for to obtain the items in the following order:
1. Mass Storage or Tool Box nodes (depending if item is stackable or not)
2. Passive Supplier Chests

There's two variation of the Request Inserter:
- Item Request Inserter: Moves 1 item at a time to fulfil the requested items.
- Stack Request Inserter: Moves up to 1 stack at a time to fulfil the requested items.

## Network Importer
Network Importer are the main way to automatically take items and add them to the network.

They scan another block's inventory one slot at a time and attempt to push items from it into the network.
Network Importers prioritize where they put their items in this order:
1. Fill the current requests of any Requesters
2. Fill any mass storage that can handle this item
3. Fill any passive supply chests (if the chests are configured to accept items from the network)

There's 2 version of the Network Importer:
- Slow Network Importer: Takes up to 10 items from a slot at a time, and tries to insert it in the network.
- Fast Network Importer: Takes up to 99 items from a slot at a time, and tries to insert them in the network.

Note that how many items can be sent at one time to a Requester is still limited by the requester's speed.

# Tools

## Hyperspanner
A multipurpose engineering tool. Use on nodes for network info. Can also reverse poliarity of Photonizers (a craft-item), which is required for crafting certain machines.
