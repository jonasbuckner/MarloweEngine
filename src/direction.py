""" This is a collection of valid directions.

They are hard-coded for now, until I can pull them
into the database.

'name' will eventually be decided by gettext.

'delta' is a vector of which direction to move,
given in the format (x, y, z)
"""

# Cardinal Directions
north = { 'name':"north", 'delta':(0, 1, 0) }
south = { 'name':"south", 'delta':(0, -1, 0) }
east = { 'name':"east", 'delta':(1, 0, 0) }
west = { 'name':"west", 'delta':(-1, 0, 0) }

# Up and Down
up = { 'name':"up", 'delta':(0, 0, 1) }
down = { 'name':"down", 'delta':(0, 0, -1) }

# Diagonals
northeast = { 'name':"northeast", 'delta':(1, 1, 0) }
southeast = { 'name':"southeast", 'delta':(1, -1, 0) }
northwest = { 'name':"northwest", 'delta':(-1, 1, 0) }
southwest = { 'name':"southwest", 'delta':(-1, -1, 0) }

valid_directions = [north, south, east, west, up, down]
