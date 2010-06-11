import unittest
import World
import DataProcessor
import direction
import Room

class TestWorld(unittest.TestCase):
    """Testing for the World Class"""

    def setUp(self):
        self.first_room_name = DataProcessor.level[0]["name"]
        self.first_room_description = DataProcessor.level[0]["description"]
        self.first_room_exits = DataProcessor.level[0]["exits"]
        self.fr_x = DataProcessor.level[0]["position"][0]
        self.fr_y = DataProcessor.level[0]["position"][1]
        self.fr_z = DataProcessor.level[0]["position"][2]

        self.second_room_name = DataProcessor.level[1]["name"]
        self.second_room_description = DataProcessor.level[1]["description"]
        self.second_room_exits = DataProcessor.level[1]["exits"]
        self.sr_x = DataProcessor.level[1]["position"][0]
        self.sr_y = DataProcessor.level[1]["position"][1]
        self.sr_z = DataProcessor.level[1]["position"][2]

        self.third_room_name = DataProcessor.level[2]["name"]
        self.third_room_description = DataProcessor.level[2]["description"]
        self.third_room_exits = DataProcessor.level[2]["exits"]
        self.tr_x = DataProcessor.level[2]["position"][0]
        self.tr_y = DataProcessor.level[2]["position"][1]
        self.tr_z = DataProcessor.level[2]["position"][2]

    def testWorld_worldHasLevel(self):
        """Does the World have a level list?"""
        self.assertTrue(isinstance(World.level, list))

    def testWorld_ProcessWorld(self):
        """Does the ProcessWorld() function create a proper world?"""
        World.ProcessWorld(DataProcessor.GetLevelData())
        self.assertEqual(World.level[self.fr_x][self.fr_y][self.fr_z].GetTitle(), self.first_room_name)
        self.assertEqual(World.level[self.sr_x][self.sr_y][self.sr_z].GetExits(), self.second_room_exits)
        self.assertEqual(World.level[self.tr_x][self.tr_y][self.tr_z].GetTitle(), self.third_room_name)

    def testWorld_worldCanGetRoom(self):
        """Does the GetRoom(x,y,z) function return a real room?"""
        room = Room.Room(self.first_room_name, self.first_room_description)
        for x in self.first_room_exits:
            room.AddExit(x)
        self.assertEqual(World.GetRoom(self.fr_x, self.fr_y, self.fr_z), room)
