import Room

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

    for room in world:
        new_room = Room.Room(room["name"], room["description"])
        for exit in room["exits"]:
            new_room.AddExit(exit)
        try:
            # if exists(level[room_x_pos])
            if level[room["position"][0]]:
                try:
                    # if exists(level[room_x_pos][room_y_pos])
                    if level[room["position"][0]][room["position"][1]]:
                        try:
                            # if exists(level[room_x_pos][room_y_pos][room_z_pos])
                            if level[room["position"][0]][room["position"][1]][room["position"][2]]:
                                level[room["position"][0]][room["position"][1]][room["position"][2]] = new_room
                        except IndexError: # else
                            for z in range(0, room["position"][2] + 1): # for (z=0; z<=room_z_pos; z++)
                                try:
                                    # if exists(level[room_x_pos][room_y_pos][z]
                                    if level[room["position"][0]][room["position"][1]][z]:
                                        pass # jump to the next iteration
                                except IndexError: # else
                                    level[room["position"][0]][room["position"][1]].append("") # Create it blank

                            # Out of the loop
                            level[room["position"][0]][room["position"][1]][room["position"][2]] = new_room

                except IndexError: # else if not exists(level[room_x_pos][room_y_pos])
                    for y in range(0, room["position"][1] + 1):
                        try:
                            # if exists(level[room_x_pos][y])
                            if level[room["position"][0]][y]:
                                continue
                        except IndexError:
                            # else if not exists(level[room_x_pos][y])
                            level[room["position"][0]].append([]) # Then create a blank string in its place

                    for z in range(0, room["position"][2] + 1):
                        level[room["position"][0]][room["position"][1]].append("")

                    level[room["position"][0]][room["position"][1]][room["position"][2]] = new_room

        except IndexError: # else if not exists(level[room_x_position])
            for x in range(0, room["position"][0] + 1):
                try:
                    # if exists(level[x])
                    if level[x]:
                        continue
                except IndexError:
                    # else if not exists(level[x])
                    level.append([]) # Create it blank

            for y in range(0, room["position"][1] + 1):
                level[room["position"][0]].append([])   # Add all the blank y values

            for z in range(0, room["position"][2] + 1):
                level[room["position"][0]][room["position"][1]].append("")    # Add all the blank z values    

            level[room["position"][0]][room["position"][1]][room["position"][2]] = new_room

def GetRoom(x, y, z):
    """Returns an object reference to the room in question"""
    return level[x][y][z]
