import unittest

import Room

class TestRoom(unittest.TestCase):
    " Unit tests for the Room class "
    
    def testRoom_roomIsARoom(self):
        " Make sure the class assigns correctly "
        room = Room.Room()
        self.assertTrue(isinstance(room, Room.Room))
        
    def testRoom_roomCanDescribe(self):
        " Does the Describe() method work as predicted? "
        room = Room.Room()
        description = "Wow. You've entered a new room."
        room.description = description
        self.assertEqual(room.Describe(), description)
        
    def testRoom_roomCanGetExits(self):
        " Does the GetExits method work as predicted? "
        room = Room.Room()
        room.exits = [room.directionNorth, room.directionSouth]
        self.assertEqual(room.GetExits(), room.exits)
        
    def testRoom_roomCanAddExit(self):
        " Does room.AddExit(direction) work? "
        room = Room.Room()
        room.AddExit(room.directionNorth)
        self.assertEqual(room.GetExits(), [room.directionNorth])
        
    def testRoom_roomDoesntAddFalseExits(self):
        " If given a false exit to add, do we return gracefully? "
        room = Room.Room()
        room.AddExit("Blernsday")
        self.assertEqual(room.GetExits(), [])
        
    def testRoom_roomDoesntAddRedundantExits(self):
        " Make sure we don't add an exit twice. "
        room = Room.Room()
        room.AddExit(room.directionNorth)
        room.AddExit(room.directionNorth)
        self.assertEqual(room.GetExits(), [room.directionNorth])
        
    def testRoom_roomCanRemoveExit(self):
        " Does the RemoveExit(direction) method work? "
        room = Room.Room()
        room.AddExit(room.directionNorth)
        room.AddExit(room.directionSouth)
        room.RemoveExit(room.directionNorth)
        self.assertEqual(room.GetExits(), [room.directionSouth])
        
    def testRoom_roomReturnsFromFalseRemove(self):
        " If given a false or redundant exit to remove, do we handle it gracefully? "
        room = Room.Room()
        room.AddExit(room.directionDown)
        room.RemoveExit(room.directionDown)
        room.RemoveExit(room.directionDown)
        
    def testRoom_roomCanGetItems(self):
        " Does the GetItems() method return a list of Items? "
        room = Room.Room()
        room.items = ["This Item.", "That item."]
        self.assertEqual(room.GetItems(), room.items)
        
    def testRoom_roomCanAddItem(self):
        " Does the AddItem(Item) work? "
        room = Room.Room()
        room.AddItem("This Item.")
        self.assertEqual(room.GetItems(), ["This Item."])
        
    def testRoom_roomCanRemoveItem(self):
        " Room.RemoveItem(Item) ? "
        room = Room.Room()
        room.AddItem("This Item.")
        room.AddItem("That Item.")
        room.RemoveItem("That Item.")
        self.assertEqual(room.GetItems(), ["This Item."])
