
    # Product Requirements Document (PRD): GeoAttend Pro

**Project Name:** GeoAttend Pro - Pertamina Trans Kontinental Edition  
**Version:** 1.0  
**Status:** Ready for Development  
**Author:** Muhamad Dava Rayhan  

---

## 1. Project Overview
GeoAttend Pro adalah aplikasi absensi berbasis web yang menggunakan teknologi **Geofencing**. Aplikasi ini memastikan karyawan hanya dapat melakukan absensi jika berada di dalam radius yang ditentukan dari koordinat kantor yang valid.

### Goals
- Mencegah kecurangan absensi (fake location).
- Memberikan visibilitas real-time bagi HR untuk memantau kehadiran.
- Automasi penghitungan jarak antara karyawan dan lokasi kantor.

---

## 2. User Roles & Personas
| Role | Deskripsi | Hak Akses Utama |
| :--- | :--- | :--- |
| **Employee** | Karyawan di lapangan/kantor | Clock-in/out, lihat jarak ke kantor, riwayat pribadi. |
| **HR / Admin** | Pengelola SDM | Dashboard statistik, manajemen lokasi kantor, pantau log semua karyawan. |

---

## 3. Functional Requirements

### 3.1 Geofencing & Location Engine
- **Geolocation Access:** Sistem harus meminta izin akses GPS pengguna saat masuk ke halaman absensi.
- **Distance Calculation:** Menggunakan **Haversine Formula** untuk menghitung jarak antara koordinat user ($lat_1, lng_1$) dan koordinat kantor ($lat_2, lng_2$).
- **Validation Logic:** 
    - Jika `distance <= geofence_radius`, status = **Valid** (Tombol aktif).
    - Jika `distance > geofence_radius`, status = **Invalid** (Tombol nonaktif & muncul peringatan).

### 3.2 Core Features
- **Authentication:** Login menggunakan email dan password via Supabase Auth.
- **Interactive Map:** Menampilkan peta (Leaflet.js) dengan marker lokasi user dan lingkaran radius kantor.
- **Attendance Action:** Tombol "Clock In" dan "Clock Out" yang mencatat timestamp dan koordinat ke database.
- **HR Dashboard:** 
    - Ringkasan statistik (Total Hadir, Telat, Luar Radius).
    - Monitoring log aktivitas terbaru dengan detail jarak.

---

## 4. Technical Stack
- **Frontend:** Next.js (App Router), Tailwind CSS.
- **Icons & UI:** Lucide React, Headless UI / Shadcn UI.
- **Maps:** Leaflet.js (OpenStreetMap) untuk visualisasi peta tanpa API Key berbayar.
- **Backend & Database:** Supabase (PostgreSQL).
- **Security:** Row Level Security (RLS) di Supabase untuk membatasi akses data.

---

## 5. Database Schema (Supabase)
Berdasarkan perancangan ERD yang sudah dibuat:

### Table: `profiles`
Menyimpan data identitas karyawan.
- `id` (uuid, PK), `email` (text), `full_name` (text), `role` (user_role), `department` (text).

### Table: `offices`
Menyimpan titik pusat koordinat geofence.
- `id` (uuid, PK), `name` (text), `latitude` (float8), `longitude` (float8), `geofence_radius` (int4).

### Table: `attendance`
Menyimpan data transaksi absensi.
- `id` (uuid, PK), `user_id` (uuid, FK), `check_in_time` (timestamptz), `is_valid` (bool), `distance_from_office` (float8), `status` (attendance_status).

### Table: `attendance_logs`
Menyimpan audit trail aktivitas sistem.
- `id` (uuid, PK), `attendance_id` (uuid, FK), `action` (text), `details` (jsonb).

---

## 6. UI/UX Specifications
- **Theme:** Clean, professional, mobile-responsive.
- **Employee View:** Fokus pada jam digital, indikator jarak, dan tombol aksi yang besar.
- **Admin View:** Sidebar navigasi untuk berpindah antara Dashboard, Data Karyawan, dan Pengaturan Lokasi.
- **Feedback:** Penggunaan toast notifications (berhasil/gagal) untuk setiap aksi absensi.

---

## 7. Security & Business Rules
1. **Server-Side Validation:** Jarak harus dihitung ulang di backend atau via database trigger sebelum data disimpan untuk mencegah manipulasi GPS di sisi client.
2. **Device Constraints:** Satu akun hanya boleh aktif di satu perangkat (opsional untuk pengembangan tahap lanjut).
3. **RLS Policies:** 
    - `profiles`: User hanya bisa melihat data miliknya.
    - `attendance`: User hanya bisa memasukkan data jika `auth.uid() == user_id`.

---