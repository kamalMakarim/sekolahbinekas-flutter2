# sekolahbinekas

A new Flutter project.

## Pengajuan penahanan invoice

Jalankan `sql/23.on_hold_requests.sql` setelah `sql/21.paymentVA.sql` pada
database Supabase sebelum menggunakan fitur ini. Orang tua dapat mengajukan
penahanan seluruh invoice terbit dari halaman Pembayaran. Akuntan memproses
pengajuan dan melihat riwayat melalui menu Pengajuan Penahanan.

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