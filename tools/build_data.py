# -*- coding: utf-8 -*-
"""Turn the raw 17MB / 10-language dataset into a slim, English-only, beginner-enriched
asset for the Flutter app.

The raw dataset is a reference catalogue: it knows *what* an exercise is, not *whether a
beginner should do it* or *how it fits into a week of training*. This script adds the
missing layer:

  pattern      movement pattern (squat / hinge / horizontal_push / ...) so the plan
               generator can build balanced days instead of picking at random
  difficulty   0 beginner / 1 intermediate / 2 advanced
  compound     multi-joint lifts, which anchor every session
  unilateral   one-side-at-a-time work, which needs different set handling
  equipClass   coarse equipment bucket matched against what the user actually has
  home         the kit a movement needs in a flat (an empty list means a floor and
               nothing else); the key is absent entirely when it needs a gym
"""
import json
import os
import re
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'exercises-dataset', 'data', 'exercises.json')
OUT_DIR = os.path.join(ROOT, 'app', 'assets', 'data')
os.makedirs(OUT_DIR, exist_ok=True)

# -- Equipment buckets -------------------------------------------------------
# Bucketed by what a user would answer to "what do you have access to?".
EQUIP_CLASS = {
    'body weight': 'bodyweight', 'weighted': 'bodyweight', 'assisted': 'machine',
    'dumbbell': 'dumbbell', 'kettlebell': 'kettlebell',
    'barbell': 'barbell', 'ez barbell': 'barbell', 'olympic barbell': 'barbell',
    'trap bar': 'barbell', 'smith machine': 'machine',
    'cable': 'cable', 'leverage machine': 'machine', 'sled machine': 'machine',
    'band': 'band', 'resistance band': 'band', 'rope': 'band',
    'stability ball': 'ball', 'bosu ball': 'ball', 'medicine ball': 'ball',
    'wheel roller': 'other', 'roller': 'other', 'hammer': 'other', 'tire': 'other',
    'stationary bike': 'cardio_machine', 'elliptical machine': 'cardio_machine',
    'stepmill machine': 'cardio_machine', 'skierg machine': 'cardio_machine',
    'upper body ergometer': 'cardio_machine',
}

