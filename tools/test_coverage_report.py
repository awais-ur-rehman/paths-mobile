import unittest
from coverage_report import summarize
class CoverageTest(unittest.TestCase):
    def test_no_predictions_is_unknown_precision_and_pending_is_incomplete(self):
        self.assertEqual(summarize([{'scenario':'walk','mode':'foreground','expected':'yes','observed':'no'}])['precision'],None)
        self.assertEqual(summarize([{'scenario':'walk','mode':'foreground','expected':'yes','observed':'pending'}])['status'],'incomplete')
    def test_false_positives_and_missed_crossings_are_reported_separately(self):
        result=summarize([{'scenario':'same street','mode':'foreground','expected':'yes','observed':'yes'},{'scenario':'different floor','mode':'locked','expected':'no','observed':'yes'},{'scenario':'fast crossing','mode':'foreground','expected':'yes','observed':'no'}])
        self.assertEqual(result['precision'],.5)
        self.assertEqual(result['recall'],.5)
        self.assertEqual(result['falsePositives'],1)
        self.assertEqual(result['byMode']['locked']['falsePositives'],1)
if __name__=='__main__':unittest.main()
