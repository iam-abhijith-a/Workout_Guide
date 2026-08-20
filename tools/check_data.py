# -*- coding: utf-8 -*-
"""Spot-check the derived pattern/difficulty labels against lifts whose correct
classification is not in dispute. Run after any change to build_data.py."""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'app', 'assets', 'data', 'exercises.json')

# (name fragment, expected pattern, expected difficulty)
EXPECT = [
    ('barbell full squat', 'squat', 1),
    ('dumbbell lunge', 'lunge', 0),
    ('barbell deadlift', 'hinge', 1),
    ('lever leg extension', 'leg_iso', 0),
    ('lever seated hip abduction', 'leg_iso', 0),
    ('lever seated leg curl', 'leg_iso', 0),
    ('barbell bench press', 'horizontal_push', 1),
    ('dumbbell bench press', 'horizontal_push', 0),
    ('push-up', 'horizontal_push', 0),
    ('cable seated row', 'horizontal_pull', 0),
    ('pull-up', 'vertical_pull', 1),
    ('assisted pull-up', 'vertical_pull', 0),
    ('dumbbell lateral raise', 'shoulder_iso', 0),
    ('barbell curl', 'arm_biceps', 0),
    ('cable pushdown', 'arm_triceps', 0),
    ('standing calf raise', 'calf', 0),
    ('crunch', 'core', 0),
    ('plank', 'core', 0),
    ('hamstring stretch', 'stretch', 0),
    ('barbell clean and press', None, 2),
    ('barbell snatch', None, 2),
    ('pistol squat', None, 2),
    ('handstand push-up', None, 2),
    ('barbell behind head military press', None, 2),
]


# (name fragment, kit it needs at home) -- None means it cannot be done at home
# at all. These are the calls a user would notice immediately: a push-up that
# demanded a bench, or a lat pulldown offered to someone in a living room.
HOME_EXPECT = [
    ('push-up', []),
    ('jump squat', []),
    ('mountain climber', []),
    ('burpee', []),
    ('glute bridge', []),
    ('walking lunge', []),
    ('pull-up', ['pullup_bar']),
    ('chin-up', ['pullup_bar']),
    ('hanging leg raise', ['pullup_bar']),
    ('dumbbell biceps curl', ['dumbbell']),
    ('dumbbell lunge', ['dumbbell']),
    ('dumbbell bench press', ['bench', 'dumbbell']),
    ('bench dip (knees bent)', ['bench']),
    ('band bench press', ['band', 'bench']),
    # Caught on a phone, in the grid, filed as "no kit": the name says nothing
    # and only the instructions give the machine away.
    ('gorilla chin', ['pullup_bar']),
    ('monster walk', ['band']),
    ('donkey calf raise', ['bench']),
    ('dumbbell fly', ['bench', 'dumbbell']),
    ('glute-ham raise', None),
    ('hyperextension', None),
    ('balance board', None),
    ('straddle maltese', None),
    ('barbell full squat', None),
    ('cable seated row', None),
    ('lever leg extension', None),
    ('smith bench press', None),
    ('kettlebell swing', None),
    ('chest dip (on dip-pull-up cage)', None),
    ('captains chair straight leg raise', None),
]


def check_home(by_name):
    """Every entry either carries a kit list or is off the home page entirely."""
    fails = 0
    for frag, want in HOME_EXPECT:
        hits = [e for n, e in by_name.items() if frag in n]
        if not hits:
            print('  SKIP  no match for %r' % frag)
            continue
        e = min(hits, key=lambda x: len(x['name']))
        got = sorted(e['home']) if 'home' in e else None
        if got == (sorted(want) if want is not None else None):
            print('  ok    %-42s %s' % (e['name'], 'gym only' if got is None else got))
        else:
            fails += 1
            print('  FAIL  %-42s %s   (want %s)' % (e['name'], got, want))
    return fails


def main():
    with open(DATA, encoding='utf-8') as f:
        data = json.load(f)
    by_name = {e['name'].lower(): e for e in data}

    fails = 0
    for frag, pattern, diff in EXPECT:
        hits = [e for n, e in by_name.items() if frag in n]
        if not hits:
            print('  SKIP  no match for %r' % frag)
            continue
        # Prefer the shortest name -- that is the plain, unqualified variant.
        e = min(hits, key=lambda x: len(x['name']))
        ok_p = pattern is None or e['pattern'] == pattern
        ok_d = e['difficulty'] == diff
        if ok_p and ok_d:
            print('  ok    %-42s %-16s d%d' % (e['name'], e['pattern'], e['difficulty']))
        else:
            fails += 1
            print('  FAIL  %-42s %-16s d%d   (want %s d%s)'
                  % (e['name'], e['pattern'], e['difficulty'], pattern, diff))

    print('\nhome kit:')
    home_fails = check_home(by_name)

    total = len(EXPECT) + len(HOME_EXPECT)
    print('\n%d/%d checks failed' % (fails + home_fails, total))
    return 1 if fails + home_fails else 0


if __name__ == '__main__':
    sys.exit(main())
