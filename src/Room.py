from direction import valid_directions

class Room:
    """Defines the Rooms of the world"""
    def __init__(self, title="UNDEFINED ROOM TITLE - This is a bug.", description="UNDEFINED ROOM DESCRIPTION - This is a bug."):
        self.title = title
        self.description = description
        self.exits = []
        self.items = []

    def GetTitle(self):
        """Returns the title of the current room."""
        return self.title

    def SetTitle(self, title):
        """Resets the title of the current room."""
        # TODO: Check the room title for uniqueness
        self.title = title

    def SetDescription(self, description):
        """Set the description of the current room."""
        self.description = description

    def GetDescription(self):
        """Get the description of the current room."""
        return self.description

    def GetExits(self):
        " Return a list of all valid exits in the room. "
        return self.exits

    def AddExit(self, direction):
        """Add an exit to the list of exits, checking if it's valid."""
        for dir in valid_directions:
            if dir['name'] == direction:
                if direction not in self.exits:
                    self.exits.append(direction)

    def RemoveExit(self, direction):
        """Remove an exit"""
        if (direction in self.exits):
            self.exits.remove(direction)

    def GetItems(self):
        """Return a list of all the items in the room."""
        return self.items

    def AddItem(self, item):
        """Add an item to the room's list."""
        if item not in self.items:
            self.items.append(item)

    def RemoveItem(self, item):
        """Remove an item from the room's list."""
        if item in self.items:
            self.items.remove(item)
