# Mini Arena Flutter

Proyek game Flutter 2D Mini Arena. Source code utama berada di `lib/main.dart`.

## Build APK otomatis di GitHub Actions

Workflow berada di `.github/workflows/build.yml` dan otomatis berjalan ketika ada commit/push ke branch `main` atau `master`. Workflow juga bisa dijalankan manual.

1. Upload/ekstrak semua isi ZIP ini ke **root repository GitHub**. Pastikan `pubspec.yaml`, folder `lib/`, folder `android/`, dan folder `.github/` terlihat langsung di halaman utama repository—jangan sampai semuanya masih berada di dalam folder tambahan.
2. Commit perubahan ke branch `main` atau `master`.
3. Buka tab **Actions** pada repository dan pilih workflow **Build Mini Arena Flutter APK**.
4. Tunggu sampai status hijau/`Success`.
5. Buka run yang selesai, lalu unduh artifact **mini-arena-android-apk**. Di dalamnya tersedia APK universal `app-release.apk` dan APK khusus arsitektur jika berhasil dibuat.

Jika workflow tidak muncul, buka **Settings → Actions → General** dan pastikan Actions diizinkan untuk repository tersebut. Jika build gagal, buka run di tab Actions, pilih job **Build Android APK**, lalu baca langkah pertama yang merah.

## Build manual

Dengan Flutter SDK terpasang:

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

Catatan: APK yang dibuat Actions memakai konfigurasi signing debug bawaan project untuk memudahkan pengujian. Untuk rilis publik/Play Store, buat konfigurasi signing release sendiri.
