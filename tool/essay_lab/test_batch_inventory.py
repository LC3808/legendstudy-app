import unittest

from .batch_inventory import classify


class InventoryScopeTest(unittest.TestCase):
    def test_missing_input_never_promotes_an_inherited_profile(self):
        self.assertEqual(classify(True, None), 'NEEDS_REVIEW')
        self.assertEqual(classify(True, {'passed': False}), 'NEEDS_REVIEW')

    def test_identity_drift_blocks_even_preserved_success(self):
        self.assertEqual(classify(False, {'passed': True}, True), 'NEEDS_REVIEW')

    def test_existing_math_success_is_preserved_separately(self):
        self.assertEqual(classify(True, None, True), 'FULL_EVALUATION')
        self.assertEqual(classify(True, {'passed': True}), 'FULL_EVALUATION')
