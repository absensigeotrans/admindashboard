# 📝 PROGRESS TRACKER: GeoAttend PTK
*(File ini adalah source of truth untuk progress proyek. Update checklist ini setiap kali ada fitur baru yang selesai).*

## 🎯 Status: Tahap 2 (Selesai Core Feature)

---

## ✅ TAHAP 1: CORE INFRASTRUCTURE & AUTH (SELESAI)
- [x] Inisialisasi Project Flutter (`geo_attend_ptk`)
- [x] Setup `pubspec.yaml` dependencies (Supabase, Geolocation, Provider, dll)
- [x] Struktur Folder (`lib/screens`, `services`, `models`, dll)
- [x] Migrasi Database Supabase (Single Office Jakarta) + RLS + Functions
- [x] Setup Native Android (`AndroidManifest.xml` permissions)
- [x] Setup Native iOS (`Info.plist` usage descriptions & background modes)
- [x] `AuthService`: Integrasi Login & Register Supabase
- [x] `AuthWrapper`: Navigasi dinamis (Belum Login -> Pending -> Dashboard)
- [x] UI: `ShiftSelectionScreen`, `LoginScreen`, `RegistrationScreen`

## ✅ TAHAP 2: CORE FEATURE: ATTENDANCE (SELESAI)
- [x] `LocationService`: Background tracking & Haversine calculation
- [x] Anti-Fraud: Fake GPS / Mock Location Detection
- [x] `DashboardScreen`: Integrasi Map (`flutter_map`)
- [x] `DashboardScreen`: Indikator jarak real-time & validasi geofence
- [x] Logika Check-In / Check-Out insert ke tabel `attendance` Supabase

## ✅ TAHAP 3: RIWAYAT ABSENSI (SELESAI)
- [x] `HistoryScreen`: Tampilkan data absensi dari tabel `attendance` Supabase
- [x] Filter tanggal dengan `DateRangePicker`
- [x] Summary card (Total, Hadir, Terlambat)
- [x] `_AttendanceCard`: Detail per hari (check-in, check-out, jarak, durasi kerja)
- [x] Navigasi dari Dashboard ke HistoryScreen via tombol icon history

## ✅ TAHAP 4: ADMIN PANEL (SELESAI)
- [x] `AdminService`: Fetch semua user & toggle `is_active`
- [x] `AdminScreen`: Tab Pending & Tab Semua User
- [x] Tombol Approve/Nonaktifkan user
- [x] Role-based redirect (`admin` → AdminScreen, lainnya → Dashboard)
- [x] Role `admin` ditambahkan ke opsi registrasi

---

## ✅ TAHAP 5: OFFLINE SUPPORT / SYNC (SELESAI)
- [x] `DatabaseHelper`: SQLite dengan tabel `pending_attendance` dan `sync_log`
- [x] `SyncService`: Auto-detect koneksi, auto-sync setiap 5 menit
- [x] `_handleAttendance`: Check-In/Out online → Supabase, offline → SQLite
- [x] Banner "Offline Mode" & indikator "pending" di Dashboard
- [x] Pull-to-refresh History & Admin panels

## ✅ TAHAP 6: PENGGAJUAN CUTI (SELESAI)
- [x] `LeaveService`: CRUD pengajuan cuti (submit, cancel, approve/reject admin)
- [x] `LeaveRequestScreen`: Tab Ajukan + Tab Riwayat
- [x] Form: Pilih jenis cuti, tanggal mulai/selesai, alasan
- [x] 4 jenis cuti: Tahunan, Sakit, Darurat, Izin Tidak Hadir
- [x] Auto-kalkulasi total hari cuti
- [x] Card riwayat dengan status (Menunggu/Disetujui/Ditolak/Dibatalkan)
- [x] Tombol Batalkan untuk pengajuan berstatus Pending
- [x] Navigasi dari Dashboard ke LeaveRequestScreen
- [x] FAB "X Menunggu" di LeaveRequestScreen saat ada pengajuan pending

## ✅ TAHAP 7: NOTIFIKASI LOKAL (SELESAI)
- [x] `NotificationService`: Implementasi channel (Absensi, Sinkronisasi, Cuti, Pengingat)
- [x] Inisialisasi & Izin: Dipanggil saat startup di `main.dart`
- [x] Integrasi Absensi: Notif sukses check-in/out di `DashboardScreen`
- [x] Integrasi Sinkronisasi: Notif sukses/gagal sync di `SyncService`
- [x] Integrasi Keamanan: Notif alert saat Fake GPS terdeteksi di `LocationService`
- [x] Integrasi Cuti: Notif saat pengajuan terkirim di `LeaveService`

---

## ✅ TAHAP 8: LAPORAN PDF (SELESAI)
- [x] `ReportService`: Implementasi PDF generation menggunakan paket `pdf` dan `printing`.
- [x] Template Laporan: Header PTK, data karyawan, tabel absensi, dan footer tanda tangan.
- [x] Integrasi UI: Tambah tombol export PDF di `HistoryScreen` dengan filter periode yang aktif.
- [x] Print Preview & Share: Mendukung pratinjau cetak dan berbagi file PDF secara native.

---

## 🚧 TAHAP 9: NEXT ACTION ITEMS (TO-DO)
*(Silakan dilanjutkan oleh AI Agent berikutnya)*

- [x] **Biometric Login**: Implementasi Fingerprint/Face ID untuk login cepat via `local_auth`.
- [x] **Pengecualian Geofence Driver**: Driver/Sopir bisa absensi di mana saja (bebas radius 100m).
- [ ] **Pengingat Terjadwal**: Aktifkan fitur `scheduleCheckInReminder` di Settings UI.
- [ ] **Dashboard Analytics**: Tambahkan grafik statistik bulanan di `StatisticsScreen`.

---
**Penting untuk Diperhatikan:**
- **URL Supabase:** `https://yoykktgggvvoigrbtvhq.supabase.co`
- Aplikasi difokuskan pada **satu kantor saja** (Kantor Pusat PTK Jakarta). Cabang lain sudah dihilangkan dari PRD dan database.
- State management menggunakan `Provider`. Lanjutkan menggunakan pola ini untuk servis baru.
