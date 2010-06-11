class Item(object):
    """ Creates Items in the Game World 
    
        Usage:
            import Item
            my_item = Item.Item('Item Name', 'Item Description')
    """

    def __init__(self, name="UNDEFINED ITEM NAME - This is a bug.", description="UNDEFINED ITEM DESCRIPTION - This is a bug."):
        self.name = name
        self.description = description

    def GetName(self):
        """Get the item's name."""
        return self.name

    def SetName(self, name):
        """Set the item's name."""
        # TODO: Fail if item already exists in world.
        self.name = name

    def GetDescription(self):
        """Get the item's current description."""
        return self.description

    def SetDescription(self, description):
        """Set the item's description."""
        # TODO: Warn if description is a duplicate with another item.
        self.description = description
