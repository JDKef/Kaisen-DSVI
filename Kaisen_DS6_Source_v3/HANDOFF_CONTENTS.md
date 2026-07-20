# Kaisen DS6 handoff contents

## Packaged files

After `scripts/package_handoff.ps1` succeeds, `dist/` contains:

- `Kaisen_DS6_v3.apk`: one universal Android APK built with runtime
  `--dart-define` values. Release is the default build mode.
- `Kaisen_DS6_Source_v3.zip`: a clean source snapshot created from committed
  Git content without Git history.
- `SETUP_GROUP.md`: workstation, Android, Flutter, and Supabase client setup.
- `GROUP_RUN_ARGS.example.txt`: placeholder runtime arguments only.
- `DEMO_CHECKLIST.md`: the agreed group demonstration flow.
- `HANDOFF_CONTENTS.md`: this inventory.
- `FLUTTER_VERSION.txt`: exact Flutter SDK version used for validation.

## Source archive structure

- `mobile/`: the Flutter application, Android project, lockfile, and tests.
- `supabase/`: existing schema migrations, setup notes, and smoke-test material.
- `legacy_api/`: retained rollback and historical PHP/SQLite-era material.
- `docs/`: architecture, baseline, test, migration, and approved UI documents.
- `scripts/`: repeatable validation and packaging scripts.

The root `README.md` and `SETUP_GROUP.md` are the current handoff entry points.
The older `mobile/README.md` describes the legacy local/PHP workflow and should
not override the Supabase instructions in the root handoff documents.

## Intentionally excluded from the package

- Git history and local repository metadata.
- `build/`, `.dart_tool/`, Gradle caches, IDE caches, and device captures.
- `dist/` from any earlier run.
- Real Supabase run arguments, environment files, signing keys, database
  passwords, and access tokens.
- Machine-specific `FLUTTER_DOCTOR_JOSE.txt` output.
- The tracked baseline APK, which remains in the repository as rollback
  material but is not part of the clean source archive.
- The tracked Office temporary lock file under `mobile/docs/`.
- Experimental industrial mockups, screenshots, and abandoned design reports.

## Before sharing

The packaging script requires a clean committed repository because `git archive`
can only package committed content. A maintainer must review and commit the
handoff changes first. The preparation task itself does not commit or push.
