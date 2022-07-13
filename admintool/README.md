# General Framework Installation Notes

Tools:

- https://code.visualstudio.com/download

1) Firebase

1.1) Install Firebase CLI:

- https://firebase.google.com/docs/cli#sign-in-test-cli

1.2) Tutorials
- https://www.youtube.com/hashtag/firebasefundamentals

2) Flutter

2.1) Install Flutter CLI:

https://docs.flutter.dev/get-started/install/macos

2.2) flutter doctor

- Make sure, that flutter doctor runs without any issues.
- Android Studio -> Menu Bar Android Studio, Preferences, Left Sidebar:
  Appearance & Behavior > System Settings > Android SKD
  Middle Tab: SDK Tools: "Android SDK Command-line Tools", Apply
- Install Java

3) FlutterFire

https://firebase.flutter.dev

3.1) Install FlutterFire

https://firebase.flutter.dev/docs/cli

3.2) Tutorial

https://firebase.flutter.dev/docs/overview/

4) Admintool (web)

MacOS Terminal
```bash
firebase login
firebase project:list
flutterfire configure
open -a 'Google Chrome.app'
open -a Simulator
flutter devices
flutter run --release
```

5) FlutterFire - Verbinden

```bash
cd admintool
flutterfire configure
```

6) New Flutter App
```bash
flutter create --org de.hamburg.lsbg digilab_firestore_test
cd digilab_firestore_test
flutterfire configure
```

7) iOS App registrieren
7.1) app/ios/Runner.xcworkspace mit XCode öffnen
7.2) Runner/General: Bundle Identifier: eindeutigen Namen hinterlegen, e.g. de.hamburg.lsbg.kid.admintool
7.3) Runner/Signing & Capabilities: Team auswählen (All)

# admintool

