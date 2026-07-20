# Kaisen DS6

Kaisen is a Flutter inventory and sales application backed by the shared
Supabase project. The active mobile application is in `mobile/`; database
definitions, migrations, and smoke-test material are in `supabase/`.

The `legacy_api/` directory is retained for rollback and historical reference.
It is not the current group runtime path.

## Group setup

Start with [SETUP_GROUP.md](SETUP_GROUP.md). It contains the required Flutter
version, Android setup, Supabase runtime arguments, and shared-database rules.

Validate a checkout from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_handoff.ps1
```

If Flutter is not on `PATH`, supply its executable explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_handoff.ps1 `
  -FlutterExecutable "C:\path\to\flutter\bin\flutter.bat"
```

After the handoff files are committed and the working tree is clean, a
maintainer with the real client-safe runtime values can package the APK and
source archive:

```powershell
$env:SUPABASE_URL = "YOUR_SUPABASE_URL"
$env:SUPABASE_PUBLISHABLE_KEY = "YOUR_PUBLISHABLE_KEY"
powershell -ExecutionPolicy Bypass -File .\scripts\package_handoff.ps1
```

Never put a `service_role` key or database password in Flutter, Android Studio,
the repository, or the handoff archive.