# -- Movement patterns -------------------------------------------------------
# First match wins, so the list runs most-specific first. Order is load-bearing:
# `stretch` must precede `squat` or "lying quads stretch" becomes a squat, and
# `leg_iso` must precede `hinge`/`squat` or a leg extension becomes a main lift.
PATTERN_RULES = [
    ('stretch', [r'stretch', r'\bpose\b', r'\byoga\b', r'mobility', r'foam roll',
                 r'\bsplits\b', r'\bcat\b.*\bcow\b']),
    ('cardio', [r'\brun\b', r'treadmill', r'cycle', r'\bbike\b', r'elliptical', r'stepmill',
                r'ski erg', r'skierg', r'ergometer', r'rowing machine', r'jump rope',
                r'jumping jack', r'mountain climber', r'burpee', r'\bstair',
                r'battling rope', r'battle rope']),
    ('plyo', [r'\bjump\b', r'\bjumping\b', r'\bhop\b', r'\bbound\b', r'\bslam\b', r'\bthrow\b',
              r'\btoss\b', r'plyo', r'\bskater\b', r'\bexplosive\b', r'\bsprint\b']),
    ('carry', [r'farmers walk', r'\bcarry\b', r'suitcase', r'waiter walk', r'overhead walk']),
    # Must beat `hinge`: "hanging leg-hip raise" and "side bridge" are abdominal
    # work, and letting `hip raise` / `bridge` claim them would put a hanging leg
    # raise in the main hip-hinge slot of a leg day.
    ('core', [r'\bhanging\b', r'side bridge', r'leg[- ]hip raise',
              r'(leg|knee|hip) raise.*\bhanging\b']),
    ('leg_iso', [r'leg extension', r'leg curl', r'\bfemoral\b', r'hip abduction', r'hip adduction',
                 r'hip abductor', r'hip adductor', r'outer thigh', r'inner thigh',
                 r'thigh adductor', r'hip extension', r'glute kickback', r'donkey kick',
                 r'\bhip abduct', r'\bhip adduct']),
    ('hinge', [r'deadlift', r'good morning', r'hip thrust', r'glute bridge', r'romanian',
               r'hyperextension', r'back extension', r'\bswing\b', r'pull through', r'\bclean\b',
               r'snatch', r'high pull', r'rack pull', r'glute[- ]ham', r'hip lift',
               r'hip raise', r'\bbridge\b']),
    ('squat', [r'\bsquat\b', r'leg press', r'\bhack\b', r'sissy', r'wall sit']),
    ('lunge', [r'lunge', r'split squat', r'step[- ]?up', r'bulgarian']),
    ('vertical_pull', [r'pull[- ]?up', r'chin[- ]?up', r'pulldown', r'pull[- ]?down', r'pullover',
                       r'lat pull', r'muscle up', r'climb', r'sternum chin']),
    ('horizontal_pull', [r'\brow\b', r'\brows\b', r'rowing', r'face pull', r'rear delt',
                         r'reverse fly', r'reverse flye', r'inverted row', r'\bshrug\b',
                         r'\bt[- ]raise\b', r'\by[- ]raise\b', r'\barcher\b']),
    ('vertical_push', [r'shoulder press', r'overhead press', r'military press', r'arnold press',
                       r'push press', r'handstand', r'\bjerk\b', r'landmine press',
                       r'\bz press\b', r'thruster', r'behind[- ](the[- ])?(neck|head) press']),
    ('horizontal_push', [r'bench press', r'chest press', r'push[- ]?up', r'\bdip\b', r'\bdips\b',
                         r'\bfly\b', r'\bflye\b', r'pec deck', r'floor press', r'cross[- ]?over',
                         r'crossover', r'\bpress\b']),
    ('core', [r'crunch', r'sit[- ]?up', r'plank', r'leg raise', r'knee raise',
              r'russian twist', r'woodchop', r'wood chop', r'roll[- ]?out', r'roller ?out',
              r'hollow', r'dead bug', r'\bab\b', r'oblique', r'side bend', r'bicycle',
              r'v[- ]?up', r'toe touch', r'heel touch', r'dragon flag', r'l[- ]?sit', r'twist',
              r'bird dog', r'pallof', r'windshield', r'\bhanging\b', r'side bridge',
              r'\blever\b.*\bflag\b', r'front lever', r'back lever', r'skin the cat']),
    ('calf', [r'calf raise', r'\bcalf\b', r'toe press', r'tibialis']),
    ('arm_biceps', [r'curl']),
    ('arm_triceps', [r'pushdown', r'push[- ]?down', r'kickback', r'skull', r'triceps extension',
                     r'french press', r'triceps']),
    ('shoulder_iso', [r'lateral raise', r'side raise', r'front raise', r'upright row',
                      r'external rotation', r'internal rotation', r'\braise\b.*delt',
                      r'forward raise', r'shoulder raise', r'incline raise', r'\bskier\b']),
    ('neck', [r'\bneck\b']),
    ('grip', [r'wrist', r'\bgrip\b', r'finger', r'forearm']),
]
PATTERN_RULES = [(k, [re.compile(p) for p in ps]) for k, ps in PATTERN_RULES]

# Fallback when the name gives nothing away: infer from the target muscle.
# Deliberately never yields a compound pattern -- an unrecognised name is far more
# likely to be an odd isolation movement than a main lift, and wrongly promoting one
# into a plan's anchor slot is the worst failure mode here.
TARGET_PATTERN = {
    'abs': 'core', 'spine': 'core', 'serratus anterior': 'core',
    'pectorals': 'chest_iso', 'lats': 'back_iso', 'upper back': 'back_iso',
    'traps': 'back_iso', 'biceps': 'arm_biceps', 'triceps': 'arm_triceps',
    'delts': 'shoulder_iso', 'quads': 'leg_iso', 'hamstrings': 'leg_iso',
    'glutes': 'leg_iso', 'adductors': 'leg_iso', 'abductors': 'leg_iso',
    'calves': 'calf', 'forearms': 'grip', 'cardiovascular system': 'cardio',
    'levator scapulae': 'neck',
}

