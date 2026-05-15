# GeoAttend Pro

**Geofencing-based Attendance System** for Pertamina Trans Kontinental

A modern attendance tracking application using GPS geofencing technology. Employees can only clock in/out when physically present within a configurable radius of the office location.

## Features

### Employee Features
- **Digital Clock Display** - Real-time clock showing current date/time
- **GPS-based Check In/Out** - Uses browser geolocation API (web) / device GPS (mobile)
- **Interactive Map** - Visualize office location and geofence radius
- **Distance Indicator** - Shows real-time distance to office with status (within/outside range)
- **Attendance History** - View personal attendance records

### Admin/HR Features
- **Dashboard Statistics** - Overview of present, late, and outside-radius employees
- **Employee Management** - View all employees and their departments
- **Office Location Management** - Configure multiple office locations with custom geofence radius
- **Real-time Activity Log** - Monitor recent attendance activities

### Technical Features
- **Server-side Validation** - Haversine formula calculates distance server-side to prevent manipulation
- **Row Level Security (RLS)** - PostgreSQL RLS policies protect user data
- **Mobile Responsive** - Works on desktop and mobile devices
- **Toast Notifications** - User feedback for all actions

## Tech Stack

### Web (Next.js Admin)
- **Frontend**: Next.js 16 + React 19 + TypeScript + Tailwind CSS 4
- **Maps**: Leaflet.js with OpenStreetMap (no API key required)
- **Icons**: Lucide React

### Mobile (Flutter)
- **Framework**: Flutter + Dart
- **Maps**: flutter_map with OpenStreetMap
- **GPS**: geolocator + flutter_background_geolocation

### Shared Backend
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth with email/password
- **Date**: date-fns (web) / intl (mobile)

## Project Structure

