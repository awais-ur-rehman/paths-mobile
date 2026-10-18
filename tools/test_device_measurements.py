import unittest
from device_measurements import battery_snapshot, compare_runs

class MeasurementsTest(unittest.TestCase):
    def test_parser_keeps_only_aggregate_battery_fields(self):
        result = battery_snapshot('AC powered: false\nUSB powered: false\nWireless powered: false\nlevel: 88\nscale: 100\ntemperature: 310\nsecret: must not copy')
        self.assertEqual(result, {'level': 88, 'scale': 100, 'charging': False, 'temperatureC': 31})
        with self.assertRaises(ValueError): battery_snapshot('level: 88')
    def test_eight_hour_goal_never_passes_short_or_charging_runs(self):
        def entry(time, level, charging=False): return {'timeSeconds': time, 'level': level, 'scale': 100, 'charging': charging, 'device': 'same-test-device'}
        runs = {'baseline-start': entry(0,100),'baseline-end': entry(28800,96),'tracking-start': entry(30000,100),'tracking-end': entry(58800,94)}
        result = compare_runs(runs)
        self.assertEqual(result['additionalPercentagePoints'], 2)
        self.assertEqual(result['status'], 'within-experimental-goal')
        runs['tracking-end']['charging'] = True
        self.assertEqual(compare_runs(runs)['status'], 'invalid-comparison')
        runs['tracking-end'] = entry(31000,99)
        self.assertEqual(compare_runs(runs)['status'], 'invalid-comparison')

if __name__ == '__main__': unittest.main()