COMPOUND_PATTERNS = {'squat', 'hinge', 'lunge', 'vertical_pull', 'horizontal_pull',
                     'vertical_push', 'horizontal_push'}
ISOLATION_PATTERNS = {'arm_biceps', 'arm_triceps', 'shoulder_iso', 'calf', 'grip', 'neck',
                      'leg_iso', 'chest_iso', 'back_iso'}
# Lower-body targets that mean an "isolation-shaped" name was really a machine accessory.
LEG_TARGETS = {'quads', 'hamstrings', 'glutes', 'adductors', 'abductors'}

# -- Difficulty --------------------------------------------------------------
# Fixed-path machines forgive bad form; free weights demand stabilisation;
# odd objects and Olympic derivatives demand real technique.
EQUIP_SCORE = {
    'machine': -1, 'cardio_machine': -1, 'cable': 0, 'band': 0, 'bodyweight': 0,
    'dumbbell': 0, 'ball': 1, 'kettlebell': 1, 'barbell': 1, 'other': 2,
}

HARD_NAME = [
    (3, [r'snatch', r'\bclean\b', r'\bjerk\b', r'muscle up', r'planche', r'front lever',
         r'back lever', r'human flag', r'iron cross', r'dragon flag', r'pistol',
         r'handstand', r'depth jump', r'olympic', r'turkish']),
    (2, [r'single[- ]leg', r'one[- ]leg', r'behind[- ](the[- ])?(neck|head)',
         r'overhead squat', r'front squat', r'deficit', r'good morning', r'bulgarian',
         r'\bl[- ]sit\b', r'windmill', r'\bring\b', r'suspended', r'bosu',
         r'stability ball', r'kipping', r'\bskater\b', r'sissy']),
    # Skill-based: hard regardless of what (if anything) is loaded. A bodyweight
    # dip is genuinely difficult with no weight at all.
    (1, [r'single[- ]arm', r'one[- ]arm', r'\bdip\b', r'pull[- ]?up', r'chin[- ]?up',
         r'\bpause\b', r'\btempo\b']),
]

# Load-based: these names are only "technical" because of the bar in your hands.
# An air squat and a loaded back squat share a name and nothing else in terms of
# what can go wrong, so the bump only applies to free-weight variants.
LOAD_DEPENDENT_HARD = [re.compile(p) for p in [
    r'deadlift', r'\bsquat\b', r'romanian', r'hip thrust', r'push press',
    r'decline', r'\bswing\b',
]]
FREE_WEIGHT_CLASSES = {'barbell', 'dumbbell', 'kettlebell', 'ball', 'other'}
EASY_NAME = [
    (-2, [r'assisted', r'\bmachine\b', r'\blever\b', r'smith', r'\bwall\b', r'knee push',
          r'\bsupported\b', r'\bband\b']),
    (-1, [r'\bseated\b', r'\blying\b', r'incline push', r'\bkneeling\b', r'\bfloor\b',
          r'\bstatic\b', r'\bisometric\b', r'\bhold\b']),
]
HARD_NAME = [(w, [re.compile(p) for p in ps]) for w, ps in HARD_NAME]
EASY_NAME = [(w, [re.compile(p) for p in ps]) for w, ps in EASY_NAME]

# Some movements carry a technique or joint-position risk that no amount of machine
# assistance cancels out. A guided path does not make a behind-the-neck press a
# sensible first shoulder exercise, so these get a hard floor after scoring.
DIFFICULTY_FLOOR = [
    (2, [r'snatch', r'\bclean\b', r'\bjerk\b', r'muscle up',
         r'planche', r'front lever', r'back lever', r'human flag', r'iron cross',
         r'dragon flag', r'pistol', r'handstand', r'olympic', r'turkish', r'kipping']),
    (1, [r'good morning', r'upright row', r'\bdeficit\b', r'overhead squat',
         r'\bplyo', r'depth jump', r'sissy']),
]
DIFFICULTY_FLOOR = [(lvl, [re.compile(p) for p in ps]) for lvl, ps in DIFFICULTY_FLOOR]

