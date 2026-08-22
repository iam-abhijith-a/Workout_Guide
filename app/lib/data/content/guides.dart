import 'package:flutter/painting.dart';

import '../../core/theme/tokens.dart';
import '../../ui/widgets/media.dart';

/// Beginner guides.
///
/// The gap this fills is not "how do I do a squat" -- the library covers that.
/// It is everything nobody writes down: what actually happens when you walk in,
/// how to pick a weight when you have no idea, why your legs hurt two days
/// later, and whether any of this is normal. Written plainly, with no jargon
/// that is not immediately defined.
class Guide {
  const Guide({
    required this.id,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.icon,
    required this.tone,
    required this.sections,
    this.tag = 'Basics',
  });

  final String id;
  final String title;

  /// One line. A summary that needs two is a title that has not been decided on.
  final String summary;
  final int minutes;

  /// Icon and tint, so a list of nine guides is scannable by shape and colour
  /// rather than by reading nine titles.
  final FIconData icon;
  final Color tone;

  final String tag;
  final List<GuideSection> sections;
}

class GuideSection {
  const GuideSection({required this.heading, required this.body, this.callout});

  final String heading;
  final List<String> body;

  /// The one thing to take away, pulled out of the prose.
  final String? callout;
}

const guides = <Guide>[
  Guide(
    id: 'first-session',
    icon: FIcons.sparkle,
    tone: FColors.indigo,
    title: 'Your very first session',
    summary: 'What actually happens when you walk in.',
    minutes: 5,
    tag: 'Start here',
    sections: [
      GuideSection(
        heading: 'Nobody is looking at you',
        body: [
          'This is the single biggest thing stopping people from starting, so '
              'it goes first. Everyone in a gym is thinking about their own '
              'set, their own playlist, or their own reflection. The regulars '
              'were all beginners once and most of them remember it clearly.',
          'If someone does notice you, it is almost always because they want to '
              'know if you are finished with the equipment.',
        ],
        callout:
            'Turn up, do your sets, leave. That is the whole social '
            'contract.',
      ),
      GuideSection(
        heading: 'What to bring',
        body: [
          'Trainers with a flat, firm sole. Running shoes with thick squashy '
              'heels make squatting and deadlifting feel unstable — anything '
              'flatter is better.',
          'Clothes you can move in, a water bottle, and a towel if your gym '
              'asks you to wipe equipment down.',
          'Your phone, with this app open. The plan is on your Today screen and '
              'it works with no signal.',
        ],
      ),
      GuideSection(
        heading: 'Picking your first weight',
        body: [
          'Start lighter than you think. On your first set, pick something you '
              'could lift about four more times than the plan asks for. If the '
              'plan says 10 reps, use a weight you could manage roughly 14 with.',
          'That will feel too easy. It is meant to. The first two weeks are for '
              'learning the movement, and you cannot learn a movement while '
              'straining.',
          'Log what you used. Next session the app fills it in for you, and you '
              'add a little.',
        ],
        callout:
            'Too light for two weeks costs you nothing. Too heavy on day '
            'one can cost you a month.',
      ),
      GuideSection(
        heading: 'How to use a machine you have never seen',
        body: [
          'Almost every machine has a diagram on the frame. It is worth thirty '
              'seconds of reading.',
          'Set the seat so that the part of the machine that pivots lines up '
              'with the joint that bends. For a chest press that means the '
              'handles roughly at armpit height; for a leg extension, the pad '
              'just above your ankle.',
          'Do one very light set to feel the path before you load it properly.',
        ],
      ),
      GuideSection(
        heading: 'Gym etiquette in four lines',
        body: [
          'Put the weights back where you found them.',
          'Do not sit on a machine scrolling between sets — either rest '
              'standing nearby or let someone work in.',
          'Ask "how many sets have you got left?" rather than hovering.',
          'Wipe the bench down if you sweat on it.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'sets-reps-rest',
    icon: FIcons.timer,
    tone: FColors.blue,
    title: 'Sets, reps and rest',
    summary: 'The three numbers on every line.',
    minutes: 4,
    sections: [
      GuideSection(
        heading: 'A rep is one repetition',
        body: [
          'One full movement — lower the weight, lift it back. Ten reps is ten '
              'of those without stopping.',
          'A set is a group of reps. "3 × 10" means three sets of ten reps, '
              'with a rest between each.',
        ],
      ),
      GuideSection(
        heading: 'What the rep number changes',
        body: [
          'Low reps with heavy weight (about 4 to 6) build maximum strength.',
          'Medium reps (about 8 to 12) build the most muscle for most people, '
              'which is why they turn up most often.',
          'High reps with lighter weight (15 or more) build endurance, and are '
              'kinder to your joints while you are learning.',
          'All three build muscle. The differences are smaller than the '
              'internet suggests. Consistency matters far more than the number.',
        ],
      ),
      GuideSection(
        heading: 'Rest is not optional',
        body: [
          'Rest lets the muscle recover enough to make the next set count. Cut '
              'it short and every set after the first is weaker, so you do less '
              'work overall.',
          'Roughly: 2 to 3 minutes after heavy compound lifts, 60 to 90 seconds '
              'after moderate work, 45 to 60 seconds after isolation exercises.',
          'The app times this for you and starts the clock the moment you log a '
              'set.',
        ],
        callout:
            'Resting properly is not laziness — it is what makes the next '
            'set worth doing.',
      ),
      GuideSection(
        heading: 'How hard should a set feel?',
        body: [
          'Aim to finish each set with about two reps left in you. If you could '
              'have done five more, go heavier next time. If you could not have '
              'done another one, go lighter.',
          'You do not need to train to complete failure. It makes you much more '
              'tired without making you much stronger, and form falls apart '
              'exactly when it matters most.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'progressive-overload',
    icon: FIcons.chart,
    tone: FColors.emerald,
    title: 'How you get stronger',
    summary: 'The principle behind every plan.',
    minutes: 3,
    sections: [
      GuideSection(
        heading: 'Do a little more than last time',
        body: [
          'That is it. That is the whole principle, and it is called '
              'progressive overload.',
          'Your body adapts to what you repeatedly ask of it. Ask for the same '
              'thing forever and it has no reason to change.',
        ],
      ),
      GuideSection(
        heading: 'More can mean several things',
        body: [
          'More weight — the obvious one, and the slowest.',
          'More reps at the same weight. Going from 8 to 10 reps is real '
              'progress.',
          'More sets, up to a point.',
          'Better form, or a slower lowering phase, at the same weight. This '
              'counts, and it is usually where beginners improve fastest.',
        ],
        callout:
            'Add reps until you reach the top of the range, then add '
            'weight and drop back to the bottom. Repeat forever.',
      ),
      GuideSection(
        heading: 'It will not be linear',
        body: [
          'For the first few months you may add weight almost every session. '
              'That stops, and it is not a sign anything is wrong.',
          'Sleep, food and stress affect a session more than motivation does. A '
              'bad day in the gym usually happened the night before.',
          'Do not chase a number on a bad day. Log what you actually did and '
              'come back.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'form-first',
    icon: FIcons.target,
    tone: FColors.violet,
    title: 'Form before weight',
    summary: 'How to tell you are doing it right.',
    minutes: 4,
    sections: [
      GuideSection(
        heading: 'Form is just efficiency',
        body: [
          'Good form means the muscle you are trying to work is doing the work, '
              'and your joints are in positions they are built for.',
          'Bad form usually means something else has taken over — momentum, '
              'your lower back, the wrong muscle entirely.',
        ],
      ),
      GuideSection(
        heading: 'Film yourself',
        body: [
          'Prop your phone against a water bottle and record one set from the '
              'side. Ten seconds of video will teach you more than an hour of '
              'guessing.',
          'Compare it with the animation on the exercise page. You are looking '
              'for the same shape, not the same speed.',
        ],
        callout:
            'Everyone thinks their form is better than the video shows. '
            'That is normal, and it is why the video helps.',
      ),
      GuideSection(
        heading: 'The universal warning signs',
        body: [
          'Your back rounds under load. Stop the set.',
          'You need to swing or bounce to complete a rep. Too heavy.',
          'A joint hurts, as opposed to a muscle burning. Stop, and pick a '
              'different exercise for that pattern.',
          'You cannot control the weight on the way down. Too heavy.',
        ],
      ),
      GuideSection(
        heading: 'Muscle burn versus joint pain',
        body: [
          'A working muscle feels like a deep, spreading burn that fades within '
              'a minute of stopping. That is the sensation you are after.',
          'A joint problem feels sharp, pinching, or localised to one point, '
              'and it does not fade. That one is a signal to stop.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'soreness',
    icon: FIcons.alert,
    tone: FColors.amber,
    title: 'Soreness and recovery',
    summary: 'Why you hurt two days later.',
    minutes: 3,
    sections: [
      GuideSection(
        heading: 'Delayed soreness is normal',
        body: [
          'Stiffness that peaks a day or two after training has a name: delayed '
              'onset muscle soreness. It is most severe after your first few '
              'sessions and after anything new.',
          'It fades as you get used to training. Within a month or so, most '
              'sessions will not leave you sore at all.',
        ],
      ),
      GuideSection(
        heading: 'Sore does not mean effective',
        body: [
          'Soreness measures novelty, not quality. A session that leaves you '
              'wrecked is not automatically better than one that does not.',
          'Judge a session by whether you did the work you planned, not by how '
              'you feel the next day.',
        ],
        callout: 'Chasing soreness is chasing the wrong thing.',
      ),
      GuideSection(
        heading: 'What actually helps recovery',
        body: [
          'Sleep. Seven to nine hours does more for your training than any '
              'supplement on the shelf.',
          'Enough protein — roughly 1.6 grams per kilogram of body weight per '
              'day is a well-supported target.',
          'Light movement on rest days: a walk, easy cycling, some stretching.',
          'Rest days themselves. Your plan has them for a reason.',
        ],
      ),
      GuideSection(
        heading: 'Train sore, or rest?',
        body: [
          'Mildly sore is fine to train through, and often feels better once '
              'you are warmed up.',
          'Properly sore — struggling on stairs, cannot straighten your arm — '
              'means train something else or take the day.',
          'Actual pain is never something to train through.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'warm-up',
    icon: FIcons.flame,
    tone: FColors.orange,
    title: 'Warming up properly',
    summary: 'Five minutes, well spent.',
    minutes: 3,
    sections: [
      GuideSection(
        heading: 'What a warm-up is for',
        body: [
          'Raising your body temperature, getting blood into the muscles you '
              'are about to use, and rehearsing the movement so your first '
              'working set is not also your first attempt.',
          'It is not for stretching. Long static stretches before lifting '
              'temporarily reduce your strength — save those for afterwards.',
        ],
      ),
      GuideSection(
        heading: 'The five-minute version',
        body: [
          'Five minutes of easy cardio — bike, rower, brisk walk. You want to '
              'be warm and breathing slightly harder, not tired.',
          'Then, for your first big lift only: one set of about eight reps with '
              'the empty bar or a very light weight, then one set of five with '
              'roughly half your working weight.',
          'Later exercises in the session do not need their own warm-up. You '
              'are already warm.',
        ],
        callout:
            'Warm up by moving, cool down by stretching. Not the other way '
            'round.',
      ),
    ],
  ),

  Guide(
    id: 'jargon',
    icon: FIcons.book,
    tone: FColors.teal,
    title: 'Gym words, translated',
    summary: 'Every bit of jargon, in plain English.',
    minutes: 4,
    tag: 'Reference',
    sections: [
      GuideSection(
        heading: 'The basics',
        body: [
          'Rep — one repetition of a movement.',
          'Set — a group of reps done back to back.',
          'Volume — how much total work you did: sets × reps × weight.',
          'Compound — an exercise that bends more than one joint and uses '
              'several muscles, like a squat or a row.',
          'Isolation — an exercise that bends one joint and targets one muscle, '
              'like a curl.',
        ],
      ),
      GuideSection(
        heading: 'Things people shout',
        body: [
          'PB or PR — personal best or personal record. Your heaviest ever lift '
              'for a given exercise.',
          'AMRAP — as many reps as possible.',
          'Superset — two exercises done back to back with no rest between.',
          'Drop set — finishing a set, immediately reducing the weight, and '
              'continuing.',
          'Working in — sharing a piece of equipment, taking turns between sets.',
        ],
      ),
      GuideSection(
        heading: 'Body parts by nickname',
        body: [
          'Lats — the wide muscles down the sides of your back.',
          'Delts — your shoulders.',
          'Pecs — your chest.',
          'Quads — the front of your thighs.',
          'Hams — the back of your thighs.',
          'Glutes — your backside, and the strongest muscle you own.',
          'Traps — from your neck out to your shoulders.',
        ],
      ),
      GuideSection(
        heading: 'Programme words',
        body: [
          'Split — how you divide the week up. Full body, upper/lower, and '
              'push/pull/legs are the common ones.',
          'Deload — a deliberately lighter week to let you recover.',
          'Progressive overload — gradually doing more over time. The reason '
              'any of this works.',
          'Failure — the point where you physically cannot complete another '
              'rep. You rarely need to go there.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'eating',
    icon: FIcons.info,
    tone: FColors.rose,
    title: 'Eating for your goal',
    summary: 'The short, non-faddy version.',
    minutes: 4,
    tag: 'Beyond the gym',
    sections: [
      GuideSection(
        heading: 'Protein is the one that matters',
        body: [
          'Training breaks muscle down; protein is what rebuilds it. Without '
              'enough, you get most of the fatigue and much less of the result.',
          'Around 1.6 grams per kilogram of body weight per day is a '
              'well-supported target. For a 70kg person that is about 110 grams.',
          'Spread it across your meals rather than eating it all at dinner.',
        ],
        callout: 'If you change one thing about how you eat, make it protein.',
      ),
      GuideSection(
        heading: 'Building muscle versus losing fat',
        body: [
          'To build muscle, you need to eat slightly more than you burn. Not '
              'enormously more — a small surplus is enough, and anything larger '
              'is mostly fat.',
          'To lose fat, you need to eat slightly less than you burn, while '
              'keeping protein high and continuing to lift. That is what tells '
              'your body to keep the muscle.',
          'Doing both at once is realistic mainly for beginners. Happily, that '
              'is you.',
        ],
      ),
      GuideSection(
        heading: 'What to ignore',
        body: [
          'Detoxes, fat burners, and anything promising to target fat in one '
              'specific place. None of it works.',
          'Meal timing beyond broad common sense. There is no anabolic window '
              'you will miss by showering first.',
          'Supplements, with two exceptions worth considering: creatine '
              'monohydrate, which is genuinely well-evidenced, and protein '
              'powder, which is simply a convenient food.',
        ],
      ),
    ],
  ),

  Guide(
    id: 'plateaus',
    icon: FIcons.swap,
    tone: FColors.blue,
    title: 'When progress stops',
    summary: 'What to do when the weight stalls.',
    minutes: 3,
    tag: 'Later on',
    sections: [
      GuideSection(
        heading: 'First, check the boring things',
        body: [
          'Are you sleeping? Are you eating enough? Have you actually been '
              'consistent for the last month, or does it just feel that way?',
          'Most stalls are recovery problems wearing a training costume.',
        ],
      ),
      GuideSection(
        heading: 'Then change one variable',
        body: [
          'Add reps instead of weight. Going from 8 to 12 at the same weight is '
              'progress, and it is often available when adding weight is not.',
          'Add a set to the exercise that has stalled.',
          'Slow the lowering phase down to three seconds. Same weight, '
              'considerably harder.',
          'Swap to a close variation for a month, then come back.',
        ],
        callout:
            'Change one thing at a time, or you will not know what worked.',
      ),
      GuideSection(
        heading: 'Take a lighter week',
        body: [
          'If you have trained hard for two or three months without a break, '
              'try a week at about two thirds of your usual weights.',
          'It feels like going backwards. It very reliably is not — most people '
              'come back stronger.',
        ],
      ),
    ],
  ),
];

Guide? guideById(String id) {
  for (final guide in guides) {
    if (guide.id == id) return guide;
  }
  return null;
}
