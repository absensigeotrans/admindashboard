import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-admin';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { userId } = body;

    if (!userId) {
      return NextResponse.json(
        { error: 'User ID wajib diisi' },
        { status: 400 }
      );
    }

    // 1. Dapatkan info profile sebelum dihapus untuk log/response
    const { data: profile, error: profileFetchError } = await supabaseAdmin
      .from('profiles')
      .select('full_name, email')
      .eq('id', userId)
      .maybeSingle();

    if (profileFetchError) {
      return NextResponse.json(
        { error: 'Gagal mencari profil karyawan' },
        { status: 500 }
      );
    }

    if (!profile) {
      return NextResponse.json(
        { error: 'Karyawan tidak ditemukan' },
        { status: 404 }
      );
    }

    // 2. Hapus user di auth.users menggunakan admin client
    // Hal ini otomatis mentrigger CASCADE DELETE pada tabel profiles, attendance, leave_requests, dll.
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);

    if (deleteError) {
      return NextResponse.json(
        { error: `Gagal menghapus akun: ${deleteError.message}` },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: `Akun karyawan ${profile.full_name || profile.email} berhasil dihapus beserta seluruh riwayat datanya`,
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Gagal menghapus karyawan' },
      { status: 500 }
    );
  }
}