BEHIND_NECK = re.compile(r'behind[- ](the[- ])?(neck|head)')

# -- Training at home --------------------------------------------------------
# The home page answers a different question from the library. Not "what
# exercises exist" but "what can I do in a flat, right now" -- and that depends
# on what a movement *needs*, which the source data never records. It records
# only the piece of kit the demonstrator happened to be standing next to.
#
# A floor and a wall are assumed. Everything beyond that is optional and named,
# so the app can hide what the user has no way of doing.
HOME_EQUIPMENT = {'body weight', 'weighted', 'dumbbell', 'band', 'resistance band'}

# Kit that does not fit in a flat. These hide *inside* otherwise-bodyweight
# names -- "Chest Dip (on Dip-Pull-Up Cage)" is filed under body weight -- so
# the equipment field alone lets a dozen gym-only movements through.
#
# "peacher" is not a typo here: it is a typo in the source, and a preacher curl
# needs a preacher bench however it is spelled.
HOME_DENY = re.compile(
    r'exercise ball|stability ball|bosu|tennis ball|medicine ball|\bcage\b|cable|'
    r'machine|captains chair|parallel bars|\brings?\b|suspended|platform slide|'
    r'\bsled\b|preacher|peacher|\bsmith\b|wheel roller|rollerout|\btire\b|battling|'
    r'glute[- ]?ham|hyperextension|balance board|arm blaster|\bmaltese\b')

# Something to hang from. A doorway bar counts, and so does anything the body
# can go under -- an inverted row wants a low bar or the edge of a table.
HOME_BAR = re.compile(
    r'pull[- ]?up|chin[- ]?up|muscle[- ]?up|\bhanging\b|\bhang\b|inverted row|'
    r'front lever|back lever|skin the cat|straight bar|\bbar dip\b|vertical bar')

# Something to sit on, press off, or put a foot on: a bench, a chair, a sofa, a
# stair. Dips belong here -- without a bar, two chairs is how they get done.
HOME_BENCH = re.compile(
    r'\bbench\b|\bbox\b|step[- ]?up|\bchair\b|\bincline\b|\bdecline\b|'
    r'elevated|\bdips?\b')


# The instructions are better evidence than the name, and they are right there.
# "Gorilla Chin" says nothing; its first step says "grip a high bar". "Monster
# Walk" reads as bodyweight until step one puts a band around your ankles.
STEP_DENY = re.compile(
    r'\brings\b|vertical pole|balance board|\bab wheel\b|on the wheel|'
    r'smith machine|cable machine|roman chair|glute[- ]?ham|suspension trainer')
STEP_BAR = re.compile(
    r'pull[- ]?up bar|chin[- ]?up bar|high bar|horizontal bar|sturdy bar|'
    r'overhead bar|hang(?:ing)? from (?:a|the) bar')
STEP_BENCH = re.compile(
    r'on a bench|on the bench|raised surface|elevated surface|sturdy chair')
STEP_BAND = re.compile(r'(?:place|wrap|loop|attach) a resistance band')


def home_gear(name, equipment, equip_class, steps):
    """What this movement needs at home, or None if it cannot be done there.

    An empty list means a floor and nothing else, which is the case the whole
    page is built around.
    """
    if equipment not in HOME_EQUIPMENT:
        return None
    n = name.lower()
    text = ' '.join(steps).lower()
    if HOME_DENY.search(n) or STEP_DENY.search(text):
        return None
    gear = []
    # "weighted" is the dataset's word for "hold something heavy while you do
    # this", and at home the something is a dumbbell.
    if equip_class == 'dumbbell' or equipment == 'weighted':
        gear.append('dumbbell')
    if equip_class == 'band':
        gear.append('band')
    elif STEP_BAND.search(text):
        gear.append('band')
    if HOME_BAR.search(n):
        gear.append('pullup_bar')
    # Only for movements that ask for nothing else. A band pulldown mentions a
    # bar because that is what the band is anchored to, and demanding a doorway
    # bar for it would hide it from the people it is for.
    elif not gear and STEP_BAR.search(text):
        gear.append('pullup_bar')
    # A bar movement is not also a bench movement unless the name says so, or
    # every pull-up and dip would demand both and show to nobody.
    if HOME_BENCH.search(n) and ('bench' in n or not HOME_BAR.search(n)):
        gear.append('bench')
    elif 'bench' not in gear and STEP_BENCH.search(text):
        gear.append('bench')
    return gear


