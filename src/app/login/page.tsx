'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Toast } from '@/components/Toast';
import { Mail, Lock, Eye, EyeOff, Loader2, Ship, Anchor, Waves, Sparkles } from 'lucide-react';
import Image from 'next/image';

export default function LoginPage() {
  const { user, profile, signIn, signUp, loading: authLoading } = useAuth();
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [formVisible, setFormVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setFormVisible(true), 300);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (authLoading) return;
    if (user && profile && typeof window !== 'undefined') {
      if (profile.role === 'admin') {
        window.location.href = '/admin';
      } else {
        window.location.href = '/dashboard';
      }
    }
  }, [user, profile, authLoading]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    let result;
    if (isSignUp) {
      result = await signUp(email, password, fullName);
    } else {
      result = await signIn(email, password);
    }

    setLoading(false);

    if (result.error) {
      setToast({ message: result.error.message, type: 'error' });
    } else {
      if (isSignUp) {
        setToast({ message: 'Account created! Please check your email to verify.', type: 'success' });
        setIsSignUp(false);
      } else {
        setToast({ message: 'Signed in successfully!', type: 'success' });
      }
    }
  };

  if (authLoading) {
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
      {/* Full-page Background Image - visible on both mobile and desktop */}
      <div className="fixed inset-0 z-0">
        <Image
          src="/images/bg-login.png"
          alt="Pertamina Trans Kontinental - Maritime Operations"
          fill
          className="object-cover"
          priority
        />
        {/* Blue Ocean Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-[#03045E]/70 via-[#0077B6]/60 to-[#00B4D8]/50 backdrop-blur-sm"></div>
      </div>

      {/* Animated Background Elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none z-[1]">
        <div className="absolute top-1/4 -left-20 w-72 h-72 bg-[#90E0EF]/10 rounded-full blur-3xl animate-float-slow"></div>
        <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-[#00B4D8]/10 rounded-full blur-3xl animate-float-medium"></div>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-[#03045E]/20 rounded-full blur-3xl"></div>
      </div>

      {/* Left Panel - Branding (Desktop only) */}
      <div className="hidden lg:flex lg:w-[55%] relative z-10">
        <div className="relative z-10 flex flex-col items-center justify-center w-full px-12 text-white">
          {/* Logo with Glow */}
          <div className="mb-8 animate-fade-in relative">
            <div className="absolute -inset-8 bg-[#90E0EF]/20 rounded-full blur-2xl"></div>
            <Image
              src="/logo-ptk.png"
              alt="Pertamina Trans Kontinental"
              width={420}
              height={100}
              className="drop-shadow-2xl relative z-10"
            />
            <Sparkles className="absolute -top-4 -right-4 w-6 h-6 text-[#90E0EF] animate-sparkle" />
            <Sparkles className="absolute -bottom-2 -left-6 w-4 h-4 text-[#90E0EF] animate-sparkle-delay" />
          </div>

          {/* Tagline */}
          <p className="text-xl font-light tracking-widest uppercase mb-4 opacity-90 animate-slide-up">
            Integrated Maritime Logistics
          </p>

          {/* Decorative Divider */}
          <div className="w-24 h-0.5 bg-gradient-to-r from-transparent via-[#90E0EF] to-transparent mb-8"></div>

          {/* Stats / Features */}
          <div className="grid grid-cols-3 gap-8 text-center mb-12">
            <div className="animate-slide-up" style={{ animationDelay: '0.2s' }}>
              <div className="relative inline-block">
                <Ship className="w-8 h-8 mx-auto mb-2 opacity-80" />
                <div className="absolute inset-0 bg-white/20 rounded-full blur-sm animate-pulse"></div>
              </div>
              <p className="text-2xl font-bold">379+</p>
              <p className="text-sm opacity-70">Vessels</p>
            </div>
            <div className="animate-slide-up" style={{ animationDelay: '0.4s' }}>
              <Anchor className="w-8 h-8 mx-auto mb-2 opacity-80" />
              <p className="text-2xl font-bold">55+</p>
              <p className="text-sm opacity-70">Years</p>
            </div>
            <div className="animate-slide-up" style={{ animationDelay: '0.6s' }}>
              <Waves className="w-8 h-8 mx-auto mb-2 opacity-80" />
              <p className="text-2xl font-bold">Nationwide</p>
              <p className="text-sm opacity-70">Coverage</p>
            </div>
          </div>

          {/* Quote */}
          <blockquote className="text-center max-w-md italic opacity-80 text-sm leading-relaxed animate-slide-up" style={{ animationDelay: '0.8s' }}>
            &ldquo;Delivers high-standard energy and logistics shipping services since 1969, supported by an extensive nationwide network.&rdquo;
          </blockquote>
        </div>

        {/* Decorative Wave Pattern */}
        <div className="absolute bottom-0 left-0 right-0 h-32 opacity-20">
          <svg viewBox="0 0 1440 120" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
            <path d="M0 60L48 55C96 50 192 40 288 45C384 50 480 70 576 75C672 80 768 70 864 60C960 50 1056 40 1152 45C1248 50 1344 70 1392 80L1440 90V120H1392C1344 120 1248 120 1152 120C1056 120 960 120 864 120C768 120 672 120 576 120C480 120 384 120 288 120C192 120 96 120 48 120H0V60Z" fill="#90E0EF"/>
          </svg>
        </div>
      </div>

      {/* Right Panel - Login Form */}
      <div className="w-full lg:w-[45%] flex items-center justify-center px-4 sm:px-6 py-8 lg:px-12 relative z-10">
        <div className="w-full max-w-md transform transition-all duration-700 ease-out" style={{ opacity: formVisible ? 1 : 0, transform: formVisible ? 'translateY(0)' : 'translateY(20px)' }}>
          {/* Mobile Logo with Glow */}
          <div className="lg:hidden text-center mb-6 animate-fade-in">
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

          {/* Glassmorphism Form Card */}
          <div className="relative group">
            {/* Glassmorphism Border Glow */}
            <div className="absolute -inset-0.5 bg-gradient-to-r from-[#90E0EF]/50 via-[#0077B6]/50 to-[#90E0EF]/50 rounded-3xl blur opacity-30 group-hover:opacity-50 transition-opacity duration-500"></div>

            {/* Card */}
            <div className="relative backdrop-blur-xl bg-white/80 rounded-3xl shadow-2xl border border-white/20 p-6 sm:p-8 lg:p-10">
              {/* Header */}
              <div className="text-center mb-6 animate-slide-up">
                <h2 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-[#03045E] via-[#0077B6] to-[#00B4D8] bg-clip-text text-transparent">
                  {isSignUp ? 'Create Account' : 'Welcome Back'}
                </h2>
                <p className="text-sm sm:text-base text-gray-500 mt-2">
                  {isSignUp
                    ? 'Sign up to access GeoAttend Pro'
                    : 'Sign in to your account'}
                </p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4 sm:space-y-5">
                {isSignUp && (
                  <div className="animate-slide-up">
                    <label className="block text-sm font-medium text-gray-600 mb-1.5">
                      Full Name
                    </label>
                    <div className="relative">
                      <div className="absolute inset-0 bg-gradient-to-r from-[#90E0EF]/20 to-[#0077B6]/20 rounded-xl blur opacity-30"></div>
                      <input
                        type="text"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        required
                        className="relative w-full px-4 py-3 border border-gray-600 rounded-xl focus:ring-2 focus:ring-[#00B4D8]/40 focus:border-[#00B4D8] outline-none transition-all bg-gray-700 text-white placeholder-gray-400 backdrop-blur"
                        placeholder="Enter your full name"
                      />
                    </div>
                  </div>
                )}

                <div className="animate-slide-up" style={{ animationDelay: '0.1s' }}>
                  <label className="block text-sm font-medium text-gray-600 mb-1.5">
                    Email Address
                  </label>
                  <div className="relative">
                    <div className="absolute inset-0 bg-gradient-to-r from-[#0077B6]/10 to-[#00B4D8]/10 rounded-xl blur opacity-20"></div>
                    <div className="relative flex items-center">
                      <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-300" />
                      <input
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        required
                        className="w-full pl-11 pr-4 py-3 border border-gray-600 rounded-xl focus:ring-2 focus:ring-[#00B4D8]/40 focus:border-[#00B4D8] outline-none transition-all bg-gray-700 text-white placeholder-gray-400 backdrop-blur"
                        placeholder="name@pertamina.com"
                      />
                    </div>
                  </div>
                </div>

                <div className="animate-slide-up" style={{ animationDelay: '0.2s' }}>
                  <label className="block text-sm font-medium text-gray-600 mb-1.5">
                    Password
                  </label>
                  <div className="relative">
                    <div className="absolute inset-0 bg-gradient-to-r from-[#0077B6]/10 to-[#00B4D8]/10 rounded-xl blur opacity-20"></div>
                    <div className="relative flex items-center">
                      <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-300" />
                      <input
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                        minLength={6}
                        className="w-full pl-11 pr-12 py-3 border border-gray-600 rounded-xl focus:ring-2 focus:ring-[#00B4D8]/40 focus:border-[#00B4D8] outline-none transition-all bg-gray-700 text-white placeholder-gray-400 backdrop-blur"
                        placeholder="Enter your password"
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

                {/* Submit Button with Gradient */}
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
                      <>
                        <span>{isSignUp ? 'Create Account' : 'Sign In'}</span>
                        <svg className="w-5 h-5 transform group-hover:translate-x-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                        </svg>
                      </>
                    )}
                  </div>
                  {/* Shimmer Effect */}
                  <div className="absolute top-0 -left-100 w-48 h-full bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer"></div>
                </button>
              </form>
              {/* Toggle Sign In / Sign Up */}

              <div className="mt-6 text-center animate-slide-up" style={{ animationDelay: '0.5s' }}>
                <p className="text-sm text-gray-600">
                  {isSignUp ? 'Already have an account?' : "Don't have an account?"}
                  <button
                    onClick={() => {
                      setIsSignUp(!isSignUp);
                      setFormVisible(false);
                      setTimeout(() => setFormVisible(true), 100);
                    }}
                    className="ml-1.5 text-[#0077B6] hover:text-[#00B4D8] font-semibold transition-colors"
                  >
                    {isSignUp ? 'Sign In' : 'Create Account'}
                  </button>
                </p>
              </div>
            </div>
          </div>

          {/* Footer */}
          <p className="text-center text-xs text-white/60 mt-6">
            &copy; {new Date().getFullYear()} Pertamina Trans Kontinental. All rights reserved.
          </p>
        </div>
      </div>

      {/* Toast */}
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
