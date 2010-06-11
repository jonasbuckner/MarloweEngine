import unittest

import Player
import Item
from direction import north, south, west, east, up, down
import World
import DataProcessor

class TestPlayer(unittest.TestCase):
    """Player-specific tests"""

    def setUp(self):
        """Set up reusable variables and objects."""
        self.myItem = Item.Item("a Test Item", "This is a test item.")
        self.playerXStart = 0
        self.playerYStart = 0
        self.playerZStart = 0

        self.north = north["name"]
        self.south = south["name"]
        self.east = east["name"]
        self.west = west["name"]
        self.up = up["name"]
        self.down = down["name"]

    def testPlayer_playerIsAPlayer(self):
        """Is the player class being assigned?"""
        player = Player.Player()
        self.assertTrue(isinstance(player, Player.Player))

    def testPlayer_playerIsInXPosition(self):
        """Does the player start in the correct X position?"""
        player = Player.Player()
        self.assertEqual(player.posX, self.playerXStart)

    def testPlayer_playerIsInYPosition(self):
        """Does the player start in the correct Y position?"""
        player = Player.Player()
        self.assertEqual(player.posY, self.playerYStart)

    def testPlayer_playerIsInZPosition(self):
        """Does the player start in the correct Z position?"""
        player = Player.Player()
        self.assertEqual(player.posZ, self.playerZStart)

    #===========================================================================
    # Movement tests
    #===========================================================================
    def testPlayer_playerCanMoveNorth(self):
        """Can the Player move North?"""
        player = Player.Player()
        currentY = player.posY
        player.Move(self.north)
        self.assertEqual(player.posY, currentY + 1)

    def testPlayer_playerCanMoveSouth(self):
        """Can the Player move South?"""
        player = Player.Player()
        currentY = player.posY
        player.Move(self.south)
        self.assertEqual(player.posY, currentY - 1)

    def testPlayer_playerCanMoveEast(self):
        """Can the Player move East?"""
        player = Player.Player()
        currentX = player.posX
        player.Move(self.east)
        self.assertEqual(player.posX, currentX + 1)

    def testPlayer_playerCanMoveWest(self):
        """Can the Player move West?"""
        player = Player.Player()
        currentX = player.posX
        player.Move(self.west)
        self.assertEqual(player.posX, currentX - 1)

    def testPlayer_playerCanAscend(self):
        """Can the Player climb up?"""
        player = Player.Player()
        currentZ = player.posZ
        player.Move(self.up)
        self.assertEqual(player.posZ, currentZ + 1)

    def testPlayer_playerCanDescend(self):
        """Can the Player climb down?"""
        player = Player.Player()
        currentZ = player.posZ
        player.Move(self.down)
        self.assertEqual(player.posZ, currentZ - 1)

    def testPlayer_playerGetCurrentRoom(self):
        """Does Player.GetCurrentRoom() return the correct room?"""
        player = Player.Player()
        currentX = player.posX
        currentY = player.posY
        currentZ = player.posZ
        player.Move(self.north)
        player.Move(self.west)
        player.Move(self.up)
        currRoom = player.GetCurrentRoom()
        self.assertEqual(currRoom,
                         (currentX - 1,
                          currentY + 1,
                          currentZ + 1))

    def testPlayer_playerDoesntMoveInInvalidDirections(self):
        """Does the player fail silently when invalid room is given?"""
        player = Player.Player()
        currentX = player.posX
        currentY = player.posY
        currentZ = player.posZ
        World.ProcessWorld(DataProcessor.GetLevelData())
        player.Move(self.south)
        player.Move(self.east)
        self.assertEqual(player.GetCurrentRoom(), World.level[currentX][currentY][currentZ])
        World.level = []

    #===========================================================================
    # Inventory tests
    #===========================================================================
    def testPlayer_playerShowInventory(self):
        """Does Player.ShowInventory() show the inventory?"""
        player = Player.Player()
        anotherTestItem = Item.Item("Another Test Item", "This is another test item.")
        player.inventory.append(self.myItem)
        player.inventory.append(anotherTestItem)
        self.assertEqual(player.GetInventory(), [self.myItem, anotherTestItem])

    def testPlayer_playerGetInventoryItem(self):
        """Does the player have a method called Player.GetInventoryItem(Item), and does it work?"""
        player = Player.Player()
        player.inventory.append(self.myItem)
        self.assertEqual(player.GetInventoryItem(self.myItem), self.myItem)

    def testPlayer_playerCanPickupToInventory(self):
        """Can the Player call Pickup(Item), and is the Item in the the inventory?"""
        player = Player.Player()
        player.Pickup(self.myItem)
        self.assertEqual(player.GetInventoryItem(self.myItem), self.myItem)

    def testPlayer_playerCanDrop(self):
        """Can the Player call Drop(Item)?"""
        player = Player.Player()
        player.Pickup(self.myItem)
        player.Drop(self.myItem)
        self.assertEqual(player.GetInventoryItem(self.myItem), None)

    def testPlayer_droppedItemInRoom(self):
        """Is the dropped item in the current room?"""
        player = Player.Player()
        player.Pickup(self.myItem)
        player.Drop(self.myItem)
        self.assertEqual(player.GetCurrentRoom().GetItem(self.myItem), self.myItem)
