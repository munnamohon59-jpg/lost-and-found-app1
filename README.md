# Lost & Found App 📱

Community recovery portal — report lost/found items, verify identity, claim with OTP-based secure handover.

## Tech Stack
- Flutter (Android + Web)
- Firebase Auth + Cloud Firestore (photos stored as base64)
- url_launcher (call owner via dialer)

## 🚀 How to Run (new machine)

### Prerequisites
1. Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Android Studio (Android SDK + JDK er jonno)
3. Verify: `flutter doctor` — Android toolchain ✓ hote hobe

### Setup & Run

flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
flutter pub get
flutter run -d chrome           # Web e test
flutter run                     # USB-connected Android phone e
flutter build apk --release     # Release APK → build\app\outputs\flutter-apk\

## ⚠️ IMPORTANT FILES — DELETE KORO NA!
- `lib/firebase_options.dart` → Firebase connection config
- `android/app/google-services.json` → Firebase Android config

Ei duita chara app Firebase e connect hobe NA!

## 🐛 Common Build Errors + Fixes (real journey theke!)

| Error | Fix |
|-------|-----|
| `JAVA_HOME is not set` | `flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"` |
| `Kotlin metadata 2.4.0, expected 2.1.0` | `android/settings.gradle.kts` → kotlin version `2.3.0` |
| `minSdkVersion 21 cannot be smaller than 24` | `android/app/build.gradle.kts` → `minSdk = 24` |
| `jvmTarget: String is an error` | `kotlin { compilerOptions { jvmTarget.set(JvmTarget.JVM_11) } }` (already in file) |
| `NDK ... did not have a source.properties` | Sdk\ndk folder e broken NDK delete → SDK Manager theke reinstall |
| `not enough space on disk` | C: drive e 5+ GB free koro |
| `unsupported Gradle project` | `flutter pub get` koro; android/app folder ase kina check koro |

## ✨ Features
- Register/Login (Firebase Auth) + BD phone validation (01[3-9]XXXXXXXX)
- ID card photo verification (mandatory) → admin approves → posting unlocked
- Lost/Found posts with mandatory photo → admin review → live feed
- Claim with ownership proof → admin approves → OTP (30 min, auto-renews every 20s)
- Claimer calls owner (dialer) → meet → show PIN → owner verifies → Delivered
- Admin secret login → View (ID photos, post details, claims) → Approve/Reject

## 👥 Roles
- **User:** Home, Post, Claims, Handover (4 tabs)
- **Admin:** + Admin Console (5 tabs)
