# E2E Tests (Patrol)

End-to-end automated QA that drives the **real app** on an Android emulator
against the **real backend** (the VM) and the **real Firebase project**. This is
the alternative to manually clicking through every screen by hand.

This first slice covers the **full authentication lifecycle**. Receipts,
warranties, and claims are follow-up slices that extend the same infrastructure.

## What it does

Each run is **self-cleaning** — it creates a test account and then destroys it
through the app's own *Delete Account* feature, so deletion is itself under test
and the Firebase project is left clean for the next run:

1. **Pre-flight** — the local helper deletes any leftover test account.
2. **Sign-up** — drives the sign-up form (plus form-validation unhappy paths).
3. **Verify email** — the helper marks the account verified server-side; the
   app's verify-email screen polls `reload()` every 3s and proceeds.
4. **Session** — asserts Home, signs out, checks a wrong-password sign-in error,
   then signs in correctly (which also satisfies Firebase's
   `requires-recent-login` gate for deletion).
5. **Delete account** — deletes via the app, asserts the Firebase user is gone.
6. **Teardown safety net** — idempotent helper cleanup if any phase aborts.

## Why a local helper?

A test running on the device can't click a link in a verification email or run
the Firebase Admin SDK. `tools/test_admin_helper.py` is a throwaway HTTP service
that runs on your machine for the duration of the run, reachable from the
emulator at `http://10.0.2.2:<port>`. It uses the same
`firebase-service-account.json` the backend uses. It is **not** part of the app
or the backend API.

## Prerequisites

- Android emulator running (`flutter devices` lists it).
- Patrol CLI: `dart pub global activate patrol_cli`
- `cd mobile && flutter pub get`
- Helper deps: `pip install -r integration_test/tools/requirements.txt`
- `firebase-service-account.json` available locally (gitignored; same file the
  backend uses).

## Running

From `mobile/`:

```powershell
./scripts/run_e2e.ps1 `
  -ServiceAccount ../backend/firebase-service-account.json `
  -Email e2e-test@yourdomain.com `
  -Password 'SuperSecret123!'
```

The script starts the helper, runs `patrol test`, and stops the helper on exit.

### Physical device (adb)

Works the same, with two differences: the device reaches the helper at your PC's
**LAN IP** (not `10.0.2.2`), and you target the device explicitly. Phone and PC
must be on the same network with the helper port open in the firewall.

```powershell
./scripts/run_e2e.ps1 `
  -ServiceAccount ../backend/firebase-service-account.json `
  -Email e2e-test@yourdomain.com -Password 'SuperSecret123!' `
  -HelperHost 192.168.1.50 `   # your PC's LAN IP (ipconfig)
  -DeviceId <id from `adb devices`>
```

To run manually instead: start the helper
(`FIREBASE_SERVICE_ACCOUNT=... python integration_test/tools/test_admin_helper.py --port 8765`),
then `patrol test --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=... --dart-define=E2E_HELPER_URL=http://10.0.2.2:8765`.

## Configuration

Credentials are injected via `--dart-define` (never committed) and read in
`helpers/test_config.dart`: `E2E_EMAIL`, `E2E_PASSWORD`, `E2E_FULL_NAME`,
`E2E_HELPER_URL`. The backend URL can be retargeted with
`--dart-define=API_BASE_URL=...` (defaults to the VM).

## Notes & deferred scope

- **Cleartext HTTP**: the app talks to the VM over `http://`. The debug
  AndroidManifest (`android/app/src/debug/AndroidManifest.xml`) enables
  `usesCleartextTraffic` for the test build only; production is untouched.
  (Heads-up: production targets API 28+ with no cleartext allowance, so the
  release build may not reach an `http://` backend — worth confirming
  separately.)
- **Google / Apple sign-in** are not automated (native OAuth chooser; Apple is
  "coming soon" in-app). Email/password only.
- **Receipts/claims** need the `image_picker` native-picker problem solved
  (mock `ImagePicker` or pre-stage device files) — future slice.
- **CI**: this suite is local-only by design; it is not wired into GitHub
  Actions.
- Patrol's native API (`$.native.*`) can differ slightly across versions; if
  `patrol test` reports an unknown method on first run, align the call in
  `helpers/auth_robot.dart` with your resolved Patrol version.
```