```
geoattend-pro/                              ← Root repository
│
├── 🌐 WEB (Next.js Admin)
│   ├── src/
│   │   ├── app/                            ← Next.js App Router pages
│   │   │   ├── admin/                      ← Admin dashboard (8 pages)
│   │   │   │   ├── page.tsx                ← Dashboard statistics
│   │   │   │   ├── employees/page.tsx      ← Employee management
│   │   │   │   ├── offices/page.tsx        ← Office CRUD
│   │   │   │   ├── reports/page.tsx        ← Reports + CSV/PDF export
│   │   │   │   ├── leave-requests/page.tsx ← Leave approval
│   │   │   │   ├── settings/page.tsx       ← System settings
│   │   │   │   ├── activity-logs/page.tsx  ← Audit trail
│   │   │   │   └── monitoring/page.tsx     ← Real-time monitoring
│   │   │   ├── history/page.tsx            ← Attendance history
│   │   │   ├── login/page.tsx              ← Auth (login/register)
│   │   │   ├── layout.tsx                  ← Root layout
│   │   │   ├── page.tsx                    ← Main attendance page
│   │   │   └── globals.css                 ← Global styles
│   │   ├── components/                     ← React components
│   │   │   ├── admin/                      ← Admin-specific components
│   │   │   │   └── Sidebar.tsx             ← Admin sidebar nav
│   │   │   ├── ui/                         ← Reusable UI components
│   │   │   │   ├── Badge.tsx
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── DateRangePicker.tsx
│   │   │   │   ├── FormInput.tsx
│   │   │   │   ├── Modal.tsx
│   │   │   │   ├── Pagination.tsx
│   │   │   │   ├── SearchInput.tsx
│   │   │   │   ├── StatsCard.tsx
│   │   │   │   ├── Table.tsx
│   │   │   │   ├── Tabs.tsx
│   │   │   │   └── Toast.tsx
│   │   │   ├── AttendanceButton.tsx
│   │   │   ├── AttendancePage.tsx
│   │   │   ├── DigitalClock.tsx
│   │   │   ├── DistanceIndicator.tsx
│   │   │   ├── Map.tsx                     ← Leaflet map
│   │   │   └── Toast.tsx
│   │   ├── context/
│   │   │   └── AuthContext.tsx             ← Auth state management
│   │   ├── hooks/                          ← Custom React hooks
│   │   │   ├── useActivityLogs.ts
│   │   │   ├── useAdminSettings.ts
│   │   │   ├── useAttendance.ts
│   │   │   ├── useEmployees.ts
│   │   │   ├── useGeolocation.ts
│   │   │   ├── useLeaveRequests.ts
│   │   │   ├── useOffices.ts
│   │   │   └── useReports.ts
│   │   ├── lib/                            ← Utilities
│   │   │   ├── supabase.ts                 ← Supabase client
│   │   │   ├── utils.ts                    ← Haversine + formatters
│   │   │   └── database.types.ts           ← Supabase TypeScript types
│   │   └── types/
│   │       └── index.ts                    ← Core TypeScript interfaces
│   ├── public/                             ← Static assets
│   ├── package.json                        ← Web dependencies
│   ├── next.config.ts                      ← Next.js config
│   ├── tsconfig.json                       ← TypeScript config
│   ├── postcss.config.mjs                  ← PostCSS config
│   ├── eslint.config.mjs                   ← ESLint config
│   └── .env.local                          ← Web environment variables
│
├── 📱 MOBILE (Flutter App)
│   ├── lib/
│   │   ├── main.dart                       ← Flutter entry point
│   │   ├── models/
│   │   │   └── attendance_model.dart       ← Data models
│   │   ├── screens/
│   │   │   ├── admin_screen.dart           ← Admin panel
│   │   │   ├── dashboard_screen.dart       ← Main dashboard + map
│   │   │   ├── history_screen.dart         ← Attendance history
│   │   │   ├── leave_request_screen.dart   ← Leave requests
│   │   │   ├── login_screen.dart           ← Login
│   │   │   ├── registration_screen.dart    ← Register
│   │   │   └── shift_selection_screen.dart ← Shift selection
│   │   └── services/
│   │       ├── admin_service.dart          ← Admin operations
│   │       ├── auth_service.dart           ← Auth (login/register)
│   │       ├── biometric_service.dart      ← Fingerprint/Face ID
│   │       ├── database_helper.dart        ← SQLite (offline support)
│   │       ├── leave_service.dart          ← Leave CRUD
│   │       ├── location_service.dart       ← GPS + Haversine
│   │       ├── notification_service.dart   ← Local notifications
│   │       ├── report_service.dart         ← PDF generation
│   │       └── sync_service.dart           ← Offline sync
│   ├── android/                            ← Android platform files
│   ├── ios/                                ← iOS platform files
│   ├── windows/                            ← Windows platform files
│   ├── test/
│   │   └── widget_test.dart                ← Flutter widget tests
│   ├── pubspec.yaml                        ← Flutter dependencies
│   ├── analysis_options.yaml               ← Flutter linting rules
│   └── .dart_tool/                         ← Dart build cache
│
├── 🗄️ SHARED
│   ├── supabase/
│   │   ├── migrations/                     ← Database migrations
│   │   │   ├── 001_create_profiles.sql
│   │   │   ├── 002_create_offices.sql
│   │   │   ├── 003_create_shifts.sql
│   │   │   ├── 004_create_user_shifts.sql
│   │   │   ├── 005_create_attendance.sql
│   │   │   ├── 006_create_leave_requests.sql
│   │   │   ├── 007_create_rls_policies.sql
│   │   │   ├── 008_seed_data.sql
│   │   │   ├── 009_create_functions.sql
│   │   │   ├── 010_create_admin_account.sql
│   │   │   └── 011_fix_schema_mismatches.sql
│   │   └── config.toml                     ← Supabase CLI config
│   └── .github/workflows/                  ← CI/CD
│       ├── supabase-migrations.yml         ← Auto-apply migrations
│       └── deploy-migrations.yml           ← Deploy workflow
│
├── 📄 DOCUMENTATION
│   ├── README.md                           ← This file
│   ├── PRD.md                              ← Product Requirements Document
│   ├── PROGRESS.md                         ← Progress tracker
│   ├── ARCHITECTURE.md                     ← System architecture
│   ├── SCHEMA_FIX_CHECKLIST.md             ← Schema fix checklist
│   ├── AGENTS.md                           ← AI agent rules
│   └── CLAUDE.md                           ← Claude-specific notes
│
└── .gitignore                              ← Git ignore rules
```

## Setup Instructions

### Web (Next.js Admin)

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Environment Variables**
   Create `.env.local` in project root:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Run Development Server**
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000)

### Mobile (Flutter App)

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Environment Variables**
   Create `.env` in project root:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Run Development**
   ```bash
   flutter run
   ```

### Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the database migrations in `supabase/migrations/` (see Migration Files section below)
3. Enable Email provider in Authentication > Providers
4. Add your site URL to Authentication > URL Configuration

### Database Schema

The migrations create:
- `profiles` - User information with role (employee/admin)
- `offices` - Office locations with geofence radius
- `attendance` - Attendance records with GPS coordinates
- `attendance_logs` - Audit trail for system activities
- `shifts` - Work shift configurations
- `leave_requests` - Leave request management

## Usage

### First Time Setup

1. Sign up as a new user - the first user will be assigned the "admin" role by default
2. Add an office location via Admin > Office Locations
3. Employees can then register and use the attendance system

### For Employees

1. Login with your email and password
2. Allow location access when prompted
3. View the map showing your location relative to the office
4. Clock In when within the geofence radius
5. Clock Out when leaving

