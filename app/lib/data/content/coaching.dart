import '../models/exercise.dart';

/// Coaching notes attached to a movement pattern.
///
/// The source dataset gives step-by-step instructions but no judgement: it will
/// happily tell someone to squat without mentioning that their knees caving in is
/// the thing that will hurt them. This fills that gap.
class PatternCoaching {
  const PatternCoaching({
    required this.why,
    required this.cues,
    required this.mistakes,
    required this.beginnerTip,
  });

  /// Why this movement is in the plan at all, in plain language.
  final String why;

  /// Two or three things to think about while the set is happening. Any more and
  /// nobody remembers them mid-rep.
  final List<String> cues;

  /// What actually goes wrong, and what to do instead.
  final List<Mistake> mistakes;

  /// The single most useful thing for someone doing this for the first time.
  final String beginnerTip;
}

class Mistake {
  const Mistake(this.problem, this.fix);
  final String problem;
  final String fix;
}

const _fallback = PatternCoaching(
  why:
      'Accessory work: it targets one muscle directly, so you can add a bit '
      'more for that area without adding much fatigue.',
  cues: [
    'Move slowly enough that you could stop at any point.',
    'Take the muscle through its full range, not just the easy middle.',
  ],
  mistakes: [
    Mistake(
      'Using so much weight that your whole body swings',
      'If other body parts have to help, the target muscle is no longer doing '
          'the work. Drop the weight until only the working joint moves.',
    ),
    Mistake(
      'Cutting the range of motion short',
      'Half reps build strength in half the range. Go all the way down, all the '
          'way up.',
    ),
  ],
  beginnerTip:
      'Pick a weight you could do about four more reps with. That is '
      'the right starting point for week one.',
);

