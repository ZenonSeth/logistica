# Logistica

Logistica is a item transport, distribution and storage mod.

The core principle behind this mod is that item transportation is demand-driven: no item is moved unless it is requested somewhere.

# Nodes

All nodes require to be connected to an active network to perform their tasks. Nodes without a network, or nodes with conflicting network connections will not do anything.

## Controller
A Controller is a node required to create an active network. Exactly one controller can be conneted to a network, and removing it will disconnect all other devices connected to the network.

## Cables
Cables are simple nodes that connect a controller to other nodes, allowing the establishing of a network. Placing a cable that bridges two different active networks will burn that cable. Burned cables can simply be picked up, and return normal cables. TODO Cables come in TODO variants, all being identical in function, but different variants do not connect to each other, allowing parallel networks.

## Demander
A Demander is a node that targets any other node with an inventory, and can be configured to request items from its network to keep the target's inventory full of a specific number of specific items.

## Supplier
A Supplier is a node that takes items from another node's inventory, configuratble to only inject certain items, and tries to fulfil any supply for that item in its network. Suppliers have a tick rate and each tick they pick one inventory slot of the target's invenotry and check if there's demand anywhere on the network for that type of item. On the following tick, the supplier will move onto the next slot of the target's inventory and check that.

There are two variants:

### Item Supplier
This supplier takes only 1 item from each inventory slot it checks and fulfils one single demand with it.

### Stack Supplier
This supplier will take the whole stack, or as many items as are needed out of a stack, and try to fulfil any demand on its network with those items.

## Storage

Storage nodes provide mass-storage for items. They also act as suppliers for any demand. Storage nodes are more efficient at fulfilling demand over suppliers because they do not need to check one inventory slot at a time, but instead consider their entire inventory.