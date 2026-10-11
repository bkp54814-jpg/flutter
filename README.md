# VINZZX STUDIO Mobile Engine 0.2

Editor game 2D untuk Android dengan fokus pada workflow mobile.

## Fitur versi 0.2
- Import PNG dari galeri Android, termasuk PNG dengan transparansi.
- Sprite sheet cutter dengan pengaturan baris dan kolom (contoh 4×4 = 16 frame).
- Preview grid pemotongan, pilih frame dengan mengetuk sheet, dan strip thumbnail semua frame.
- Atur FPS 1–60, zoom tampilan sheet, serta ukuran frame dihitung otomatis dari ukuran gambar dan grid.
- Assign role asset: karakter/player, musuh, health, background, platform, projectile, efek, UI, atau lainnya.
- Scene editor dengan hierarchy, tambah/hapus objek, posisi dan ukuran objek, serta assignment sprite ke objek.
- Game preview sederhana untuk mengetes sprite animasi, gerak horizontal dengan drag, dan HP/damage dengan tap.
- Behavior script editor untuk menulis dan menyimpan template kode per asset.
- Save Project menyalin JSON project ke clipboard. Data PNG dimasukkan sebagai Base64 sehingga aset ikut berada di JSON.
- GitHub Actions membangun APK release terpisah per ABI (armeabi-v7a, arm64-v8a, x86_64).

## Cara build APK dari HP
1. Upload isi ZIP ini ke root repository GitHub (jangan upload ZIP sebagai satu file).
2. Buka tab **Actions** → **Build VINZZX STUDIO APK** → **Run workflow**.
3. Setelah workflow hijau, unduh artifact `vinzzx-studio-split-apks`.
4. Ekstrak artifact dan instal `app-arm64-v8a-release.apk` untuk kebanyakan HP Android modern 64-bit. Jika tidak cocok, gunakan APK ABI lain yang sesuai perangkat.

## Cara memakai editor
1. Tekan **IMPORT PNG**, lalu pilih PNG transparan dari galeri.
2. Buka **SPRITES**. Isi Rows dan Cols, misalnya 4 dan 4, atur FPS, lalu tekan **Potong / Apply**.
3. Ketuk kotak frame di sheet atau pilih frame dari strip bawah untuk memeriksa potongan.
4. Atur **Gambar ini sebagai**, misalnya Karakter / Player atau Nyawa / Health.
5. Di **SCENE**, tambah objek dan pilih asset pada Inspector.
6. Tekan **TEST GAME** untuk membuka preview; geser area game untuk menggerakkan player dan tap untuk mengetes pengurangan HP. Tekan Reset untuk mengulang.
7. Gunakan **SCRIPT** untuk menulis behavior, lalu Apply script agar tersimpan ke asset. Save Project menyalin JSON lengkap ke clipboard.

## Batasan yang perlu diketahui
- Ini adalah engine/editor mobile tahap awal, bukan pengganti penuh Unity/Godot. Preview saat ini adalah test arena sederhana untuk memeriksa sprite, animasi, posisi, dan HP.
- Editor kode saat ini menyimpan teks behavior ke project, tetapi **belum mengeksekusi Dart bebas**. Sistem runtime script/physics/gameplay penuh perlu dikembangkan sebagai tahap berikutnya.
- Grid cutter membagi sprite sheet secara merata; sheet yang punya margin, spacing, atau frame tidak seragam perlu disiapkan/crop lebih dulu.
- Project disalin sebagai JSON ke clipboard. Untuk project dengan PNG besar, JSON dapat sangat besar.
- Build harus diverifikasi lewat GitHub Actions karena build Flutter belum dijalankan di lingkungan pembuat ZIP.
