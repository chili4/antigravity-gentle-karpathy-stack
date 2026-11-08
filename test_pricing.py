import unittest
from pricing import calculate_discount

class TestPricing(unittest.TestCase):
    def test_vip(self):
        self.assertEqual(calculate_discount(100.0, "vip"), 20.0)

    def test_gold(self):
        self.assertEqual(calculate_discount(100.0, "gold"), 10.0)

    def test_standard(self):
        self.assertEqual(calculate_discount(100.0, "regular"), 0.0)

if __name__ == "__main__":
    unittest.main()