### For Admins

1. Access the dashboard via "Admin" link in header
2. View daily statistics
3. Manage office locations and geofence settings
4. View all employee attendance records

## Geofencing Logic

The system uses the **Haversine Formula** to calculate the great-circle distance between the employee's GPS coordinates and the office location. This calculation is performed:

1. **Client-side** - For UI feedback and distance display
2. **Server-side** - Via PostgreSQL trigger to prevent GPS spoofing

Validation rules:
- `distance <= geofence_radius` → Valid (green)
- `distance > geofence_radius` → Invalid (red, cannot clock in)
- After 9:00 AM → Status = "late"

## Migration Files

Run these migrations in order in `supabase/migrations/`:

```
supabase/migrations/
├── 001_create_profiles.sql
├── 002_create_offices.sql
├── 003_create_shifts.sql
├── 004_create_user_shifts.sql
├── 005_create_attendance.sql
├── 006_create_leave_requests.sql
├── 007_create_rls_policies.sql
├── 008_seed_data.sql
├── 009_create_functions.sql
├── 010_create_admin_account.sql
└── 011_fix_schema_mismatches.sql  ← PENTING: fix trigger + kolom leave_requests
```

> **Note**: Ada file `001_initial_schema.sql`, `002_admin_settings.sql`, `003_leave_requests.sql` yang merupakan versi lama/alternatif. Gunakan set migrasi di atas (001-011) sebagai sumber utama.

## Deployment

### Web - Vercel (Recommended)

1. Push code to GitHub
2. Connect repository to Vercel
3. Add environment variables in Vercel dashboard
4. Deploy

### Web - Other Platforms

```bash
npm run build
```

### Mobile - Build APK

```bash
flutter build apk
```

### Mobile - Build iOS

```bash
flutter build ios
```

## Security Considerations

- **RLS Policies** restrict data access to authorized users only
- **Server-side distance calculation** prevents client-side GPS manipulation
- **Environment variables** protect Supabase credentials
- **HTTPS required** for production (geolocation API requires secure context)

## 🤖 AI Development Guide

### Two Apps, One Repository

Repository ini berisi **dua aplikasi** dalam satu root directory yang sharing Supabase backend:

| Application | Source Path | Framework | Config File |
|---|---|---|---|
| **Web (Next.js Admin)** | `src/` | Next.js 16 + TypeScript | `package.json` |
| **Mobile (Flutter App)** | `lib/` | Flutter + Dart | `pubspec.yaml` |

### Where to Update

| Task | Update Location |
|---|---|
| Web UI, pages, components | `src/app/`, `src/components/` |
| Web hooks, context, utils | `src/hooks/`, `src/context/`, `src/lib/` |
| Web dependencies | `package.json` (root) |
| Mobile screens, UI | `lib/screens/` |
| Mobile models, logic | `lib/models/`, `lib/services/` |
| Mobile dependencies | `pubspec.yaml` (root) |
| Database migrations | `supabase/migrations/` (shared) |
| Web environment | `.env.local` (root) |
| Mobile environment | `.env` (root) |

### Framework Path Reference

| Framework | Source Code | Config | Env File | Dev Command |
|---|---|---|---|---|
| **Next.js (Web)** | `src/` | `package.json`, `next.config.ts` | `.env.local` | `npm run dev` |
| **Flutter (Mobile)** | `lib/` | `pubspec.yaml` | `.env` | `flutter run` |

### Common AI Mistakes to Avoid

- ❌ Jangan buat file Next.js di `lib/` — itu milik Flutter
- ❌ Jangan buat file Flutter di `src/` — itu milik Next.js
- ❌ Jangan install npm packages ke `pubspec.yaml`
- ❌ Jangan install flutter packages ke `package.json`
- ✅ Web components → `src/components/`
- ✅ Mobile screens → `lib/screens/`
- ✅ Supabase client Web → `src/lib/supabase.ts`
- ✅ Supabase client Mobile → `lib/services/supabase_service.dart`

### Linting & Type Checking

```bash
# Web (Next.js)
npx tsc --noEmit
npm run lint

# Mobile (Flutter)
flutter analyze
```

### Important Notes for AI

1. **Jangan campur** kode Flutter (`lib/`) dan Next.js (`src/`) — keduanya terpisah
2. **Kedua app** connect ke Supabase project yang sama
3. **Database migrations** ada di `supabase/migrations/` (shared, bukan terpisah)
4. Saat nambah kolom database baru, pastikan kedua app bisa mengaksesnya
5. Web menggunakan `src/lib/supabase.ts`, mobile menggunakan `lib/services/supabase_service.dart`

## License

© Pertamina Trans Kontinental. All rights reserved.