const Map<MovementPattern, PatternCoaching> patternCoaching = {
  MovementPattern.squat: PatternCoaching(
    why:
        'The squat is how you build your whole lower body at once, and it is '
        'the same movement as standing up out of a chair. Get strong here and '
        'daily life gets easier.',
    cues: [
      'Push your knees out in the direction your toes point.',
      'Keep your whole foot planted -- imagine spreading the floor apart.',
      'Chest stays proud; go down as far as you can without your back rounding.',
    ],
    mistakes: [
      Mistake(
        'Knees collapsing inward as you stand up',
        'This is the most common squat fault and the hardest on your knees. '
            'Actively push your knees out on the way up.',
      ),
      Mistake(
        'Heels lifting off the floor',
        'Usually tight ankles. Squat to a box, or raise your heels slightly on '
            'small plates until your ankles loosen up.',
      ),
      Mistake(
        'Lower back rounding at the bottom',
        'You have gone deeper than your hips currently allow. Stop the rep '
            'where your back is still flat -- depth comes with time.',
      ),
    ],
    beginnerTip:
        'Start with just your body weight and film yourself from the '
        'side. You will learn more from ten seconds of video than from ten '
        'minutes of guessing.',
  ),

  MovementPattern.hinge: PatternCoaching(
    why:
        'Hinging is bending at the hips with a flat back -- the safest way to '
        'pick anything up off the floor. It builds the whole back of your body: '
        'glutes, hamstrings and spinal muscles.',
    cues: [
      'Push your hips *back*, do not bend your knees to go down.',
      'Keep the bar or dumbbells dragging close to your legs.',
      'Finish by squeezing your glutes, not by leaning back.',
    ],
    mistakes: [
      Mistake(
        'Rounding your back',
        'The single thing to avoid. Set your back flat before you move and hold '
            'it there. If it rounds, the weight is too heavy or the range too deep.',
      ),
      Mistake(
        'Turning it into a squat',
        'If your knees travel forward and your hips drop, you are squatting. '
            'Knees stay softly bent; hips go backward.',
      ),
      Mistake(
        'Hyperextending at the top',
        'Leaning back at the finish loads your lower spine for no benefit. '
            'Stand tall and stop there.',
      ),
    ],
    beginnerTip:
        'Practise with a broomstick along your back touching your head, '
        'upper back and tailbone. If all three stay in contact, your spine is neutral.',
  ),

  MovementPattern.lunge: PatternCoaching(
    why:
        'One leg at a time exposes the side that is weaker and makes it catch '
        'up. It also trains balance, which is most of what stops people falling '
        'as they age.',
    cues: [
      'Step far enough that your front shin stays close to vertical.',
      'Drop straight down, do not push yourself forward.',
      'Push through your front heel to come back up.',
    ],
    mistakes: [
      Mistake(
        'Wobbling side to side',
        'Normal at first -- it is the balance demand, not weakness. Hold a rail '
            'or wall lightly for the first few sessions.',
      ),
      Mistake(
        'Front knee caving inward',
        'Track your knee over your second toe. Slowing the descent usually '
            'fixes it on its own.',
      ),
      Mistake(
        'Taking too short a step',
        'A short step dumps all the load on your knee. Lengthen the stride so '
            'your hip does more of the work.',
      ),
    ],
    beginnerTip:
        'Split squats -- where your feet stay put -- are much easier to '
        'balance than walking lunges. Start there.',
  ),

  MovementPattern.horizontalPush: PatternCoaching(
    why:
        'Pressing away from your chest builds the chest, front shoulders and '
        'triceps together. It is the most direct way to build upper-body '
        'pushing strength.',
    cues: [
      'Pull your shoulder blades down and together, and keep them there.',
      'Lower under control until you feel a stretch across your chest.',
      'Elbows at roughly 45 degrees from your body, not flared straight out.',
    ],
    mistakes: [
      Mistake(
        'Elbows flared out to 90 degrees',
        'This grinds the front of your shoulder. Tuck them to about 45 degrees.',
      ),
      Mistake(
        'Bouncing the weight off your chest',
        'You lose the hardest part of the rep and risk your ribs. Touch lightly, '
            'pause, then press.',
      ),
      Mistake(
        'Shoulders rolling forward at the top',
        'Keep your shoulder blades pinned back throughout. The bar moves; your '
            'shoulders do not.',
      ),
    ],
    beginnerTip:
        'Machines and dumbbells are far friendlier than a barbell to '
        'start with -- if you get stuck, you can simply put them down.',
  ),

  MovementPattern.verticalPush: PatternCoaching(
    why:
        'Pressing overhead builds shoulders that look and function well, and it '
        'is the honest test of whether your core is holding you together.',
    cues: [
      'Squeeze your glutes and brace your stomach before you press.',
      'Move your head back slightly so the weight travels straight up.',
      'Finish with your biceps beside your ears.',
    ],
    mistakes: [
      Mistake(
        'Arching your lower back to get the weight up',
        'The most common fault. If you have to lean back, the weight is too '
            'heavy. Brace and press straight.',
      ),
      Mistake(
        'Pressing around your head instead of over it',
        'The weight should end up over the middle of your feet. Tilt your head '
            'back out of the way, then bring it through.',
      ),
      Mistake(
        'Going overhead with a shoulder that hurts',
        'Overhead work is unforgiving of an angry shoulder. Press at an incline '
            'instead until it settles.',
      ),
    ],
    beginnerTip:
        'Seated presses with a back support take your lower back out of '
        'the equation, which makes them a much better starting point.',
  ),

  MovementPattern.horizontalPull: PatternCoaching(
    why:
        'Rowing builds the muscles between your shoulder blades. It is the '
        'direct counterweight to sitting at a desk, and it should get at least '
        'as much work as your chest.',
    cues: [
      'Start by pulling your shoulder blade back, then bend the elbow.',
      'Pull toward your belly button, not your chin.',
      'Lower slowly -- the stretch is half the benefit.',
    ],
    mistakes: [
      Mistake(
        'Yanking with your arms only',
        'The back should initiate. Think about driving your elbow behind you '
            'rather than pulling with your hand.',
      ),
      Mistake(
        'Shrugging your shoulders up to your ears',
        'That moves the work to your traps. Keep your shoulders down and pull '
            'back, not up.',
      ),
      Mistake(
        'Using body momentum to swing the weight',
        'A little at the end of a hard set is fine. On every rep, it means the '
            'weight is too heavy.',
      ),
    ],
    beginnerTip:
        'Supported rows -- chest on a bench, or a seated cable row -- '
        'let you learn the pull without also having to hold your torso still.',
  ),

  MovementPattern.verticalPull: PatternCoaching(
    why:
        'Pulling down from overhead is what builds the width of your back. It '
        'is also the movement most beginners are weakest at, which makes it the '
        'one with the most to gain.',
    cues: [
      'Start by pulling your shoulders down away from your ears.',
      'Drive your elbows down toward your hips.',
      'Control the way back up; do not let the weight snatch your arms straight.',
    ],
    mistakes: [
      Mistake(
        'Leaning far back and using your whole body',
        'A slight lean is fine. If your torso swings, reduce the weight so your '
            'back does the work.',
      ),
      Mistake(
        'Pulling the bar behind your neck',
        'This forces your shoulder into its most vulnerable position for no '
            'extra benefit. Always pull to your collarbone in front.',
      ),
      Mistake(
        'Gripping so wide it shortens the range',
        'Just outside shoulder width is plenty and lets you pull further.',
      ),
    ],
    beginnerTip:
        'Cannot do a pull-up yet? Almost nobody can at the start. Use '
        'the assisted machine or a lat pulldown and build up.',
  ),

  MovementPattern.core: PatternCoaching(
    why:
        'Your core\'s real job is to stop your spine moving while your arms and '
        'legs do. That is why holds and anti-rotation work carry over to '
        'everything else more than endless sit-ups.',
    cues: [
      'Breathe normally -- if you cannot, the position is too hard.',
      'Ribs down, pelvis slightly tucked, so your lower back does not sag.',
      'Quality over reps: stop when the position breaks down.',
    ],
    mistakes: [
      Mistake(
        'Letting your hips sag in a plank',
        'Your lower back takes the load instead of your abs. Squeeze your '
            'glutes and stop the set when the sag starts.',
      ),
      Mistake(
        'Pulling on your neck during crunches',
        'Rest your hands lightly behind your head and lead with your chest, not '
            'your chin.',
      ),
      Mistake(
        'Chasing very high rep numbers',
        'Once you can hold a plank for a minute, add difficulty rather than time.',
      ),
    ],
    beginnerTip:
        'Visible abs come from body fat, not from ab work. Train your '
        'core for strength; the look comes from the kitchen.',
  ),

  MovementPattern.legIso: PatternCoaching(
    why:
        'Single-joint leg work lets you target one muscle -- quads, hamstrings '
        'or glutes -- without the fatigue of a heavy squat. Useful for adding '
        'volume and for evening out weak spots.',
    cues: [
      'Match the machine\'s pivot to your joint before you start.',
      'Pause briefly where the muscle is most contracted.',
      'Lower over about three seconds.',
    ],
    mistakes: [
      Mistake(
        'Setting the machine up wrong',
        'If the pad is in the wrong place, the load lands on your joint instead '
            'of the muscle. Take the ten seconds to adjust it.',
      ),
      Mistake(
        'Slamming the weight stack at the bottom',
        'You lose tension and you announce it to everyone. Control it down.',
      ),
    ],
    beginnerTip:
        'These are the friendliest machines in the gym for learning what '
        'a muscle working actually feels like.',
  ),

  MovementPattern.armBiceps: PatternCoaching(
    why:
        'Curls train the biceps directly. Your biceps already work in every '
        'pulling movement, so this is a finisher, not a foundation.',
    cues: [
      'Keep your elbows pinned at your sides.',
      'Turn your palm up as you curl for a stronger contraction.',
      'Lower for three seconds; that is where most of the growth happens.',
    ],
    mistakes: [
      Mistake(
        'Swinging the weight up with your back',
        'The classic. If your torso moves, drop the weight by a third.',
      ),
      Mistake(
        'Elbows drifting forward',
        'That turns it into a front raise. Elbows stay put; only your forearm '
            'moves.',
      ),
    ],
    beginnerTip:
        'Two or three sets at the end of an upper-body day is plenty. '
        'Arms grow from your rows and presses more than from curls.',
  ),

  MovementPattern.armTriceps: PatternCoaching(
    why:
        'Triceps are about two thirds of your upper arm, so training them '
        'directly does more for arm size than curls do.',
    cues: [
      'Keep your upper arm still; only your forearm moves.',
      'Straighten fully and squeeze at the end.',
      'Keep your wrists straight, not bent back.',
    ],
    mistakes: [
      Mistake(
        'Elbows flaring out on pushdowns',
        'Keep them tucked at your ribs or your chest and shoulders take over.',
      ),
      Mistake(
        'Locking out aggressively with heavy weight',
        'Elbows do not enjoy being snapped straight. Finish firmly, not violently.',
      ),
    ],
    beginnerTip:
        'If your elbows ache during overhead extensions, switch to '
        'pushdowns -- same muscle, much less joint stress.',
  ),

  MovementPattern.shoulderIso: PatternCoaching(
    why:
        'Raises train the side and rear of your shoulder, which pressing alone '
        'never fully reaches. This is what makes shoulders look broad.',
    cues: [
      'Lead with your elbow, not your hand.',
      'Stop at shoulder height -- higher just brings your traps in.',
      'Very light weight, very strict form.',
    ],
    mistakes: [
      Mistake(
        'Going far too heavy',
        'This is the most over-weighted exercise in any gym. Genuinely light '
            'dumbbells, done strictly, work better.',
      ),
      Mistake(
        'Shrugging as you lift',
        'Keep your shoulders down. If they rise, the weight is too heavy.',
      ),
    ],
    beginnerTip:
        'Rear-delt work is the most skipped and the most useful for '
        'posture. Do not leave it out.',
  ),

  MovementPattern.calf: PatternCoaching(
    why:
        'Calves take you through every step you walk, so they need a full '
        'stretch and a hard squeeze to respond at all.',
    cues: [
      'Drop your heel as far below the step as you can.',
      'Pause a beat at the top and at the bottom.',
      'Higher reps work better here than heavy singles.',
    ],
    mistakes: [
      Mistake(
        'Bouncing rapidly through a tiny range',
        'That uses the tendon\'s springiness instead of the muscle. Slow down '
            'and use the full range.',
      ),
    ],
    beginnerTip:
        'Calves respond to frequency. Two or three short sessions a '
        'week beats one long one.',
  ),

  MovementPattern.cardio: PatternCoaching(
    why:
        'Cardio trains your heart and your recovery between sets. It also means '
        'a flight of stairs stops being an event.',
    cues: [
      'You should be able to speak in short sentences, not sing.',
      'Start easier than you think; you can always add later.',
    ],
    mistakes: [
      Mistake(
        'Going all-out every session',
        'Most of your cardio should be comfortable. Hard intervals are the '
            'seasoning, not the meal.',
      ),
    ],
    beginnerTip:
        'Ten easy minutes before you lift is a warm-up. Save the harder '
        'cardio for after your weights, or a separate day.',
  ),

  MovementPattern.stretch: PatternCoaching(
    why:
        'Stretching after training helps you feel loose and gives your heart '
        'rate somewhere to come down to. It is the easiest part to skip and the '
        'nicest part to keep.',
    cues: [
      'Ease to a mild tension, never to pain.',
      'Hold for 30 seconds and keep breathing.',
      'Do both sides evenly.',
    ],
    mistakes: [
      Mistake(
        'Bouncing in and out of the stretch',
        'Hold it steady. Bouncing makes the muscle tighten defensively.',
      ),
      Mistake(
        'Long static stretching *before* lifting',
        'It temporarily reduces your strength. Warm up by moving; stretch afterwards.',
      ),
    ],
    beginnerTip:
        'If a stretch feels sharp rather than broad, back off. Sharp is '
        'your body telling you something.',
  ),

  MovementPattern.plyo: PatternCoaching(
    why:
        'Jumping trains your ability to produce force quickly. Genuinely useful '
        '-- but it needs a strength base underneath it first.',
    cues: [
      'Land softly, hips back, knees bent.',
      'Full rest between efforts; this is not conditioning.',
      'Stop the moment the landings get sloppy.',
    ],
    mistakes: [
      Mistake(
        'Doing them tired, for reps',
        'Fatigued jumping is how people get hurt. Low reps, long rests, fresh legs.',
      ),
    ],
    beginnerTip:
        'Skip these until you can squat your own body weight comfortably.',
  ),

  MovementPattern.carry: PatternCoaching(
    why:
        'Picking something heavy up and walking with it trains grip, core and '
        'posture at once. It is the most directly useful thing in the gym.',
    cues: [
      'Stand tall, shoulders back, ribs down.',
      'Short, deliberate steps.',
      'Put the weight down before your form goes.',
    ],
    mistakes: [
      Mistake(
        'Leaning to one side on a single-sided carry',
        'That is the point of the exercise -- resist it. Lighter weight, stay square.',
      ),
    ],
    beginnerTip:
        'Distance or time, not reps. Thirty seconds per trip is a good '
        'place to start.',
  ),

  MovementPattern.grip: PatternCoaching(
    why:
        'Grip is the first thing to fail on rows, deadlifts and carries. '
        'Strengthening it means your back can keep working after your hands '
        'would have given up.',
    cues: [
      'Slow, controlled reps through a full range.',
      'Squeeze hard at the end of each rep.',
    ],
    mistakes: [
      Mistake(
        'Training grip to failure before a pulling session',
        'Do it at the end. Fried forearms ruin everything that comes after.',
      ),
    ],
    beginnerTip:
        'Simply holding the last set of your rows for an extra ten '
        'seconds does most of this for you.',
  ),

  MovementPattern.neck: PatternCoaching(
    why:
        'Neck work builds resilience against everyday strain and looking down '
        'at a phone all day.',
    cues: [
      'Very light, very slow, small range.',
      'Stop immediately at any pinching sensation.',
    ],
    mistakes: [
      Mistake(
        'Adding weight quickly',
        'The neck is not the place to be ambitious. Progress in the smallest '
            'increments available.',
      ),
    ],
    beginnerTip: 'Optional for a beginner. There is no rush to add this.',
  ),
};

