from direction import valid_directions

class Player:
    """Describe, move, and store the Player"""
    def __init__(self):
        self.inventory = []

        self.posX = 0
        self.posY = 0
        self.posZ = 0

    def Move(self, direction):
        """Move in the specified direction.
        
        This takes a human-readable string value, checked against the
        valid_directions property of the direction class. 
        """
        for dir in valid_directions:
            if (dir['name'] == direction):
                self.posX += dir['delta'][0]
                self.posY += dir['delta'][1]
                self.posZ += dir['delta'][2]

    def GetCurrentRoom(self):
        """Returns an object reference to the player's current room"""
        # TODO: Change when World class is implemented
        return (self.posX, self.posY, self.posZ)

    def GetInventory(self):
        """Returns the list of inventory items."""
        return self.inventory

    def GetInventoryItem(self, item):
        """Returns an individual Item object from the player's inventory"""
        if item in self.inventory:
            return item
        else:
            return None

    def Pickup(self, item):
        """Pickup an Item from the world."""
        # TODO: Add check to ensure that this is a real item
        self.inventory.append(item)
        return "You picked up " + item.GetName() + "."

    def Drop(self, item):
        """Drop an item from the inventory"""
        # TODU: Drop item into player's current room
        if (item in self.inventory):
            self.inventory.remove(item)
            return "You've dropped " + item.GetName() + "."