UNILATERAL = re.compile(r'single[- ]arm|one[- ]arm|single[- ]leg|one[- ]leg|alternat|'
                        r'unilateral|split squat|bulgarian|step[- ]?up|lunge|'
                        r'concentration curl|kickback')

KEEP_UPPER = {'ez', 'iii', 'ii', 'iv'}
SMALL = {'to', 'with', 'and', 'on', 'the', 'of', 'in', 'a', 'for', 'per', 'from'}


# A handful of source names carry mojibake from a bad round-trip ("45в°" for "45°").
MOJIBAKE = {'в°': '°', 'Ð°': 'a'}


def clean_name(name):
    for bad, good in MOJIBAKE.items():
        name = name.replace(bad, good)
    return re.sub(r'\s+', ' ', name).strip()


def _cap(word):
    """Upper-case the first letter, skipping leading punctuation like "(parallel"."""
    for i, ch in enumerate(word):
        if ch.isalpha():
            return word[:i] + word[i].upper() + word[i + 1:]
    return word


def title_name(name):
    parts = name.split(' ')
    out = []
    for i, w in enumerate(parts):
        lw = w.strip('()').lower()
        if lw in KEEP_UPPER:
            out.append(w.replace(lw, 'EZ' if lw == 'ez' else lw.upper()))
        elif i > 0 and lw in SMALL:
            out.append(w.lower())
        elif '-' in w and len(w) > 2:
            out.append('-'.join(_cap(s) for s in w.split('-')))
        else:
            out.append(_cap(w))
    return ' '.join(out)


# The source instructions end almost every exercise with a line telling you to
# repeat for the desired number of repetitions. The app already prescribes the
# reps two inches above, so that line is 892 instances of pure filler. The
# variants that name a side carry real information, so they are kept -- shortened.
DROP_STEP = re.compile(
    r'^repeat (for|until) (the )?desired (number of )?(repetitions|reps)\.?$', re.I)
SWITCH_STEP = re.compile(
    r'^repeat for the desired number of repetitions,?\s*(?:and\s+)?then (.+)\.$', re.I)
ALTERNATE_STEP = re.compile(
    r'^continue alternating (\w+) for the desired number of repetitions\.$', re.I)


def clean_steps(steps):
    out = []
    for step in steps:
        text = step.strip()
        if DROP_STEP.match(text):
            continue
        m = SWITCH_STEP.match(text)
        if m:
            out.append(m.group(1).strip().capitalize() + '.')
            continue
        m = ALTERNATE_STEP.match(text)
        if m:
            out.append('Keep alternating %s.' % m.group(1).lower())
            continue
        # Tidy the phrase wherever else it appears mid-list.
        text = re.sub(r'for the desired number of (repetitions|reps)',
                      'for your target reps', text, flags=re.I)
        out.append(text)
    # Never return nothing: an exercise with no instructions is worse than one
    # with a redundant final line.
    return out or [s.strip() for s in steps]


def classify_pattern(name, target):
    n = name.lower()
    for key, regs in PATTERN_RULES:
        if any(r.search(n) for r in regs):
            # A "kickback" on glutes is a leg accessory, not a triceps movement.
            if key == 'arm_triceps' and target in LEG_TARGETS:
                return 'leg_iso'
            return key
    return TARGET_PATTERN.get(target, 'isolation')


