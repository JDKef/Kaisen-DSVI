# Kaisen DS6 group setup

## Required tools

- Flutter `3.44.6` on the stable channel.
- Dart `3.12.2` (included with the required Flutter SDK).
- Android Studio with the Flutter and Dart plugins.
- Android SDK, Android SDK Platform-Tools, Android SDK Command-line Tools, and
  accepted Android licenses.
- An Android phone with USB debugging enabled or an Android emulator.

The exact verified SDK output is recorded in `FLUTTER_VERSION.txt`. Do not run
`flutter pub upgrade` casually. The repository includes `mobile/pubspec.lock`
so teammates use the tested dependency set.

## Verify the workstation

Open PowerShell and run:

```powershell
flutter doctor
flutter doctor --android-licenses
```

Resolve Android toolchain errors before attempting an APK build. The complete
`flutter doctor` output should not be committed because it can contain personal
machine paths and device details.

## Install and validate the application

From the repository root:

```powershell
Set-Location .\mobile
flutter pub get
flutter analyze
flutter test
flutter devices
```

The repository-level validation script runs the first three Flutter commands
and stops immediately on failure:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_handoff.ps1
```

Use `-FlutterExecutable "C:\path\to\flutter\bin\flutter.bat"` when Flutter is
not on `PATH`.

## Configure Supabase safely

Kaisen reads both client values through `String.fromEnvironment`. Obtain the
shared project's client-safe URL and publishable key from the team maintainer.
Do not hardcode them in Dart, Gradle, XML, documentation, or a committed run
configuration.

Run from `mobile/` with runtime definitions:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

`GROUP_RUN_ARGS.example.txt` contains placeholders only. A teammate may copy it
to `GROUP_RUN_ARGS.txt` and replace the placeholders locally; that real file is
ignored by Git and must never be shared.

To configure Android Studio:

1. Open the `mobile/` directory in Android Studio.
2. Open **Run > Edit Configurations**.
3. Select the Flutter run configuration.
4. Paste both space-separated `--dart-define` arguments into **Additional run
   args**.
5. Keep the real values local. Do not commit `.idea` run configurations that
   contain credentials.

Only the Supabase publishable key belongs in a client application. Teammates
must never use or request a `service_role` key, PostgreSQL password, dashboard
access token, or other server credential.

## Shared environment rules

- The configured Supabase project already exists. Do not rerun the migrations
  in `supabase/migrations/` against that configured project.
- Every teammate connects to the same Kaisen business and database.
- Each teammate must register a new application user instead of sharing
  credentials.
- Remote authentication, inventory, sales, and history operations need an
  internet connection.
- Test products and users should use identifiable names, for example
  `TEST-JOSE-GUANTES`, so the group can recognize and clean up demonstration
  records safely.
- Do not deploy, alter Supabase settings, execute SQL, or run
  `supabase/SMOKE_TEST.sql` without the team's explicit database-maintenance
  process.

## Run on Android

Start an emulator or connect an authorized device, then run from `mobile/`:

```powershell
flutter devices
flutter run `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Grant camera permission when prompted so barcode scanning can operate.

