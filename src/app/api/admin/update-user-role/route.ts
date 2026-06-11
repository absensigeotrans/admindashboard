import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-admin';

export const runtime = 'edge';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { user_id, role, full_name, shift_type } = body;

    if (!user_id) {
      return NextResponse.json(
        { error: 'user_id wajib diisi' },
        { status: 400 }
      );
    }

    // 1. Update profiles table
    const profileUpdates: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };
    if (role !== undefined) profileUpdates.role = role;
    if (full_name !== undefined) profileUpdates.full_name = full_name;
    if (shift_type !== undefined) profileUpdates.shift_type = shift_type;

    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update(profileUpdates)
      .eq('id', user_id);

    if (profileError) {
      return NextResponse.json(
        { error: profileError.message },
        { status: 500 }
      );
    }

    // 2. Sync role to auth.users if role changed
    if (role) {
      const { error: authError } = await supabaseAdmin.auth.admin.updateUserById(
        user_id,
        { user_metadata: { role } }
      );

      if (authError) {
        return NextResponse.json(
          { error: authError.message },
          { status: 500 }
        );
      }
    }

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Gagal update role' },
      { status: 500 }
    );
  }
}
