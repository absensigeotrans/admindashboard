'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Toast } from '@/components/Toast';
import { Lock, Eye, EyeOff, Loader2, Sparkles } from 'lucide-react';
import Image from 'next/image';

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [checkingSession, setCheckingSession] = useState(true);
  const [hasSession, setHasSession] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [formVisible, setFormVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setFormVisible(true), 300);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    const checkSession = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session) {
          setHasSession(true);
        } else {
          // If no session, wait a brief moment in case the client SDK is still parsing the hash parameters
          await new Promise((resolve) => setTimeout(resolve, 1500));
          const { data: { session: retrySession } } = await supabase.auth.getSession();
          if (retrySession) {
            setHasSession(true);
          } else {
            setHasSession(false);
          }
        }
      } catch (err) {
        console.error('Error checking session:', err);
        setHasSession(false);
      } finally {
        setCheckingSession(false);
      }
    };

    checkSession();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password.length < 8) {
      setToast({ message: 'Kata sandi minimal harus 8 karakter', type: 'error' });
      return;
    }
    if (password !== confirmPassword) {
      setToast({ message: 'Konfirmasi kata sandi tidak cocok', type: 'error' });
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase.auth.updateUser({
        password: password,
      });

      if (error) {
        setToast({ message: error.message, type: 'error' });
      } else {
        setToast({ message: 'Kata sandi berhasil diperbarui!', type: 'success' });
        // Sign out to clear the temporary recovery session
        await supabase.auth.signOut();
        setTimeout(() => {
          router.push('/login');
        }, 2000);
      }
    } catch (err: any) {
      setToast({ message: err?.message || 'Gagal mengubah kata sandi', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  if (checkingSession) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#03045E] via-[#0077B6] to-[#00B4D8]">
        <div className="relative">
          <div className="absolute inset-0 bg-white/20 rounded-full blur-xl animate-pulse"></div>
          <div className="animate-spin rounded-full h-16 w-16 border-4 border-white/30 border-t-white"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex relative overflow-hidden">
      {/* Full-page Background Image */}
      <div className="fixed inset-0 z-0">
        <Image
          src="/images/bg-login.png"
          alt="Pertamina Trans Kontinental - Maritime Operations"
          fill
          className="object-cover"
          priority
        />
        <div className="absolute inset-0 bg-gradient-to-br from-[#03045E]/70 via-[#0077B6]/60 to-[#00B4D8]/50 backdrop-blur-sm"></div>
      </div>

      {/* Center Panel */}
      <div className="w-full flex items-center justify-center px-4 sm:px-6 py-8 relative z-10">
        <div className="w-full max-w-md transform transition-all duration-700 ease-out" style={{ opacity: formVisible ? 1 : 0, transform: formVisible ? 'translateY(0)' : 'translateY(20px)' }}>
          {/* Logo */}
          <div className="text-center mb-6 animate-fade-in">
            <div className="relative inline-block">
              <div className="absolute -inset-4 bg-[#90E0EF]/20 rounded-full blur-xl"></div>
              <Image
                src="/logo-ptk.png"
                alt="Pertamina Trans Kontinental"
                width={240}
                height={60}
                className="relative z-10"
              />
            </div>
          </div>

          {/* Glassmorphism Card */}
          <div className="relative group">
            <div className="absolute -inset-0.5 bg-gradient-to-r from-[#90E0EF]/50 via-[#0077B6]/50 to-[#90E0EF]/50 rounded-3xl blur opacity-30 group-hover:opacity-50 transition-opacity duration-500"></div>

            <div className="relative backdrop-blur-xl bg-white/80 rounded-3xl shadow-2xl border border-white/20 p-6 sm:p-8 lg:p-10">
              {!hasSession ? (
                <div className="text-center space-y-4 py-4">
                  <h2 className="text-xl sm:text-2xl font-bold text-red-600">
                    Tautan Tidak Valid atau Kedaluwarsa
                  </h2>
                  <p className="text-sm text-gray-650">
                    Tautan untuk mengatur ulang kata sandi Anda sudah tidak berlaku, kedaluwarsa, atau tidak sah. Silakan ajukan permintaan tautan baru di halaman login.
                  </p>
                  <button
                    onClick={() => router.push('/login')}
                    className="w-full py-3.5 bg-gradient-to-r from-[#03045E] to-[#0077B6] text-white font-semibold rounded-xl hover:brightness-110 transition-all shadow-md"
                  >
                    Kembali ke Login
                  </button>
                </div>
              ) : (
                <>
                  <div className="text-center mb-6 animate-slide-up">
                    <h2 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-[#03045E] via-[#0077B6] to-[#00B4D8] bg-clip-text text-transparent">
                      Atur Ulang Kata Sandi
                    </h2>
                    <p className="text-sm sm:text-base text-gray-500 mt-2">
                      Silakan masukkan kata sandi baru untuk akun Anda
                    </p>
                  </div>

                  <form onSubmit={handleSubmit} className="space-y-4 sm:space-y-5">
                    <div className="animate-slide-up" style={{ animationDelay: '0.1s' }}>
                      <label className="block text-sm font-medium text-gray-600 mb-1.5">
                        Kata Sandi Baru
                      </label>
                      <div className="relative">
                        <div className="absolute inset-0 bg-[#0077B6]/10 to-[#00B4D8]/10 rounded-xl blur opacity-20"></div>
                        <div className="relative flex items-center">
                          <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-300" />
                          <input
                            type={showPassword ? 'text' : 'password'}
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            minLength={8}
                            className="w-full pl-11 pr-12 py-3 border border-gray-600 rounded-xl focus:ring-2 focus:ring-[#00B4D8]/40 focus:border-[#00B4D8] outline-none transition-all bg-gray-700 text-white placeholder-gray-400 backdrop-blur"
                            placeholder="Minimal 8 karakter"
                          />
                          <button
                            type="button"
                            onClick={() => setShowPassword(!showPassword)}
                            className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-300 hover:text-gray-100 transition-colors"
                          >
                            {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                          </button>
                        </div>
                      </div>
                    </div>

                    <div className="animate-slide-up" style={{ animationDelay: '0.2s' }}>
                      <label className="block text-sm font-medium text-gray-600 mb-1.5">
                        Konfirmasi Kata Sandi Baru
                      </label>
                      <div className="relative">
                        <div className="absolute inset-0 bg-[#0077B6]/10 to-[#00B4D8]/10 rounded-xl blur opacity-20"></div>
                        <div className="relative flex items-center">
                          <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-300" />
                          <input
                            type={showPassword ? 'text' : 'password'}
                            value={confirmPassword}
                            onChange={(e) => setConfirmPassword(e.target.value)}
                            required
                            minLength={8}
                            className="w-full pl-11 pr-12 py-3 border border-gray-600 rounded-xl focus:ring-2 focus:ring-[#00B4D8]/40 focus:border-[#00B4D8] outline-none transition-all bg-gray-700 text-white placeholder-gray-400 backdrop-blur"
                            placeholder="Ulangi kata sandi baru"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Submit Button */}
                    <button
                      type="submit"
                      disabled={loading}
                      className="relative w-full py-3.5 overflow-hidden rounded-xl transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed group"
                    >
                      <div className="absolute inset-0 bg-gradient-to-r from-[#03045E] via-[#0077B6] to-[#00B4D8]"></div>
                      <div className="absolute inset-0 bg-gradient-to-r from-[#0077B6] via-[#00B4D8] to-[#03045E] opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                      <div className="relative flex items-center justify-center gap-2 text-white font-semibold">
                        {loading ? (
                          <Loader2 className="w-5 h-5 animate-spin" />
                        ) : (
                          <span>Simpan Kata Sandi</span>
                        )}
                      </div>
                    </button>
                  </form>
                </>
              )}
            </div>
          </div>

          <p className="text-center text-xs text-white/60 mt-6">
            &copy; {new Date().getFullYear()} Pertamina Trans Kontinental. Semua hak dilindungi undang-undang.
          </p>
        </div>
      </div>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
