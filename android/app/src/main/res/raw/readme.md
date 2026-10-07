# Adhan Sound Assets

## adhan_placeholder.wav

**PLACEHOLDER — NOT PRODUCTION LICENSED**

This is a minimal valid WAV file (0.1-second 440 Hz sine wave) generated at
build time for development and CI purposes.

### How to replace with a real adhan recording

1. Obtain a properly licensed adhan audio file (WAV or MP3, ≤ 30 seconds
   recommended for battery/resource reasons).
2. Rename it to `adhan_placeholder.wav` (or update the channel sound name in
   `notification_service.dart` + `prayer_notification_scheduler.dart`).
3. Place the file in `android/app/src/main/res/raw/`.
4. For iOS, place a `.wav` or `.caf` copy at `ios/Runner/adhan_placeholder.wav`.
   Apple requires custom notification sounds to be ≤ 30 seconds and in a
   supported format (`.caf`, `.aiff`, `.wav`).
5. Re-build the app.

### Licensing note

Do NOT distribute a copyrighted adhan recording without verifying the license
allows app distribution.  Public-domain or royalty-free sources:
- Record your own
- Commission a recording
- Use a Creative Commons (CC0 / CC BY) source and attribute correctly
