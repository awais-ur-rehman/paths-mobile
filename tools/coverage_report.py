"""Summarize owner-labelled scenarios without identities or coordinates."""
import argparse
import csv
import json

def counts(rows):
    tp=sum(row['expected']=='yes' and row['observed']=='yes' for row in rows)
    fp=sum(row['expected']=='no' and row['observed']=='yes' for row in rows)
    fn=sum(row['expected']=='yes' and row['observed']=='no' for row in rows)
    return {'truePositives':tp,'falsePositives':fp,'falseNegatives':fn,'precision':tp/(tp+fp) if tp+fp else None,'recall':tp/(tp+fn) if tp+fn else None}

def summarize(rows):
    if not rows or any(row.get('expected') not in ('yes','no') or row.get('observed') not in ('yes','no') or not row.get('scenario') or not row.get('mode') for row in rows):
        return {'status':'incomplete','limitation':'Fill every ground-truth label; pending or missing results cannot count as success.'}
    result=counts(rows)
    return {'status':'measured','scenarios':len(rows),**result,'byMode':{mode:counts([row for row in rows if row['mode']==mode]) for mode in sorted({row['mode'] for row in rows})},'limitation':'Labels are owner observations; this is not proof of venue, floor or universal encounter accuracy. Expand repetitions before a pilot claim.'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('csv_file');args=parser.parse_args()
    with open(args.csv_file,newline='') as source:print(json.dumps(summarize(list(csv.DictReader(source)))))
