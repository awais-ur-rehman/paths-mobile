"""Owner-operated aggregate battery collection; no location, messages or credentials."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time


def battery_snapshot(raw):
    fields = dict(re.findall(r'^\s*([A-Za-z ]+):\s*(\S+)\s*$', raw, re.M))
    required = ('level', 'scale', 'temperature', 'AC powered', 'USB powered', 'Wireless powered')
    if any(key not in fields for key in required):
        raise ValueError('Incomplete battery reading')
    level, scale = int(fields['level']), int(fields['scale'])
    if not 0 <= level <= scale or scale <= 0:
        raise ValueError('Invalid battery reading')
    return {'level': level, 'scale': scale, 'charging': any(fields[key] == 'true' for key in required[3:]), 'temperatureC': int(fields['temperature']) / 10}


def compare_runs(runs):
    labels = ('baseline-start', 'baseline-end', 'tracking-start', 'tracking-end')
    if any(label not in runs for label in labels):
        return {'status': 'incomplete'}
    a, b, c, d = (runs[label] for label in labels)
    baseline, tracking = b['timeSeconds'] - a['timeSeconds'], d['timeSeconds'] - c['timeSeconds']
    if len({row['device'] for row in (a,b,c,d)}) != 1 or any(row['charging'] for row in (a,b,c,d)) or min(baseline,tracking) < 28800 or abs(baseline-tracking) > 900:
        return {'status': 'invalid-comparison', 'reason': 'Use the same unplugged device for matched runs of at least eight hours, within fifteen minutes of one another.'}
    idle = 100 * (a['level']/a['scale'] - b['level']/b['scale'])
    active = 100 * (c['level']/c['scale'] - d['level']/d['scale'])
    if min(idle, active) < 0:
        return {'status': 'invalid-comparison', 'reason': 'Battery increased; repeat without charging.'}
    extra = round(active-idle,3)
    return {'status': 'within-experimental-goal' if extra <= 3 else 'above-experimental-goal', 'additionalPercentagePoints': extra, 'baselineDropPercentagePoints': round(idle,3), 'trackingDropPercentagePoints': round(active,3), 'baselineSeconds': baseline, 'trackingSeconds': tracking, 'limitation': 'Endpoint charging flags do not prove an entire run was unplugged. Owner must confirm charging, matched usage and coverage separately.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True)
    parser.add_argument('--record', choices=('baseline-start','baseline-end','tracking-start','tracking-end'))
    parser.add_argument('--file', type=Path, default=Path('artifacts/task13/battery.local.json'))
    args = parser.parse_args()
    runs = json.loads(args.file.read_text()) if args.file.exists() else {}
    if args.record:
        raw = subprocess.check_output(['adb','-s',args.device,'shell','dumpsys','battery'], text=True, timeout=15)
        runs[args.record] = {**battery_snapshot(raw), 'timeSeconds': time.time(), 'device': args.device}
        args.file.parent.mkdir(parents=True,exist_ok=True)
        args.file.write_text(json.dumps(runs,indent=2)+'\n')
        args.file.chmod(0o600)
    print(json.dumps(compare_runs(runs)))


if __name__ == '__main__':
    main()
