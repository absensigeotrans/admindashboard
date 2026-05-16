# Push Migration ke Supabase

Step-by-step push migration lokal ke Supabase database.

## Prasyarat

- Supabase CLI sudah terinstall (`npx supabase --version`)
- Sudah login sekali (`npx supabase login`)
- Project sudah di-link (`npx supabase link`)

## Step (setiap kali ada migrasi baru)

```bash
# 1. Masuk ke project
cd "D:/new pertamna"

# 2. Push semua migrasi yang pending
npx supabase db push --include-all
```

## Setup Awal (cukup sekali)

Kalau clone repo baru atau first time:

```bash
# 1. Login dengan Personal Access Token
# Token: https://supabase.com/dashboard/account/tokens
npx supabase login --token "sbp_xxxxxxxxxxxxxxxx"

# 2. Link ke project
npx supabase link --project-ref yoykktgggvvoigrbtvhq

# 3. Push migrasi
npx supabase db push --include-all
```

## Notes

- **Database password** akan diminta saat `link` atau `push`.
  Cek/reset di: **Supabase Dashboard → Project Settings → Database → Database password**

- Token login tersimpan di `~/.supabase/`, jadi cukup generate sekali.

- Kalau error `Found local migration files to be inserted before the last migration`, jalankan dengan `--include-all`.
