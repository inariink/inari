# Pending changelog notes

Draft bullets for the next `CHANGELOG.md` entry. Clear or trim this file after promoting.

## Added

- `/inari doctor` checks that the installed EllesmereUI version has everything inari hooks into.
- `/inari reset confirm` and a Reset Settings button in Setup put inari's own options back to defaults.
- inari is in the minimap addon dropdown.
- "Keep my own UI scale" in Setup stops the UI scale warning and the installer's scale step.
- The Profiles updated dialog says what changed, and reimporting EllesmereUI keeps your previous layouts as `inari16:9 backup` / `inari21:9 backup`.

## Changed

- inari only forces unit frame, resource bar, and chat settings while an inari EllesmereUI profile is active. Your own profiles are left alone.
- The chat look is applied by the installer only, so chat changes you make in EllesmereUI now stick.
- "Not Now" on the Profiles updated dialog is remembered until that profile is updated again. Profiles > Update Profiles still opens it.
- "Not Now" in the installer stops it reopening on its own. Run it from Setup or `/inari install`.
- Turning inari off now also stops the forced EllesmereUI settings and hides inari's portraits.
- Reimporting EllesmereUI keeps the spec assignments of the inari profiles.
- CVar presets and the friendly nameplate setting wait for combat to end instead of being skipped.
- Cooldown Manager layout versions are tracked per class. Classes that already have inari layouts are asked to update once.
- EllesmereUI's own first-install picker stays quiet; inari's installer handles setup.

## Fixed

- `/inari apply` and the Reapply button did nothing when no setting had changed.
- `/inari install ellesmere` printed no result and could import twice.
- The installer reopened after every loading screen until it was finished.
- Another group member changing spec or talents re-applied inari's settings.
- Disabling inari's portraits did not bring EllesmereUI's portraits back.
- Idle fade could stay on when combat started without a target.
- Edit Mode import refused when account and character layouts together reached five.
- Health opacity can no longer be set to 1%, which EllesmereUI reads as 100%.

## Removed

- Blinkii's Portraits import code and its bundled profile string.
- `/inari dmpos`.
