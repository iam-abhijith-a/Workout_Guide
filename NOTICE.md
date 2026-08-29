# Third-party notices

Workout Guide itself (everything under `app/` and `tools/`) is released under the MIT
License — see [`LICENSE`](LICENSE). It is built on the following third-party work.

## exercises-dataset

The exercise **data** — names, categories, body parts, equipment, targets, muscle groups and
instructions — comes from
[hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset), included
as a git submodule at `exercises-dataset/` rather than copied into this repository.

> MIT License — Copyright (c) 2026 Hasan Emir Yıldırım

`app/assets/data/exercises.json` is derived from that data by `tools/build_data.py` and is
generated locally, not committed.

## Exercise media — Gym visual

The exercise thumbnails and animations are the property of **Gym visual** and are
redistributed in the dataset **with the rights holder's separate permission**, under these
terms (see the dataset's
[`NOTICE.md`](https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md)):

> **© Gym visual — https://gymvisual.com/**
>
> - distributed at **180×180** only;
> - every use must carry the copyright indication above.

That permission was granted to the dataset, not to this repository — as the dataset puts it,
*cloning this repo is not a license*. For that reason the converted media the app bundles
(`app/assets/anim/`, `app/assets/thumb/`) is **not committed here**. It is generated on your
own machine from the submodule by `tools/build_media.py`, at the original 180×180 size, and
the app shows the attribution in Settings. Before distributing a build of the app, read
[Gym visual's Terms & Conditions of Use](https://gymvisual.com/content/3-terms-and-conditions-of-use)
and, where required, obtain your own licence from Gym visual.

## Inter

The [Inter](https://rsms.me/inter/) typeface is Copyright (c) 2016 The Inter Project Authors
(Rasmus Andersson), licensed under the SIL Open Font License 1.1 — see
[`app/assets/fonts/LICENSE-Inter.txt`](app/assets/fonts/LICENSE-Inter.txt).
