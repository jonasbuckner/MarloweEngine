""" Process data from the various data stores and
    make it available to the rest of the game 

    This is currently a stub. Values are hardcoded.
"""

import sqlite3
import direction

level = []
level.append({})
level[0]["name"] = "The First Room."
level[0]["description"] = "You are in the first room."
level[0]["exits"] = []
level[0]["exits"].append("north")
level[0]["exits"].append("west")
level[0]["position"] = (8, 0, 0)

level.append({})
level[1]["name"] = "The Northern Room."
level[1]["description"] = "You are in the Northern room."
level[1]["exits"] = []
level[1]["exits"].append("south")
level[1]["position"] = (8, 1, 0)

level.append({})
level[2]["name"] = "The Western Room."
level[2]["description"] = "You are in the Western room."
level[2]["exits"] = []
level[2]["exits"].append("east")
level[2]["position"] = (7, 0, 0)


def ReadWorld(self):
    """Process Data from the world storage."""
    conn = sqlite3.connect("marlowe.sqlite")
    c = conn.cursor()
    c.execute("select * from room;")

    world = []
    for row in c:
        world.push(row)

    c.close()

    return world

def GetLevelData():
    return level