PatternCoaching coachingFor(MovementPattern pattern) =>
    patternCoaching[pattern] ?? _fallback;

/// Setup notes attached to the kit, not the movement. A machine's real beginner
/// hurdle is "how do I adjust this thing", which no instruction list covers.
const Map<EquipClass, String> equipmentTips = {
  EquipClass.machine:
      'Set the seat so the moving part lines up with the joint that bends. Most '
      'machines have a diagram on the frame -- it is worth reading once.',
  EquipClass.barbell:
      'The empty bar is usually 20kg / 45lb. That is a real weight and a '
      'perfectly good place to start. Always use collars.',
  EquipClass.dumbbell:
      'Pick a pair you could lift about four more times than the plan asks. If '
      'in doubt, go lighter for the first session and note what happened.',
  EquipClass.cable:
      'Cable height changes the exercise completely. Set the pulley where the '
      'instructions say before you choose your weight.',
  EquipClass.bodyweight:
      'No weight to pick, so progress by adding reps, slowing down, or moving to '
      'a harder variation.',
  EquipClass.band:
      'Bands get harder as they stretch. Anchor them somewhere genuinely solid '
      'and check for nicks before you load one up.',
  EquipClass.kettlebell:
      'The offset weight is the point. Keep the bell close to your body and let '
      'it settle before each rep.',
  EquipClass.ball:
      'Inflate until it gives slightly under your weight. A rock-hard ball is '
      'harder to balance on, not better.',
  EquipClass.cardioMachine:
      'Enter your weight if it asks -- the calorie readout is guesswork without '
      'it, and still only a rough guide.',
  EquipClass.other:
      'Specialist kit. If you are not sure how it works, ask a member of staff '
      'rather than working it out under load.',
};
