import unittest

import Item

class TestItem(unittest.TestCase):
    " Tests for the Item Class "

    def setUp(self):
        " Set up initial items. "
        self.test_item_name = "Test Item"
        self.test_item_description = "This is an item. You feel tested."

        # Items for testing
        self.item_complete = Item.Item(self.test_item_name, self.test_item_description)
        self.item_empty = Item.Item()
        self.item_no_name = Item.Item(description=self.test_item_description)
        self.item_no_description = Item.Item(self.test_item_name)

    def testItem_itemIsAItem(self):
        " Is the item an Item()? "
        self.assertTrue(isinstance(self.item_complete, Item.Item))

    def testItem_itemHasName(self):
        " Does the name get correctly set? "
        item = Item.Item(self.test_item_name)
        self.assertEqual(self.item_no_description.name, self.test_item_name)

    def testItem_itemHasDescription(self):
        " Does the description get correctly set? "
        self.assertEqual(self.item_complete.description, self.test_item_description)

    def testItem_itemCanGetName(self):
        " Does GetName() work? "
        self.assertEqual(self.item_complete.GetName(), self.test_item_name)

    def testItem_itemCanSetName(self):
        " Does SetName(string) work? "
        self.item_complete.SetName("New Test Item Name")
        self.assertEqual(self.item_complete.GetName(), "New Test Item Name")

    def testItem_itemCanGetDescription(self):
        " Does GetDescription() return the proper string? "
        self.assertEqual(self.item_complete.GetDescription(), self.test_item_description)

    def testItem_itemCanSetDescription(self):
        " Does the SetDescription(string) work? "
        self.item_no_description.SetDescription(self.test_item_description)
        self.assertEqual(self.item_no_description.GetDescription(), self.test_item_description)

    def testItem_itemWarnsOnEmptyCreation(self):
        " Does a new item warn if empty? "
        # self.assertRaises(TypeError, self.item_empty)
        self.assertEqual(self.item_empty.GetName(), "UNDEFINED ITEM NAME - This is a bug.")
        self.assertEqual(self.item_empty.GetDescription(), "UNDEFINED ITEM DESCRIPTION - This is a bug.")

    def testItem_itemFailsWithoutAName(self):
        " Does a new item fail without a name variable? "
        self.assertRaises(TypeError, self.item_no_name)
