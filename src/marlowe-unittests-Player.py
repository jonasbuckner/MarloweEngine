import unittest

import Player

class TestPlayer(unittest.TestCase):
    " Player-specific tests "
    
    def setUp(self):
        " Set up reusable variables and objects. "
        self.myItem = "Test Item"
        self.playerXStart = 0
        self.playerYStart = 0
        self.playerZStart = 0
    
    def testPlayer_playerIsAPlayer(self):
        " Is the player class being assigned? "
        player = Player.Player()
        self.assertTrue(isinstance(player, Player.Player))
        
    def testPlayer_playerIsInXPosition(self):
        " Does the player start in the correct X position? "
        player = Player.Player()
        self.assertEqual(player.posX, self.playerXStart)
        
    def testPlayer_playerIsInYPosition(self):
        " Does the player start in the correct Y position? "
        player = Player.Player()
        self.assertEqual(player.posY, self.playerYStart)
        
    def testPlayer_playerIsInZPosition(self):
        " Does the player start in the correct Z position? "
        player = Player.Player()
        self.assertEqual(player.posZ, self.playerZStart)
        
    def testPlayer_playerCanMoveNorth(self):
        " Can the Player move North? "
        player = Player.Player()
        currentY = player.posY
        player.Move(player.directionNorth)
        self.assertEqual(player.posY, currentY + 1)
        
    def testPlayer_playerCanMoveSouth(self):
        " Can the Player move South? "
        player = Player.Player()
        currentY = player.posY
        player.Move(player.directionSouth)
        self.assertEqual(player.posY, currentY - 1)
        
    def testPlayer_playerCanMoveEast(self):
        " Can the Player move East? "
        player = Player.Player()
        currentX = player.posX
        player.Move(player.directionEast)
        self.assertEqual(player.posX, currentX + 1)
        
    def testPlayer_playerCanMoveWest(self):
        " Can the Player move West? "
        player = Player.Player()
        currentX = player.posX
        player.Move(player.directionWest)
        self.assertEqual(player.posX, currentX - 1)
        
    def testPlayer_playerCanAscend(self):
        " Can the Player climb up? "
        player = Player.Player()
        currentZ = player.posZ
        player.Move(player.directionUp)
        self.assertEqual(player.posZ, currentZ + 1)
        
    def testPlayer_playerCanDescend(self):
        " Can the Player climb down? "
        player = Player.Player()
        currentZ = player.posZ
        player.Move(player.directionDown)
        self.assertEqual(player.posZ, currentZ - 1)
        
    def testPlayer_playerGetCurrentRoom(self):
        " Does Player.GetCurrentRoom() return the correct room? "
        player = Player.Player()
        currentX = player.posX
        currentY = player.posY
        currentZ = player.posZ
        player.Move(player.directionNorth)
        player.Move(player.directionWest)
        player.Move(player.directionUp)
        currRoom = player.GetCurrentRoom()
        self.assertEquals(currRoom[0], currentX - 1)
        self.assertEqual(currRoom[1], currentY + 1)
        self.assertEqual(currRoom[2], currentZ + 1)
        
    def testPlayer_playerShowInventory(self):
        " Does Player.ShowInventory() show the inventory? "
        player = Player.Player()
        anotherTestItem = "Another Test Item"
        player.inventory.append(self.myItem)
        player.inventory.append(anotherTestItem)
        self.assertEqual(player.GetInventory(), [self.myItem, anotherTestItem])
            
    def testPlayer_playerGetInventoryItem(self):
        " Does the player have a method called Player.GetInventoryItem(Item), and does it work? "
        player = Player.Player()
        player.inventory.append(self.myItem)
        self.assertEqual(player.GetInventoryItem(self.myItem), self.myItem)
        
    def testPlayer_playerCanPickupToInventory(self):
        " Can the Player call Pickup(Item), and is the Item in the the inventory? "
        player = Player.Player()
        player.Pickup(self.myItem)
        self.assertEqual(player.GetInventoryItem(self.myItem), self.myItem)
            
    def testPlayer_playerCanDrop(self):
        " Can the Player call Drop(Item)? "
        player = Player.Player()
        player.Pickup(self.myItem)
        player.Drop(self.myItem)
        self.assertEqual(player.GetInventoryItem(self.myItem), None)
        
    def testPlayer_droppedItemInRoom(self):
        " Is the dropped item in the current room? "
        player = Player.Player()
        player.Pickup(self.myItem)
        player.Drop(self.myItem)
        self.assertEqual(player.GetCurrentRoom().GetItem(self.myItem), self.myItem)
        
