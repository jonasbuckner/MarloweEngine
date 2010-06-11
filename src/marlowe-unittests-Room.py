import unittest

import Room
import Item
from direction import north, south, west, east, up, down

class TestRoom(unittest.TestCase):
    """Unit tests for the Room class"""

    def setUp(self):
        """Reusable constants"""
        self.generic_room_title = "A Generic Room"
        self.generic_room_desc = "Wow. You've entered a new room."

        self.north = north["name"]
        self.south = south["name"]
        self.east = east["name"]
        self.west = west["name"]
        self.up = up["name"]
        self.down = down["name"]

        self.fake_exit = "Blernsday"

        self.first_item = Item.Item("my First Item", "This is our first test item.")
        self.second_item = Item.Item("my Second Item", "Oh, my! A second test item!")

    def testRoom_roomIsARoom(self):
        """Does the class assign okay?"""
        room = Room.Room()
        self.assertTrue(isinstance(room, Room.Room))

    def testRoom_roomCanGetTitle(self):
        """Does the current room title return properly?"""
        room = Room.Room()
        room.title = self.generic_room_title
        self.assertEqual(room.GetTitle(), self.generic_room_title)

    def testRoom_roomCanSetTitle(self):
        """Does the title get set with SetTitle(string)?"""
        room = Room.Room()
        room.SetTitle(self.generic_room_title)
        self.assertEqual(room.GetTitle(), self.generic_room_title)

    def testRoom_roomCanDescribe(self):
        """Does the Describe() method work as predicted?"""
        room = Room.Room()
        room.description = self.generic_room_desc
        self.assertEqual(room.GetDescription(), self.generic_room_desc)

    def testRoom_roomCanSetDescription(self):
        """Does the room description get set with SetDescription(string)?"""
        room = Room.Room()
        room.SetDescription(self.generic_room_desc)
        self.assertEqual(room.GetDescription(), self.generic_room_desc)

    def testRoom_roomCanGetExits(self):
        """Does the GetExits method work as predicted?"""
        room = Room.Room()
        room.exits = [self.north, self.south]
        self.assertEqual(room.GetExits(), room.exits)

    def testRoom_roomCanAddExit(self):
        """Does room.AddExit(direction) work?"""
        room = Room.Room()
        room.AddExit(self.north)
        self.assertEqual(room.GetExits(), [self.north])

    def testRoom_roomDoesntAddFalseExits(self):
        """If given a false exit to add, do we return gracefully?"""
        room = Room.Room()
        room.AddExit("Blernsday")
        self.assertEqual(room.GetExits(), [])

    def testRoom_roomDoesntAddRedundantExits(self):
        """Make sure we don't add an exit twice."""
        room = Room.Room()
        room.AddExit(self.north)
        room.AddExit(self.north)
        self.assertEqual(room.GetExits(), [self.north])

    def testRoom_roomCanRemoveExit(self):
        """Does the RemoveExit(direction) method work?"""
        room = Room.Room()
        room.AddExit(self.north)
        room.AddExit(self.south)
        room.RemoveExit(self.north)
        self.assertEqual(room.GetExits(), [self.south])

    def testRoom_roomReturnsFromFalseRemove(self):
        """If given a false or redundant exit to remove, do we handle it gracefully?"""
        room = Room.Room()
        room.AddExit(self.down)
        room.RemoveExit(self.down)
        room.RemoveExit(self.down)

    def testRoom_roomCanGetItems(self):
        """Does the GetItems() method return a list of Items?"""
        room = Room.Room()
        room.items = [self.first_item]
        self.assertEqual(room.GetItems(), room.items)

    def testRoom_roomCanAddItem(self):
        """Does the AddItem(Item) work?"""
        room = Room.Room()
        room.AddItem(self.first_item)
        self.assertEqual(room.GetItems(), [self.first_item])

    def testRoom_roomCanRemoveItem(self):
        """Room.RemoveItem(Item) ?"""
        room = Room.Room()
        room.AddItem(self.first_item)
        room.AddItem(self.second_item)
        room.RemoveItem(self.second_item)
        self.assertEqual(room.GetItems(), [self.first_item])
