# Mini Arena Flutter

Proyek game Flutter 2D Mini Arena. Source code utama berada di `lib/main.dart`.

## Build APK otomatis (split per ABI)

Workflow GitHub Actions berada di `.github/workflows/build.yml`. Build berjalan otomatis saat ada push ke branch `main` atau `master`, saat pull request, dan bisa juga dijalankan manual lewat tab Actions.

1. Upload/commit **seluruh isi ZIP ini** ke root repository GitHub. Di halaman utama repository harus terlihat `pubspec.yaml`, `lib/`, `android/`, dan `.github/`. Jangan upload ZIP sebagai satu file dan jangan simpan semua isi di folder tambahan.
2. Commit ke branch `main` atau `master`.
3. Buka tab **Actions**, pilih **Build Mini Arena Flutter APK**, lalu buka proses build terbaru.
4. Jika statusnya hijau, unduh artifact **`mini-arena-split-apks`**.

Workflow akan mencoba membuat ulang file platform Android jika `android/gradlew` atau file wrapper-nya hilang, seperti yang dapat terjadi saat mengunggah file satu per satu melalui browser. Lalu workflow menjalankan hanya `flutter build apk --release --split-per-abi` supaya tidak membuat APK universal tambahan.

## Pilih APK yang cocok

- `app-arm64-v8a-release.apk` — pilihan yang biasanya cocok untuk HP Android modern.
- `app-armeabi-v7a-release.apk` — perangkat ARM 32-bit yang lebih lama.
- `app-x86_64-release.apk` — perangkat/emulator Android berbasis x86_64.

APK split lebih kecil karena setiap file hanya membawa native library untuk satu arsitektur. Pasang APK yang cocok dengan arsitektur perangkat; jangan perlu memasang ketiganya.

## Build manual

Dengan Flutter SDK terpasang:

```bash
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```

Catatan: build Actions menggunakan signing debug bawaan untuk memudahkan pengujian. Untuk rilis publik/Play Store, konfigurasi signing release sendiri.
