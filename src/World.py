import Room

level = [[["" for z in range(0, 10)] for y in range(0, 50)] for x in range(0, 50)] # 50x50x10

def ProcessWorld(world):
    """Sets up the world from the list returned by the DataProcessor
    
    It expects the world variable to be in the following form:
    [ {
       "name":"Room Name",
       "description":"Room Description",
       "exits":["north", "south"]            # This is a list of directions from the direction class
       "position":[0, 0, 0]                  # This contains a vector in the form [x, y, z]
      },
    ]
    """

    for room in world:
        new_room = Room.Room(room["name"], room["description"])
        for exit in room["exits"]:
            new_room.AddExit(exit)
        level[room["position"][0]][room["position"][1]][room["position"][2]] = new_room

def GetRoom(x, y, z):
    """Returns an object reference to the room in question"""
    return level[x][y][z]
