# 🚁 Custom Freecam Simulator Pro (Roblox)

Script kamera sinematik dan simulator penerbangan Drone FPV paling canggih yang dirancang khusus untuk Roblox. Dibuat dengan antarmuka (UI) dalam game berlapis penuh yang bisa Anda modifikasi secara *real-time*!

---

## 🌟 Fitur Utama

Skrip ini memiliki 3 **Mode Penerbangan Utama** yang mendefinisikan pergerakan kamera Anda:

1. **Normal Mode (Sinematik Standar)**
   * Terbang bebas layaknya Freecam bawaan Roblox, namun jauh lebih halus.
   * Sangat mulus (*smoothing*) untuk perekaman video.
   * Kontrol miring (*Roll*) manual bebas hambatan.

2. **Drone Mode (FPV Simulator Profesional)** 🛫
   Meniru algoritma fisika simulator drone sungguhan seperti *Liftoff* atau *VelociDrone*.
   * Didesain khusus untuk dimainkan menggunakan **Gamepad / Controller (Joystick)**.
   * Punya 3 gaya terbang: **Angle** (Otomatis stabil), **Acro** (Terbang bebas ala profesional), dan **3D** (Rotasi motor bolak-balik untuk terbang terbalik).
   * **Fisika Realistis Terintegrasi:** 
      * Kelembaman Tensor *Moment of Inertia* (Pitch/Roll/Yaw terasa punya berat berbeda).
      * *Propwash Oscillation* (Bergetar ketika menembus angin dari baling-baling sendiri).
      * *Ground Effect* (Bantalan udara saat terbang dekat lantai).
      * *Asymmetric Motor Spool* (Reaksi delay gas baling-baling seperti drone asli).
   * **Sistem Betaflight Rates**: Pengaturan sensitivitas joystick sama persis dengan aplikasi konfigurasi *Betaflight* dunia nyata (RC Rate, Super Rate, Expo).

3. **Gyro Mode (Anti-Miring)**
   * Kamera Freecam melayang sangat lembut.
   * Secara otomatis mengembalikan keseimbangan (*auto-level*) ketika Anda tidak menggerakkan sumbu rotasi (seperti *gimbal* kamera DJi).

---

## 🎮 Cara Penggunaan (Kontrol Bawaan)

| Tombol Aksi | Kegunaan |
| :--- | :--- |
| **Shift + F** | Mengaktifkan / Mematikan Freecam. |
| **P** | Menampilkan / Menyembunyikan Menu UI Settings. |
| **G** | Mengunci kursor mouse di tengah layar / Melepas mouse untuk menekan UI. |
| **Z** | Mengganti orbit / Memutar kamera mengelilingi pemain Anda. |
| **Tombol H** | Mengaktifkan/Mematikan *Depth of Field* (Latar Belakang Blur). |
| **Q / E** | Turun / Naik (Di posisi Normal mode). Miring / *Roll* kiri atau kanan (Jika Roll dihidupkan). |

> **💡 TIP:** Saat Anda mengaktifkan UI pertama ditekannya tombol **`P`**, silakan telusuri pengaturan (Settings). Hampir **70+ Variabel** dapat diubah, mulai dari *Speed*, *Field of View*, sampai ke gravitasi Drone FPV!

---

## 📋 Cara Pasang & Pakai (Instalasi)

Anda punya dua opsi pemasangan: melalui Roblox Studio untuk game Anda sendiri, atau memakai aplikasi *Executor* agar skrip ini bisa dipakai terbang di game apapun!

**Opsi A: Menggunakan *Executor* (Main di Game Manapun)**
1. Salin seluruh teks kode dari file `customfreecam.lua`.
2. Buka aplikasi *Script Executor* favorit Anda (contoh: Synapse, KRNL, Delta, Xeno, dll) saat bermain di dalam *game* Roblox manapun.
3. *Paste* skripnya lalu tekan **Execute/Inject**. 
4. Notifikasi "Custom Freecam Aktif" akan muncul, tekan **Shift+F** untuk langsung menerbangkan drone di *map* game tersebut!

**Opsi B: Melalui Roblox Studio (Ditanam di Game Anda Sendiri)**
1. **Buka Roblox Studio**: Buka *place* atau game kreasi Anda.
2. Tempatkan skrip ini sebagai `LocalScript` di direktori jalurnya:
   * `StarterPlayer` > `StarterPlayerScripts`
3. Jika dieksekusi dengan benar, pemain Anda dapat menekan **Shift+F** dan membuka UI kontrol drone untuk memainkannya.

---

## 💾 Menyimpan Settingan (Import/Export)

Anda mendapatkan *settingan* fisik drone yang fantastis dan tidak ingin setelannya hilang saat keluar game?
* Buka **Settings Menu (P)** > Tab **General / Tools**.
* Cari dan klik opsi **Export Settings**. Munculah teks kode yang dimulai dari `FCv1|`.
* Simpan rentetan huruf dan teks itu di 'Notepad' Anda.
* Kapanpun Anda mau memainkan setelan itu lagi, tinggal tekan **Import Settings** lalu *Paste* kodenya! 

---
*Kode dibuat dalam standar Luau (Roblox Lua) berkualitas tinggi. Sepenuhnya teroptimasi untuk performa tanpa membebani FPS.*
