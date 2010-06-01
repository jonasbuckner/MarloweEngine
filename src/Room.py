

class Room:
    " Defines the Rooms of the world "
    def __init__(self):
        self.title = "UNDEFINED ROOM TITLE - This is a bug."
        self.description = "UNDEFINED ROOM DESCRIPTION - This is a bug."
        self.exits = []
        
    def Describe(self):
        return self.description
