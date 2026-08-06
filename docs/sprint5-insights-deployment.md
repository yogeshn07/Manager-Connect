# Catalyst Insights — Deployment Documentation

**Module:** Catalyst Insights  
**Version:** 1.0.0+1  
**Sprint:** Sprint 5 — Insights Integration  
**Date:** 2026-07-21

---

## 1. Pre-Deployment Prerequisites

### Backend (Supabase) — Must Be Verified Before Flutter Deployment

| Requirement | Verification Command | Expected |
|-------------|---------------------|----------|
| `catalyst_insights` table exists | `select count(*) from catalyst_insights` | No error |
| `insights_raw` table exists | `select count(*) from insights_raw` | No error |
| `insights_sources` table exists | `select count(*) from insights_sources` | No error |
| RLS enabled on `catalyst_insights` | Supabase dashboard → Table Editor → RLS | Enabled |
| RLS enabled on `insights_raw` | Supabase dashboard → Table Editor → RLS | Enabled |
| RLS enabled on `insights_sources` | Supabase dashboard → Table Editor → RLS | Enabled |
| `collect-insight` Edge Function deployed | `supabase functions list` | Status: active |
| `review-insight` Edge Function deployed | `supabase functions list` | Status: active |
| At least one row in `insights_sources` with `is_active = true` | `select * from insights_sources where is_active = true` | ≥1 row |

### Flutter Toolchain

| Requirement | Command | Expected |
|-------------|---------|----------|
| Flutter SDK | `flutter --version` | >=3.38.0 |
| Dart SDK | `dart --version` | >=3.9.0 <4.0.0 |
| Android SDK | `flutter doctor` | No critical issues |
| Java 17 | `java -version` | 17.x |

---

## 2. Environment Configuration

The app uses `String.fromEnvironment` for Supabase credentials injected at build time. Hardcoded fallbacks in `env.dart` point to the production Supabase project and are used automatically if `--dart-define` flags are omitted.

### Recommended: Explicit Injection (Production Builds)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xispkgjjhqaiddbcaudt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon_key>
```

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://xispkgjjhqaiddbcaudt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon_key>
```

### Fallback (Internal Beta Only)

Omitting `--dart-define` flags is acceptable for internal beta. The app will use the hardcoded fallback values in `lib/core/config/env.dart`, which point to the same production Supabase project.

### Important Notes

- The anon key is the Supabase `anon` role key (public by design). It is not a secret.
- The `service_role` key is **never** present in the Flutter app. It exists only in Supabase Edge Function environment.
- `Env.isConfigured` must return `true` before Supabase initialises in `lib/app.dart`.

---

## 3. Android Release Build

### Step 1: Configure Signing (Required for Play Store)

**Current state:** `build.gradle.kts` uses `signingConfigs.getByName("debug")` for release builds. This is acceptable for internal beta via direct APK install but **not** for Play Store.

To configure production signing:

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias catalysts-upload
   ```

2. Create `frontend/android/key.properties` (do NOT commit to git):
   ```
   storePassword=<keystore_password>
   keyPassword=<key_password>
   keyAlias=catalysts-upload
   storeFile=../upload-keystore.jks
   ```

3. Update `frontend/android/app/build.gradle.kts`:
   ```kotlin
   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
   }
   
   signingConfigs {
       create("release") {
           keyAlias = keystoreProperties["keyAlias"] as String
           keyPassword = keystoreProperties["keyPassword"] as String
           storeFile = keystoreProperties["storeFile"]?.let { file(it) }
           storePassword = keystoreProperties["storePassword"] as String
       }
   }
   
   buildTypes {
       release {
           signingConfig = signingConfigs.getByName("release")
       }
   }
   ```

### Step 2: Build

```bash
cd frontend
flutter clean
flutter pub get

# APK (for direct distribution)
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# App Bundle (for Play Store)
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

**Output locations:**
- APK: `frontend/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `frontend/build/app/outputs/bundle/release/app-release.aab`

### Step 3: Verify the Build

```bash
# Confirm APK is signed (should show debug or release keystore info)
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. iOS Release Build (macOS Required)

> iOS builds require macOS with Xcode 15+. The following steps are documented for completeness; execution requires the macOS build machine.

### Prerequisites

- Valid Apple Developer Program membership
- App Store Connect app record created for `com.managerconnect.manager_connect`
- Distribution certificate and provisioning profile installed in Xcode

### Build

```bash
cd frontend
flutter clean
flutter pub get
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://xispkgjjhqaiddbcaudt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon_key>
```

**Output:** `frontend/build/ios/ipa/manager_connect.ipa`

### iOS Configuration Verified

| Item | Value | Status |
|------|-------|--------|
| `CFBundleDisplayName` | "The Catalysts" | ✓ |
| `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | ✓ |
| `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` → 1.0.0 | ✓ |
| `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` → 1 | ✓ |
| Portrait orientation | Supported | ✓ |
| Landscape Left/Right | Supported | ✓ |
| Multiple scenes | false | ✓ |

---

## 5. Post-Deployment Verification

After distributing the build to internal beta testers, verify:

1. **Auth flow**: Sign in with OTP → profile loads → navigation works
2. **Insights feed**: `/insights` accessible from navigation, articles load
3. **Category filter**: Filter chip changes result set
4. **Detail view**: Tap article → detail screen renders all sections
5. **Submit insight**: Form validates URL + source; submission reaches `insights_raw`
6. **Submission history**: `/insights/history` shows the submitted item
7. **Admin — review queue**: Admin user sees `/admin/insights/review` with items
8. **Admin — pipeline health**: Admin user sees `/admin/insights/pipeline` with signals
9. **Error handling**: Disable network → error state appears with retry button

---

## 6. Distribution

### Internal Beta (Current Phase)

- Android: Distribute APK directly via Firebase App Distribution or share file
- iOS: Distribute via TestFlight (requires macOS build + App Store Connect)

### Public Release (Future)

- Android: Submit AAB to Google Play Console → Production track
- iOS: Submit IPA via App Store Connect → App Review → Distribution

---

## 7. Application Metadata

| Field | Value |
|-------|-------|
| App Name | The Catalysts |
| Package / Bundle ID | com.managerconnect.manager_connect |
| Version Name | 1.0.0 |
| Version Code / Build Number | 1 |
| Min Android SDK | flutter.minSdkVersion (set by Flutter SDK) |
| Target Android SDK | flutter.compileSdkVersion |
| Java Compatibility | Java 17 |
| Supabase Project | xispkgjjhqaiddbcaudt.supabase.co |
| Edge Functions | collect-insight, review-insight |
| Database Tables | catalyst_insights, insights_raw, insights_sources |
