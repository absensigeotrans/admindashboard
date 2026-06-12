'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/context/AuthContext';
import { supabase } from '@/lib/supabase';
import { toast } from '@/components/ui/Toast';
import { Calendar, FileText, CheckCircle, Clock, XCircle, Lock, Eye, EyeOff } from 'lucide-react';

export default function EmployeePasswordRequestPage() {
  const { user } = useAuth();
  
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [requests, setRequests] = useState<any[]>([]);
  const [loadingHistory, setLoadingHistory] = useState(true);

  // Password visibility
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const fetchRequestHistory = useCallback(async () => {
    if (!user) return;
    setLoadingHistory(true);

    try {
      const { data, error } = await supabase
        .from('password_change_requests')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setRequests(data || []);
    } catch (err) {
      console.error('Error fetching password requests:', err);
      toast.error('Gagal memuat riwayat pengajuan');
    } finally {
      setLoadingHistory(false);
    }
  }, [user]);

  useEffect(() => {
    fetchRequestHistory();
  }, [fetchRequestHistory]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    if (!newPassword) {
      toast.error('Password baru wajib diisi!');
      return;
    }

    if (newPassword.length < 8) {
      toast.error('Password baru minimal 8 karakter!');
      return;
    }

    if (newPassword !== confirmPassword) {
      toast.error('Konfirmasi password tidak cocok!');
      return;
    }

    setIsSubmitting(true);

    try {
      const { error } = await supabase
        .from('password_change_requests')
        .insert({
          user_id: user.id,
          new_password: newPassword,
          status: 'pending',
        });

      if (error) throw error;

      toast.success('Pengajuan ganti password berhasil dikirim');
      setNewPassword('');
      setConfirmPassword('');
      fetchRequestHistory();
    } catch (err) {
      console.error('Error submitting password request:', err);
      toast.error('Gagal mengirim pengajuan');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'approved':
        return (
          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-green-500/10 text-green-400 border border-green-500/20 flex items-center gap-1">
            <CheckCircle className="w-3 h-3" /> DISETUJUI
          </span>
        );
      case 'rejected':
        return (
          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20 flex items-center gap-1">
            <XCircle className="w-3 h-3" /> DITOLAK
          </span>
        );
      default:
        return (
          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-yellow-500/10 text-yellow-400 border border-yellow-500/20 flex items-center gap-1">
            <Clock className="w-3 h-3" /> PENDING
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Info */}
      <div className="relative border-l-2 border-blue-500 pl-4 py-1">
        <h1 className="text-xl font-bold text-white tracking-wide">Pengajuan Ganti Password</h1>
        <p className="text-xs text-gray-400">Ajukan permohonan pergantian password akun Anda. Perubahan akan aktif setelah disetujui Admin.</p>
      </div>

      {/* Request Form */}
      <form onSubmit={handleSubmit} className="bg-gray-900 border border-gray-800 rounded-3xl p-5 space-y-4">
        <h2 className="text-sm font-bold text-gray-300 uppercase tracking-wider">Form Pengajuan</h2>

        {/* New Password */}
        <div className="space-y-1.5 relative">
          <label className="text-xs text-gray-400 font-semibold">Password Baru (Minimal 8 Karakter)</label>
          <div className="relative">
            <input
              type={showNewPassword ? 'text' : 'password'}
              required
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Masukkan password baru"
              className="w-full bg-gray-850 border border-gray-800 rounded-xl pl-3 pr-10 py-2.5 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-blue-500"
            />
            <button
              type="button"
              onClick={() => setShowNewPassword(!showNewPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-gray-500 hover:text-gray-450 rounded"
            >
              {showNewPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* Confirm New Password */}
        <div className="space-y-1.5 relative">
          <label className="text-xs text-gray-400 font-semibold">Konfirmasi Password Baru</label>
          <div className="relative">
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              required
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Ulangi password baru"
              className="w-full bg-gray-850 border border-gray-800 rounded-xl pl-3 pr-10 py-2.5 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-blue-500"
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-gray-500 hover:text-gray-450 rounded"
            >
              {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={isSubmitting}
          className={`w-full py-3.5 rounded-2xl font-bold text-sm tracking-wide shadow-md active:scale-[0.98] transition-all flex items-center justify-center gap-2 ${
            isSubmitting
              ? 'bg-gray-800 text-gray-600 cursor-not-allowed border border-gray-700/50 shadow-none'
              : 'bg-gradient-to-r from-blue-600 to-blue-500 text-white hover:brightness-110 active:brightness-95'
          }`}
        >
          {isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan'}
        </button>
      </form>

      {/* History */}
      <div className="space-y-3">
        <h2 className="text-sm font-bold text-gray-400 uppercase tracking-wider pl-1">Riwayat Pengajuan</h2>

        {loadingHistory ? (
          <div className="space-y-2">
            {[1, 2].map((n) => (
              <div key={n} className="h-20 bg-gray-900 border border-gray-800 rounded-2xl animate-pulse" />
            ))}
          </div>
        ) : requests.length === 0 ? (
          <div className="bg-gray-900 border border-gray-850 rounded-2xl p-6 text-center text-gray-500 text-xs">
            Belum ada riwayat pengajuan ganti password.
          </div>
        ) : (
          <div className="space-y-3">
            {requests.map((request) => (
              <div
                key={request.id}
                className="bg-gray-900 border border-gray-850 rounded-2xl p-4 space-y-3 relative overflow-hidden shadow-sm"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 text-xs font-bold text-white font-mono">
                      <Lock className="w-3.5 h-3.5 text-blue-500 shrink-0" />
                      <span>Password diajukan: {request.new_password}</span>
                    </div>
                    <p className="text-[10px] text-gray-500 flex items-center gap-1">
                      <Calendar className="w-3 h-3 text-blue-500" />
                      Diajukan: {new Date(request.created_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                  {getStatusBadge(request.status)}
                </div>

                {/* Admin notes (if responded) */}
                {request.admin_notes && (
                  <div className="bg-blue-950/20 border border-blue-900/20 p-2.5 rounded-xl text-xs text-gray-400 space-y-1">
                    <span className="font-bold text-blue-400 text-[10px] uppercase">Catatan Admin:</span>
                    <p className="italic">"{request.admin_notes}"</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
