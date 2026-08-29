# Workout Guide

A Flutter training app that takes a complete beginner from their first gym session to a real
routine. It is a **frontend** I built for my own use on top of
[hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) — not a product, and there are no plans to make it one.
Feel free to fork it, change it and use it however suits you; the app is MIT-licensed (see
[License](#license) — the exercise media has its own terms).

The dataset ships with `index.html` — a good desktop browser for 1,324 exercises, with search
and three filter facets. It answers *"what exercises exist?"*. It cannot answer the questions
someone actually has in a gym: **what should I do today, am I allowed to do this yet, and how
long do I rest?**

Workout Guide is built around those questions, for someone on their first day.

---

## What was added on top of the dataset

The raw data is a catalogue. It knows what an exercise *is*; it has no opinion on whether a
beginner should do it, or how it fits into a week. [`tools/build_data.py`](tools/build_data.py)
derives that missing layer:

| Field | Why it exists |
| --- | --- |
| `pattern` | Movement pattern (squat / hinge / horizontal push / …). A week is balanced when *patterns* are balanced, so the plan generator picks by pattern, never by muscle name. |
| `difficulty` | How hard the movement is to perform **correctly** — a different question from how heavy it is. A machine chest press is beginner because the path is fixed; a barbell back squat is not, at any weight. |
| `compound` | Multi-joint lifts, which anchor every session. |
| `unilateral` | One side at a time, so a "set" means a set per side. |
| `equipClass` | Coarse bucket matched against what the user says they have. |
| `home` | The kit a movement needs in a flat — an empty list means a floor and nothing else, and the field is absent entirely for the 690 movements that need a gym. The dataset records the equipment the demonstrator stood next to, never what the movement *requires*, so a bodyweight dip filed under "body weight" is really asking for a bar. The instructions are read as well as the name, because "Gorilla Chin" gives nothing away and its first step says "grip a high bar". |

It also fixes source-data problems: mojibake in six names (`45в°` → `45°`), and title-casing.

Correctness here is enforced, not assumed — [`tools/check_data.py`](tools/check_data.py) asserts
24 well-known lifts land on the right pattern and difficulty, that a push-up needs nothing and a
dumbbell bench press needs a bench, that a lat pulldown is not offered to someone in a living
room, and
[`app/test/plan_generator_test.dart`](app/test/plan_generator_test.dart) checks the guarantees
that actually matter across all 48 onboarding combinations.

Beyond the derived fields, three bodies of content were written for the app:

- **Coaching notes** per movement pattern — why it is in your plan, two or three cues, and the
  mistakes that actually go wrong. The dataset will happily tell someone to squat without
  mentioning that knees caving inward is the thing that will hurt them.
- **Muscle map** — the dataset's three overlapping muscle vocabularies mapped onto regions of an
  anatomical figure, plus plain-English explanations ("lats — the wide muscles down the sides of
  your back").
- **Nine beginner guides** — what actually happens when you walk in, how to pick a first weight,
  why you hurt two days later.

## Media pipeline

[`tools/build_media.py`](tools/build_media.py) converts the 1,324 GIFs to animated WebP:

```
121 MB  →  45 MB      identical frame timing, all 12 frames, infinite loop preserved
```

Frame timing is preserved exactly, including the one-second hold at each end position — that
rhythm is doing real teaching work, so it is not normalised to a constant frame rate.

The English-only JSON drops from **17 MB to 0.92 MB**.

Everything is bundled. The app makes **no network requests at all**, which is what lets it work
in a basement gym with no signal.

## The app

```
Onboarding  →  five steps, one question each, one supporting line each
    ↓
At home     →  what you can train in a flat, with the kit you actually own
Plan        →  the week, today's session, why this split, what each day is for
Library     →  the reference page, rebuilt for a phone
Progress    →  consistency first, then volume, then where your work goes
Learn       →  the things nobody tells you before your first session
```

The **session screen** is the one that had to be right: a phone propped against a rack, used by
someone out of breath. One exercise fills the screen, set rows are large tap targets, completing
a set is a single tap that also starts the rest timer, the display is held awake, and every
change is written to disk immediately because phones die mid-workout.

### Design decisions worth knowing

- **Consistency is measured in weeks, not days.** A daily streak punishes exactly the rest days
  a beginner needs, and the first miss tends to end the habit.
- **A novice is never given low-rep heavy work**, whatever goal they picked. Five hard reps of a
  lift you cannot yet perform is the worst of both worlds.
- **Five days a week is not offered to someone who has never trained.** Their limit is recovery,
  not motivation.
- **The balance chart** puts chest next to back deliberately. Beginners overtrain what they can
  see in the mirror; the chart makes that obvious without anyone having to say it.
- **A running workout replaces the day card** rather than sitting above it — showing both left
  the card's own button greyed out and unexplained, a dead end on the app's most important control.

### Training at home

The library answers *what exercises exist*. The **At home** tab answers a much narrower and far
more useful question: what can I do on this floor, tonight, with what is in the room.

- **The kit is the filter, and it sits above everything.** Four things can be ticked — dumbbells,
  a pull-up bar, a bench or chair, a band — and every count on the page is a count of what that
  kit can do. Toggling one visibly moves the numbers, which explains the page without a sentence
  of help text.
- **A floor and a wall are assumed.** 220 movements need nothing else, and that is the case the
  page is built around.
- **Eight focuses, six of them regions and two cutting across.** A jump squat is legs *and*
  conditioning; a hamstring stretch is legs *and* mobility. Those are the two sessions people ask
  for by name, so they get a tile rather than being buried inside "Legs".
- **Twenty to a page, not an endless scroll.** A page is a finite thing you can get to the bottom
  of, which is what picking three exercises for a session needs. 106 core movements in one
  continuous list is a scroll with no decision at the end of it. Turning a page moves the grid
  along the axis you pressed.
- **A short grid explains itself.** With an empty room, "Shoulders" is four movements — the honest
  answer. Rather than leaving it at that, the page names the one purchase that changes it and by
  how much, and tapping it does the thing instead of sending you back a screen to do it.
- **Filters are built from what is in front of you.** A chest page never offers "calves", and a
  page with nothing advanced in it never offers "Advanced", so no tap can produce an empty grid.
- **Sort is on the surface, not behind the filter button.** Ordering is what you reach for the
  instant the grid did not lead with what you expected, and it should cost one tap.

Removing Today cost the app nothing it needed: Plan already carried the week and the Start button
for the next session, so it took on the resume card and the week strip as well.

## Design system

Light, greyscale, flat. **There are no gradients anywhere.** Depth comes from a hairline border
and one step of background tint, the way Linear and shadcn do it.

Everything comes from [`core/theme/`](app/lib/core/theme/) and nothing is allowed to invent a
value:

| | |
| --- | --- |
| **Type** | Seven styles — `h1 h2 h3 body small label caption` plus three tabular numerics. No screen passes a one-off `fontSize`; there were 58 of those and now there are none. |
| **Spacing** | A strict 4px grid, one 20px page gutter used by every screen so edges line up as you navigate. |
| **Surfaces** | A four-step neutral ramp. Borders do the structural work; shadows are reserved for things that genuinely float. |
| **Buttons** | Four variants, three heights (32/40/48). A screen has exactly one primary. |

Colour has exactly two jobs, and decoration is not one of them:

1. **Tinting an icon by what it means** — blue for information and timing, violet for technique,
   emerald for done, amber for caution, rose for destructive, orange for effort, teal for
   measurement, indigo for learning. A muted plate behind a tinted glyph (`FIconTile`) is what
   keeps a greyscale interface from reading as monotonous.
2. **Washing a surface that is a different *kind* of thing** — an 8% tint plus a 20% hairline
   turns a card into a callout without it competing with the text on top.

The same semantics run everywhere: a completed set, a finished rest timer and the "Beginner"
difficulty tag are all the same green, because they all mean the same thing.

### On text

The first version of this app had a paragraph everywhere a sentence would do. The rewrite cut it
hard:

- **Onboarding lost a whole step.** The name question asked for something before delivering
  anything, and its answer only ever decorated a greeting. Settings collects it instead.
- **The exercise page went from a seven-section scroll to three tabs** — Steps, Muscles, Tips.
  Someone checking "how many reps" never scrolls past the mistakes list again.
- **892 exercises ended with "Repeat for the desired number of repetitions."** The app prescribes
  the reps two inches above, so [`build_data.py`](tools/build_data.py) strips it — while keeping
  the variants that name a side, because those carry real information.
- Every question in onboarding gets one supporting line. If it needs a paragraph to justify
  itself, it is the wrong question.

### Motion

Defined once in [`core/motion/`](app/lib/core/motion/). Two rules run through all of it: things
seen dozens of times a day move fast or not at all, and anything entering or leaving uses an
ease-*out* — `easeIn` delays movement at exactly the moment the eye is watching.

Tab switches cross-fade in 200 ms with no lateral movement, and hidden tabs have their tickers
disabled so nothing animates off-screen. The workout summary, seen a few times a week at a moment
of real accomplishment, is allowed to take its time. Sheets track the finger 1:1, rubber-band past
their limit, and project momentum on release, so a quick flick dismisses even if it barely moved.
All of it respects `prefers-reduced-motion`.

Icons, charts, the anatomical body map and the logo are drawn as vector paths in `CustomPainter`
rather than pulled from a font or an image, so each element animates independently — the logo
draws itself stroke by stroke, muscles fade up region by region on the post-workout figure, ticks
are drawn along their own path rather than cross-faded in.

## Running it

The exercise dataset is a git submodule, and the data and media the app bundles are generated
from it on your machine — they are **not** committed to this repository (see
[License](#license) for why).

```bash
git clone --recurse-submodules <this repo>
# or, in an existing clone:
git submodule update --init

# derive the training layer and check it, then convert the media
# (Python 3, no packages; ffmpeg on PATH for the media step)
python tools/build_data.py && python tools/check_data.py
python tools/build_media.py

cd app
flutter pub get
flutter test          # 48 tests
flutter run
```

Requires Flutter 3.44+. Dependencies are deliberately minimal: `flutter_riverpod`,
`shared_preferences`, `wakelock_plus`. Everything visual is custom — Material is present only as
a host for routing and overlays. The launcher icon is drawn by
[`tools/build_icon.py`](tools/build_icon.py) (needs Pillow) and only needs re-running if the
logo changes.

> **Note for Windows builds:** `android/gradle.properties` sets `kotlin.incremental=false`.
> Kotlin's incremental compiler cannot reliably release its `.tab` cache handles on Windows,
> which breaks the plugin builds. Also avoid running `flutter test` and `flutter build`
> concurrently — they contend over the Dart kernel cache.

## License

- **The app** — everything under [`app/`](app/) and [`tools/`](tools/) — is released under the
  [MIT License](LICENSE).
- **Exercise data** is from [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) (MIT, © Hasan Emir
  Yıldırım), pulled in as a submodule rather than copied. `app/assets/data/exercises.json` is
  derived from it locally.
- **Exercise thumbnails and animations** are **© Gym visual — https://gymvisual.com/**. They
  are redistributed in the dataset with the rights holder's separate permission, under its own
  terms (180×180 only, attribution must stay). That permission covers the dataset, not this
  repo, so the converted media is generated from the submodule on your machine and never
  committed here. The app keeps the attribution in Settings; read
  [Gym visual's terms](https://gymvisual.com/content/3-terms-and-conditions-of-use) before
  distributing a build.
- **Inter** typeface © Rasmus Andersson, [SIL OFL 1.1](app/assets/fonts/LICENSE-Inter.txt).

Full third-party notices are in [`NOTICE.md`](NOTICE.md).
