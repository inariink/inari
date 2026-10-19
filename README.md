<div align="center">

<a href="https://inari.ink">
  <img src="kitsune.png" alt="inari" width="200">
</a>

<p>An EllesmereUI-based World of Warcraft user interface.</p>

<p>
  <a href="https://inari.ink">inari.ink</a>
  ·
  <a href="https://github.com/inariink/inari/releases/latest">Download</a>
  ·
  <a href="https://inari.ink">CurseForge</a>
  ·
  <a href="inari/CHANGELOG.md">Changelog</a>
</p>

<p><img src="screenshots/dark_idle.jpg" alt="Idle" width="920"></p>
<p><img src="screenshots/dark_dps_dungeon.jpg" alt="Dungeon" width="920"></p>
<p><img src="screenshots/color_heal_raid.jpg" alt="Raid" width="920"></p>

</div>

inari is the installer, profiles, and extras on top of [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui). It imports 16:9 and 21:9 layouts, player and target portraits, frame shadows, and the supporting profiles for BigWigs, EXBoss, sArena, and Baganator.

Setup and downloads live on **[inari.ink](https://inari.ink)**. This repo is the addon.

## Install

**Coming from a version before 1.0.5?** That update is a full reinstall. Delete the previous copy of this addon from `Interface\AddOns` and reimport the WowUp string. Settings do not carry over.

1. In [WowUp](https://wowup.io/), open **My Addons → Import** and paste the string from [inari.ink/install](https://inari.ink/install).
2. Restart World of Warcraft and log in. The installer opens, picks 16:9 or 21:9 from your monitor, and imports both layouts.

If it does not open:

```
/inari install
```

No WowUp? Grab [inari.zip](https://github.com/inariink/inari/releases/latest/download/inari.zip) or install from [CurseForge](https://inari.ink). Those are inari only — EllesmereUI and the rest still have to be installed separately. A [video guide](https://www.youtube.com/watch?v=W4Ub_4-39Xk) covers the full setup.

## What it does

- **Layouts** — Bundled EllesmereUI profiles for 16:9 and 21:9. The installer imports both; switch later with `/inari layout 16` or `/inari layout 21`.
- **Portraits** — Player and target portraits are built in. Blinkii's Portraits is not required.
- **Appearance** — Dark or class coloring, health opacity, class-background tint, chat button side, and drop shadows on unit frames, resource bars, and the cooldown manager.
- **Profiles** — Imports for BigWigs (including boss options and an inari countdown voice), EXBoss, sArena Reloaded, Baganator, and Cooldown Manager.
- **Healing** — A healing profile that activates on healer specs.

Required: **EllesmereUI** and **inari**. Optional, but what the installer styles: BigWigs / LittleWigs, EXBoss, sArena Reloaded, Baganator.

## Commands

| Command | |
| --- | --- |
| `/inari` / `/iui` / `/inariui` | Settings |
| `/inari install` | Run the installer |
| `/inari layout 16` / `21` | Switch the active EllesmereUI layout |
| `/inari appearance dark` / `class` | Frame coloring |
| `/inari shadows on` / `off` | Frame shadows |
| `/inari doctor` | Check that this EllesmereUI version has everything inari hooks into |
| `/inari reset confirm` | Reset inari's own settings to defaults |
| `/inari help` | Full command list |
