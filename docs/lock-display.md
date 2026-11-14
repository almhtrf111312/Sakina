# Software lock display (1.1.1)

The old AOD screen opened Android's live-wallpaper chooser. Its toggle and many
appearance options existed only in an in-memory Riverpod provider; nothing
observed screen-off. A wallpaper is not a portable integration with system AOD.

The replacement is an opt-in foreground service, started while the app is
visible, with an ongoing notification and Stop action. It observes screen-off
and launches a private, dim, black Activity with show-when-locked/turn-screen-on.
It does not dismiss keyguard, install a wallpaper, use accessibility, or replace
system AOD. Overlay permission is checked before enabling and before launching.
OEM background launch restrictions still apply. Xiaomi may additionally require
lock-screen/background pop-up permissions and unrestricted battery usage.

A software display keeps the normal display awake, so it consumes more power than
hardware/system AOD; AMOLED alone does not guarantee compatibility. Pixel shifting
reduces stationary pixels but does not guarantee protection from burn-in. The
service keeps listening but skips display when power saver is on or battery is
10% or lower without charging. A visible display rechecks these limits each minute.
Double-tap exposes the normal lock screen. Pressing power while it is visible
closes it without immediately waking it again. Unlock closes it. Disabling closes
it and stops the service. Preferences are native and persist between app launches,
including a stop from the notification. After reboot or force-stop, open Sakina
to resume an enabled service; no background boot-start is assumed.

Preview and real display use the same native renderer and prayer schedule. Time
and countdown refresh once a minute; the cached schedule is shared with widgets
and refreshed by Flutter. Expired/missing data displays a prompt to open Sakina.
Prayer adjustments, numeral type and Hijri offset remain in general settings.
Existing user-installed live wallpapers are not reset automatically.

## Validation

Automated Flutter tests cover native enable/disable, denied permission, start
failure, saved preferences/appearance, and native preview without enabling.
CI runs these tests and builds the signed universal release APK.

Physical-device acceptance checks (required before claiming device compatibility):

- Xiaomi/HyperOS and another vendor, Android 10 through current: enable, grant
  overlay permission, return, enable; verify no wallpaper chooser appears.
- Lock from both Sakina and another app: display appears; secure PIN/biometric
  keyguard remains when double-tapping; unlock dismisses display.
- Press power during the display: remains off; next lock cycle can show it again.
- Disable and notification Stop: no display on subsequent screen-off; reopening
  settings reflects disabled state. Revoke overlay permission: no crash/relaunch.
- Check permission denial and OEM background-launch blocking instructions.
- Preview with service disabled; change color, brightness and visibility, reopen
  app, and compare preview to locked display. Check actual adjusted prayer times,
  midnight rollover, expired schedule, date/numerals, landscape and large fonts.
- Battery <=10%, charging, power saver, phone calls, notifications, reboot and
  force-stop. Measure overnight battery usage and test fingerprint unlock.

No emulator/physical-device execution is implied by a successful APK build.
