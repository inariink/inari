## inari 1.10

A big one! inari now works on WoW Forever and pretty much every profile got a refresh.

### New

- **WoW Forever support.** Same download as retail, and every Forever class gets its own Cooldown Manager layout.
- **DynamicCam profile.** Import it from the installer, from Profiles, or with `/inari install dynamiccam`.
- **`/inari doctor`** checks that your EllesmereUI version has everything inari needs.
- **Reset Settings** in Setup (or `/inari reset confirm`) puts inari's own options back to default.
- **"Keep my own UI scale"** in Setup, if you'd rather not have inari touch your UI scale.
- inari now shows up in the minimap addon dropdown.

### Updated profiles

- New EllesmereUI (21:9), BigWigs, EXBoss and Edit Mode profiles.
- New Rogue and Warlock Cooldown Manager layouts.
- **16:9 players:** the updated 16:9 layout isn't ready yet, so you keep your current one for now. It's coming in a later update.
- The update prompt now tells you what changed. Reimporting EllesmereUI saves your previous layout as `inari16:9 backup` / `inari21:9 backup` and keeps your spec assignments.

### Changes

- inari leaves your own EllesmereUI profiles alone and only adjusts things while an inari profile is active.
- Chat changes you make in EllesmereUI now stick. inari only sets up the chat look during the install.
- "Not Now" is remembered, both in the installer and on the update prompt. You can always open them again from Setup, Profiles, or `/inari install`.
- Turning inari off now fully turns it off, portraits included.
- Graphics presets and the friendly nameplate setting wait until combat ends instead of being skipped.
- EllesmereUI's own setup window stays out of the way, since inari's installer handles it.

### Fixes

- Sounds, the BigWigs bar style and the countdown voice now load properly from the bundled profiles.
- The installer no longer resets your Skyriding bar texture and size.
- No more bright line under unit frames with a detached power bar when frame shadows are on.
- The installer doesn't freeze anymore if a step runs into an error.
- `/inari apply` and Reapply work even when nothing has changed.
- `/inari install ellesmere` shows a result and doesn't import twice.
- The installer doesn't reopen after every loading screen.
- Someone else in your group changing spec no longer reapplies inari's settings.
- EllesmereUI's portraits come back when you turn inari's portraits off.
- Idle fade turns off when combat starts without a target.
- Edit Mode import works when you already have five layouts.
- Health opacity can't be set to 1% anymore (EllesmereUI treats that as 100%).

### Removed

- The Blinkii's Portraits import, since portraits are built into inari.
- `/inari dmpos`.

## inari 1.0.6

- Added Nameplate target arrows, on by default. Toggle and resize them in extras in `/inari` or with `/inari arrows on|off|30`.
- Updated EXBoss profile for season 2!
- Cooldown Manager layouts are updated for every class. Outdated CDM profiles now show in the Profiles updated dialog.

## inari 1.0.5

- First public release, slash commands are `/inari`, `/iui`, and `/inariui`.
- Addon list now has a icon.
- EllesmereUI layouts are `inari16:9` and `inari21:9`. The installer imports both and uses the one that matches your monitor.
- Player and target portraits are built in. Blinkii's Portraits is not required anymore.
- Appearance covers Dark Mode and Class Colored.
- Bundled imports for BigWigs (including countdown voice and bar style), EXBoss, sArena Reloaded, Baganator, Cooldown Manager, and Edit Mode.
- Healing profile activates on healer specs.
- Damage Meters changed to a three-window layout.
- Site and downloads: [inari.ink](https://inari.ink).
