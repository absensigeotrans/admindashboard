# GeoAttend Pro

**Geofencing-based Attendance System** for Pertamina Trans Kontinental

A modern web application for employee attendance tracking using GPS geofencing technology. Employees can only clock in/out when physically present within a configurable radius of the office location.

## Features

### Employee Features
- **Digital Clock Display** - Real-time clock showing current date/time
- **GPS-based Check In/Out** - Uses browser geolocation API
- **Interactive Map** - Visualize office location and geofence radius using Leaflet
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

- **Frontend**: Next.js 16 + React 19 + TypeScript + Tailwind CSS 4
- **Maps**: Leaflet.js with OpenStreetMap (no API key required)
- **Icons**: Lucide React
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth with email/password
- **Date**: date-fns for date formatting

## Setup Instructions

### 1. Environment Variables

Create a `.env.local` file in the project root:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the database migration in `supabase/migrations/001_initial_schema.sql`
3. Enable Email provider in Authentication > Providers
4. Add your site URL to Authentication > URL Configuration

### 3. Database Schema

The migration creates:
- `profiles` - User information with role (employee/admin)
- `offices` - Office locations with geofence radius
- `attendance` - Attendance records with GPS coordinates
- `attendance_logs` - Audit trail for system activities

### 4. Install Dependencies

```bash
npm install
```

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

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

## Deployment

### Vercel (Recommended)

1. Push code to GitHub
2. Connect repository to Vercel
3. Add environment variables in Vercel dashboard
4. Deploy

### Other Platforms

Build the production bundle:
```bash
npm run build
```

## Security Considerations

- **RLS Policies** restrict data access to authorized users only
- **Server-side distance calculation** prevents client-side GPS manipulation
- **Environment variables** protect Supabase credentials
- **HTTPS required** for production (geolocation API requires secure context)

## Project Structure

```
geoattend-pro/
├── src/
│   ├── app/                    # Next.js app router pages
│   │   ├── page.tsx            # Main attendance page
│   │   ├── login/page.tsx      # Auth page
│   │   ├── history/page.tsx    # Attendance history
│   │   └── admin/              # Admin dashboard
│   ├── components/             # React components
│   │   ├── Map.tsx             # Leaflet map component
│   │   ├── DigitalClock.tsx    # Real-time clock
│   │   ├── AttendanceButton.tsx
│   │   └── ...
│   ├── hooks/                # Custom React hooks
│   │   ├── useGeolocation.ts
│   │   ├── useAttendance.ts
│   │   └── useOffices.ts
│   ├── context/              # React context
│   │   └── AuthContext.tsx
│   ├── lib/                  # Utilities
│   │   ├── supabase.ts
│   │   ├── utils.ts
│   │   └── database.types.ts
│   └── types/                # TypeScript types
│       └── index.ts
├── supabase/
│   └── migrations/             # Database migrations
└── public/                     # Static assets
```

## License

© Pertamina Trans Kontinental. All rights reserved.
