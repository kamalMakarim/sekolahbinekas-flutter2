# sekolahbinekas

A new Flutter project.

## Command test di simulator

```bash
#ke root folder project
flutter run
```
## Command tiap kali ganti versi

```bash
flutter clean
rm -rf .dart_tool
rm -f pubspec.lock
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter/Flutter.framework ios/Flutter/Flutter.podspec
flutter pub get
cd ios
pod repo update
pod install
cd ..
flutter build ios --release
open ios/Runner.xcworkspace
```

```bash
flutter clean
rm -rf .dart_tool
rm -f pubspec.lock
flutter pub get
flutter build apk --release
flutter build appbundle --release
```
# TODO LIST
- Geofence 
- Pembayaran RLS sama trigger table top_up_verifications dan balances