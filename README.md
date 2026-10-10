# Mini Arena — Flutter Edition

Game shooter 2D side-scrolling berbasis Flutter, dibangun ulang dari base HTML yang diberikan.

## Fitur
- Loading screen lalu lobby dengan tombol **MULAI MISI** di kanan bawah.
- Arena side-scrolling dengan kamera mengikuti karakter.
- Karakter animasi lari, lompat, jetpack, tembakan, health bar, dan lima bot AI.
- Kontrol sentuh: joystick gerak di kiri, joystick bidik/tembak di kanan, lompat, jetpack, dan tombol tembak.
- HUD HP, jumlah bot tersisa, eliminasi, serta layar hasil misi.
- Orientasi landscape dan immersive mode untuk layar game penuh.
- Menggunakan CustomPainter dan timer frame untuk menggambar game tanpa aset eksternal; aset gambar bisa ditambahkan belakangan.

## Build
Pastikan Flutter stable dan Android SDK sudah terpasang.

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

Project ini berupa game offline lokal. Belum ada multiplayer online atau impor gambar dari galeri di gameplay; karakter dan arena saat ini digambar langsung oleh Flutter agar project bisa langsung dibangun tanpa mengunduh aset.
