class Player:
    " Describe, move, and store the Player "
    def __init__(self):
        self.inventory = []
        
        self.posX = 0
        self.posY = 0
        self.posZ = 0
        
        self.directionNorth = "north"
        self.directionSouth = "south"
        self.directionEast = "east"
        self.directionWest = "west"
        self.directionUp = "up"
        self.directionDown = "down"
        
    def Move(self, direction):
        " Move in the specified direction. "
        if (direction == "north"):
            self.posY += 1
        elif (direction == "south"):
            self.posY -= 1
        elif (direction == "east"):
            self.posX += 1
        elif (direction == "west"):
            self.posX -= 1
        elif (direction == "up"):
            self.posZ += 1
        elif (direction == "down"):
            self.posZ -= 1
            
    def GetCurrentRoom(self):
        return (self.posX, self.posY, self.posZ)

    def GetInventory(self):
        return self.inventory
    
    def GetInventoryItem(self, item):
        if item in self.inventory:
            return item
        else:
            return None
    
    def Pickup(self, item):
        # TODO: Add check to ensure that this is a real item
        self.inventory.append(item)
        return "You picked up " + item + "."
    
    def Drop(self, item):
        # TODO: Add check to ensure that this is actually in the inventory
        self.inventory.remove(item) 
        return "You've dropped " + item + "."
