import sqlite3

class DataProcessor:
    """ Process data from the various data stores and
    make it available to the rest of the game """
    def ReadWorld(self):
        " Process Data from the world storage. "
        conn = sqlite3.connect("marlowe.sqlite")
        c = conn.cursor()
        c.execute("select * from room;")
        
        world = []
        for row in c:
            world.push(row)
            
        c.close()
        
        return world        
