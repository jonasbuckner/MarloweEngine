import Room
from operator import itemgetter

level = []

def SortRooms(x, y):
    """Sort the Rooms By Their Position"""
    if x["position"][0] == y["position"][0] and x["position"][1] == y["position"][1] and x["position"][2] == y["position"][2]:
        return 0
    elif x["position"][0] > y["position"][0]:
        return 1

def ProcessWorld(world):
    """Sets up the world from the list returned by the DataProcessor
    
    It expects the world variable to be in the following form:
    [ {
       "name":"Room Name",
       "description":"Room Description",
       "exits":[direction.north]             # This is a list of directions from the direction class
       "position":[0, 0, 0]                  # This contains a vector in the form [x, y, z]
      },
    ]
    """


    for room in world.sort(lambda x, y: cmp(x["position"], y["position"])):
        new_room = Room.Room(room["name"], room["description"])
        for exit in room["exits"]:
            new_room.AddExit(exit)
        level[room["position"][0]][room["position"][1]][room["position"][2]] = new_room

def GetRoom(x, y, z):
    """Returns an object reference to the room in question"""
    return level[x][y][z]
