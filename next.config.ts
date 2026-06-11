import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export', // 👈 WAJIB: Mengubah Next.js menjadi file statis murni buat Cloudflare Pages
  images: {
    unoptimized: true, // 👈 WAJIB: Mematikan optimasi gambar bawaan server karena tidak pakai hosting Node.js
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdnjs.cloudflare.com',
      },
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },
  // Catatan: Fungsi async headers() dihapus karena tidak didukung oleh Static Export ('output: 'export'').
  // Untuk pengaturan keamanan header (X-Frame-Options, dll) di Cloudflare Pages, 
  // nanti bisa diatur langsung lewat file _headers di folder public jika memang sangat butuh.
};

export default nextConfig;