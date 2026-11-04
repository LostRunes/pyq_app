# How app configuration (`.env`) works in Focus Fox

As of 4 Nov 2026 · branch `env-dart-define`

## 1. Summary

Configuration values are **compiled into the app at build time** with `--dart-define-from-file=.env`. The `.env` file is **not shipped inside the app**.

- **Before:** `.env` was bundled as a plain-text asset. Anyone could unzip the APK and read it.
- **Now:** there is no config file in the build. The values exist only inside the compiled app binary, so pulling them out takes reverse-engineering tools, not an unzip.
- **The content database's service-role (admin) key is no longer used by the app at all.** The app uses the public anon key, and anything that needs admin rights runs in Supabase Edge Functions.

The values in the app are now only ones that are designed to be public (anon keys, URLs, OAuth client IDs). This is **not encryption**: anything compiled into an app can in principle be extracted. That's why secrets stay on the server (section 5).

---

## 2. Running and building

The flag is **required**. Without it every value is empty and the app can't reach Supabase.

```bash
# Run (debug)
flutter run --dart-define-from-file=.env

# Android release
flutter build apk --release --dart-define-from-file=.env
flutter build appbundle --release --dart-define-from-file=.env

# iOS release
flutter build ipa --release --dart-define-from-file=.env
```

Built without the flag, the app logs at startup:

```
Missing build config: SUPABASE_URL, SUPABASE_KEY, ... Run with --dart-define-from-file=.env
```

**VS Code / Android Studio:** add the flag to your run configuration. For VS Code, in `.vscode/launch.json`:

```json
{
  "name": "Focus Fox",
  "request": "launch",
  "type": "dart",
  "args": ["--dart-define-from-file=.env"]
}
```

**Hot reload:** values are compile-time constants. After changing `.env`, do a full restart (stop and run again), not a hot reload.

---

## 3. How it works

### The pieces

1. **`.env`** in the project root, in `KEY=value` format. Git-ignored; never committed.
2. **`--dart-define-from-file=.env`** tells the Flutter tool to pass every line of the file to the Dart compiler as a compile-time define.
3. **[`lib/core/config/env.dart`](../lib/core/config/env.dart)** reads each define once:
   ```dart
   abstract final class Env {
     static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
     static const supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');
     static const supabase2Url = String.fromEnvironment('SUPABASE_2_URL');
     static const supabase2AnonKey = String.fromEnvironment('SUPABASE_2_KEY');
     static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
     static const driveApiKey = String.fromEnvironment('DRIVE_API_KEY');
     // ...
   }
   ```
   `String.fromEnvironment` is evaluated **by the compiler**, not at runtime. The compiler writes the value straight into the code as a constant.
4. **The rest of the app** uses `Env.supabaseUrl`, `Env.driveApiKey` and so on. Nothing reads a file at runtime. `flutter_dotenv` has been removed from the project.

### The flow

```
 .env on the build machine
        │  flutter build --dart-define-from-file=.env
        ▼
 Dart compiler: String.fromEnvironment('KEY')  →  constant inside the compiled code
        │
        ▼
 APK / AAB / IPA: compiled code only, no .env file anywhere in the package
        │
        ▼
 App on the phone: uses Env.* constants directly
```

### What changed from before

| | Before (`flutter_dotenv`) | Now (`--dart-define-from-file`) |
|---|---|---|
| `.env` inside the APK/IPA | Yes, plain text at `assets/flutter_assets/.env` | **No** |
| How values are read | File read at startup by `dotenv.load()` | Compile-time constants |
| To see the values | Rename the APK to `.zip` and open the file | Decompile/inspect the native binary (`libapp.so` on Android) |
| Content DB key in the app | Service-role (admin) key | **Anon (public) key**, protected by database rules |
| Student lookup by roll number | App read the `students` table directly | `resolve-student` Edge Function returns one student |
| Passing the flag | Ignored (values came from the bundled file) | Required |

History: this setup was first introduced in "safety precaution" (`1eafd1d`, 27 Jul 2026) and reverted in `499d3e1` (31 Jul 2026, PR #60). Between then and now, `--dart-define-from-file` was being passed but nothing read it; the values came from the bundled `.env`. This branch restores the compile-time setup and the anon-key client.

---

## 4. Every key

| Key | Used for | Public by design? |
|---|---|---|
| `SUPABASE_URL` | Content project URL | Yes |
| `SUPABASE_KEY` | Content project **anon** key. Reads questions, subjects, topics etc. under database (RLS) rules | Yes, safe as long as RLS is correct |
| `SUPABASE_2_URL` | Main project URL (auth, profiles, Skulk) | Yes |
| `SUPABASE_2_KEY` | Main project **anon** key | Yes, safe as long as RLS is correct |
| `GOOGLE_WEB_CLIENT_ID` | Google Sign-In client ID | Yes. Client IDs are not secrets |
| `DRIVE_API_KEY` | Google Drive API (notes and PDFs) | Yes, **if restricted** to our app and the Drive API in Google Cloud Console |
| `LIVEKIT_URL`, `APTITUDE_API_URL` | Service URLs | Yes |

**Not in the app, and must never be added to `.env`:**
- `SUPABASE_SERVICE` (service-role key): admin access, bypasses all database rules
- `GEMINI_API_KEY`, `LIVEKIT_API_SECRET`, or any other paid-API key or `*_SECRET`

Those live only in Supabase Edge Function secrets (`supabase secrets set`).

---

## 5. Why secrets still don't go in the app

Compiling values into the app keeps them out of plain sight, but it is not encryption. Every value the app sends to Supabase or Google has to exist inside the app in usable form. Someone determined can recover it by inspecting the binary or watching the app's network traffic.

So the rule is:
- **In the app:** only values that are safe for every user to see. Database rules (RLS), Google key restrictions and server-side checks are what protect the data.
- **On the server:** everything that grants power: service-role keys, paid API keys, signing secrets. The app calls an Edge Function, which checks the request and uses the secret itself.

Examples already in the codebase:
- `livekit-token` (main project) holds the LiveKit secret and returns short-lived room tokens.
- `manage-subject-customization` (main project) writes subject customizations.
- `resolve-student` (content project) returns a single student's batch and section by roll number.

---

## 6. Open items

1. **Lock down the `students` table.** It is currently readable with the public anon key (14,006 rows: roll numbers, batches, sections). The app no longer reads it directly, so add RLS that denies `anon`/`authenticated` reads. The `resolve-student` function uses the service role server-side and is unaffected.
2. **Rotate the content project's service-role key.** It shipped inside earlier builds. Once this release is out and old versions are force-updated (`app_config` minimum version), generate a new key in Supabase (Settings → API) and update the Edge Function secrets.
3. **Restrict `DRIVE_API_KEY`** in Google Cloud Console → Credentials: Android package `com.focusfox.app` + release SHA-1, iOS bundle `com.focusfox.study`, Drive API only.
4. **Test avatar upload.** It writes to the content project's `avatars` storage bucket, now with the anon key. If the bucket's storage policy doesn't allow it, move uploads to an Edge Function.
5. **Account deletion and subject customizations.** Deleting an account can no longer remove the user's rows in `user_subject_customizations` from the app (anon key). Add that cleanup to the `manage-subject-customization` function or the content project's `delete_my_account`.

### Checklist when adding a new key

- Is it safe for every user to see? Add it to `.env` **and** to `lib/core/config/env.dart`.
- Otherwise, put it in `supabase secrets set` and use it only inside an Edge Function.
- Update every machine and CI job that builds the app, since the build now depends on `.env` being passed in.
