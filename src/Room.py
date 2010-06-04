from direction import valid_directions

class Room:
    " Defines the Rooms of the world "
    def __init__(self):
        self.title = "UNDEFINED ROOM TITLE - This is a bug."
        self.description = "UNDEFINED ROOM DESCRIPTION - This is a bug."
        self.exits = []
        self.items = []
        
        self.directionNorth = "north"
        self.directionSouth = "south"
        self.directionEast = "east"
        self.directionWest = "west"
        self.directionUp = "up"
        self.directionDown = "down"
        
    def Describe(self):
        return self.description
    
    def GetExits(self):
        " Return a list of all valid exits in the room. "
        return self.exits
    
    def AddExit(self, direction):
        " Add an exit to the list of exits. Hopefully it's already valid. "
        for dir in valid_directions:
            if dir['name'] == direction:
                if direction not in self.exits:
                    self.exits.append(direction)
        
    def RemoveExit(self, direction):
        " Remove an exit "
        if (direction in self.exits):
            self.exits.remove(direction)
    
    def GetItems(self):
        " Return a list of all the items in the room. "
        return self.items
    
    def AddItem(self, item):
        " Add an item to the room's list. "
        self.items.append(item)
        
    def RemoveItem(self, item):
        " Remove an item from the room's list. "
        if (item in self.items):
            self.items.remove(item)