def score_difficulty(name, equip_class, pattern):
    n = name.lower()
    # Stretches carry no load and no skill barrier -- always safe to prescribe.
    if pattern == 'stretch':
        return 0
    score = EQUIP_SCORE.get(equip_class, 0)
    # Plyometrics land at speed; never surface them to someone in their first weeks.
    if pattern == 'plyo':
        score += 2
    for w, regs in HARD_NAME:
        if any(r.search(n) for r in regs):
            score += w
            break
    else:
        # Only reached when no skill-based rule matched, so the two never stack.
        if equip_class in FREE_WEIGHT_CLASSES and \
                any(r.search(n) for r in LOAD_DEPENDENT_HARD):
            score += 1
    for w, regs in EASY_NAME:
        if any(r.search(n) for r in regs):
            score += w
            break
    if pattern in COMPOUND_PATTERNS:
        score += 1
    if pattern in ISOLATION_PATTERNS:
        score -= 1
    # Calibrated so a bodyweight lunge lands beginner, a barbell back squat lands
    # intermediate, and only genuinely technical lifts reach advanced.
    if score <= 1:
        level = 0
    elif score <= 3:
        level = 1
    else:
        level = 2
    # Loading a bar behind the neck puts the shoulder in its most vulnerable position,
    # whether the path is guided or not.
    if pattern in ('vertical_push', 'vertical_pull') and BEHIND_NECK.search(n):
        level = max(level, 2)
    for floor, regs in DIFFICULTY_FLOOR:
        if any(r.search(n) for r in regs):
            return max(level, floor)
    return level


def main():
    with open(SRC, encoding='utf-8') as f:
        raw = json.load(f)

    out = []
    for e in raw:
        equip_class = EQUIP_CLASS.get(e['equipment'], 'other')
        name = clean_name(e['name'])
        pattern = classify_pattern(name, e['target'])
        secondary = [m for m in dict.fromkeys(e['secondary_muscles']) if m != e['target']]
        out.append({
            'id': e['id'],
            'name': title_name(name),
            'bodyPart': e['body_part'],
            'equipment': e['equipment'],
            'equipClass': equip_class,
            'target': e['target'],
            'secondary': secondary,
            'pattern': pattern,
            'difficulty': score_difficulty(name, equip_class, pattern),
            'compound': pattern in COMPOUND_PATTERNS,
            'unilateral': bool(UNILATERAL.search(name.lower())),
            'steps': clean_steps(e['instruction_steps']['en']),
        })
        gear = home_gear(name, e['equipment'], equip_class, out[-1]['steps'])
        # Absent rather than null for everything that needs a gym: the key only
        # exists when it has something to say.
        if gear is not None:
            out[-1]['home'] = gear

    out.sort(key=lambda x: x['id'])
    path = os.path.join(OUT_DIR, 'exercises.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))

    print('wrote %s  %.2f MB  (%d exercises)' % (path, os.path.getsize(path) / 1e6, len(out)))
    for field in ('pattern', 'difficulty', 'equipClass'):
        c = collections.Counter(x[field] for x in out)
        print('\n%s:' % field)
        for k, v in c.most_common():
            print('   %s: %s' % (k, v))
    home = [x for x in out if 'home' in x]
    print('\nhome-suitable: %d' % len(home))
    print('   floor only:      %d' % sum(1 for x in home if not x['home']))
    for key in ('dumbbell', 'pullup_bar', 'bench', 'band'):
        print('   needs %-10s %d' % (key + ':', sum(1 for x in home if key in x['home'])))
    print('\nhome movements per body part:')
    for k, v in collections.Counter(x['bodyPart'] for x in home).most_common():
        floor = sum(1 for x in home if x['bodyPart'] == k and not x['home'])
        print('   %-12s %3d  (%d need no kit at all)' % (k, v, floor))

    print('\ncompound: %d   unilateral: %d'
          % (sum(x['compound'] for x in out), sum(x['unilateral'] for x in out)))

    # A plan for a true beginner is only as good as the beginner-compound pool it draws from.
    print('\nbeginner compounds available per pattern:')
    pool = collections.Counter(x['pattern'] for x in out if x['difficulty'] == 0 and x['compound'])
    for k, v in pool.most_common():
        print('   %s: %s' % (k, v))
    print('\nsample beginner compounds:')
    seen = set()
    for x in out:
        if x['difficulty'] == 0 and x['compound'] and x['pattern'] not in seen:
            seen.add(x['pattern'])
            print('   %-18s %s (%s)' % (x['pattern'], x['name'], x['equipment']))


if __name__ == '__main__':
    main()
