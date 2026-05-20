'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Toast } from '@/components/Toast';
import { Mail, Lock, Eye, EyeOff, Loader2, Ship, Anchor, Waves } from 'lucide-react';
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

  useEffect(() => {
    if (authLoading) return;
    if (user && profile && typeof window !== 'undefined') {
      if (profile.role === 'admin') {
        window.location.href = '/admin';
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
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-ptk-navy"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex bg-gray-50">
      {/* Left Panel - Branding */}
      <div className="hidden lg:flex lg:w-[55%] relative overflow-hidden">
        {/* Background Image */}
        <div className="absolute inset-0">
          <Image
            src="/images/bg-login.png"
            alt="Pertamina Trans Kontinental - Maritime Operations"
            fill
            className="object-cover"
            priority
          />
          {/* Navy Overlay */}
          <div className="absolute inset-0 bg-overlay-navy"></div>
        </div>

        {/* Content */}
        <div className="relative z-10 flex flex-col items-center justify-center w-full px-12 text-white">
          {/* Logo */}
          <div className="mb-8 animate-fade-in">
            <Image
              src="/logo-ptk.svg"
              alt="Pertamina Trans Kontinental"
              width={420}
              height={100}
              className="drop-shadow-2xl"
            />
          </div>

          {/* Tagline */}
          <p className="text-xl font-light tracking-widest uppercase mb-4 opacity-90">
            Integrated Maritime Logistics
          </p>

          {/* Decorative Divider */}
          <div className="w-24 h-0.5 bg-white/30 mb-8"></div>

          {/* Stats / Features */}
          <div className="grid grid-cols-3 gap-8 text-center mb-12">
            <div className="animate-fade-in" style={{ animationDelay: '0.2s' }}>
              <Ship className="w-8 h-8 mx-auto mb-2 opacity-80" />
              <p className="text-2xl font-bold">379+</p>
              <p className="text-sm opacity-70">Vessels</p>
            </div>
            <div className="animate-fade-in" style={{ animationDelay: '0.4s' }}>
              <Anchor className="w-8 h-8 mx-auto mb-2 opacity-80" />
              <p className="text-2xl font-bold">55+</p>
              <p className="text-sm opacity-70">Years</p>
            </div>
            <div className="animate-fade-in" style={{ animationDelay: '0.6s' }}>
              <Waves className="w-8 h-8 mx-auto mb-2 opacity-80" />
              <p className="text-2xl font-bold">Nationwide</p>
              <p className="text-sm opacity-70">Coverage</p>
            </div>
          </div>

          {/* Quote */}
          <blockquote className="text-center max-w-md italic opacity-80 text-sm leading-relaxed">
            &ldquo;Delivers high-standard energy and logistics shipping services since 1969, supported by an extensive nationwide network.&rdquo;
          </blockquote>
        </div>

        {/* Decorative Wave Pattern */}
        <div className="absolute bottom-0 left-0 right-0 h-32 opacity-10">
          <svg viewBox="0 0 1440 120" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
            <path d="M0 60L48 55C96 50 192 40 288 45C384 50 480 70 576 75C672 80 768 70 864 60C960 50 1056 40 1152 45C1248 50 1344 70 1392 80L1440 90V120H1392C1344 120 1248 120 1152 120C1056 120 960 120 864 120C768 120 672 120 576 120C480 120 384 120 288 120C192 120 96 120 48 120H0V60Z" fill="white"/>
          </svg>
        </div>
      </div>

      {/* Right Panel - Login Form */}
      <div className="w-full lg:w-[45%] flex items-center justify-center px-6 py-12 lg:px-12">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden text-center mb-8">
            <Image
              src="/logo-ptk.svg"
              alt="Pertamina Trans Kontinental"
              width={280}
              height={70}
              className="mx-auto"
            />
          </div>

          {/* Form Card */}
          <div className="bg-white rounded-2xl shadow-xl border border-gray-100 p-8 lg:p-10">
            {/* Header */}
            <div className="text-center mb-8">
              <h2 className="text-2xl font-bold text-gray-900">
                {isSignUp ? 'Create Account' : 'Welcome Back'}
              </h2>
              <p className="text-sm text-gray-500 mt-2">
                {isSignUp
                  ? 'Sign up to access GeoAttend Pro'
                  : 'Sign in to your GeoAttend Pro account'}
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5">
              {isSignUp && (
                <div className="animate-fade-in">
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    Full Name
                  </label>
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    required
                    className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-ptk-navy/20 focus:border-ptk-navy outline-none transition-all bg-gray-50/50"
                    placeholder="Enter your full name"
                  />
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Email Address
                </label>
                <div className="relative">
                  <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="w-full pl-11 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-ptk-navy/20 focus:border-ptk-navy outline-none transition-all bg-gray-50/50"
                    placeholder="name@pertamina.com"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={6}
                    className="w-full pl-11 pr-12 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-ptk-navy/20 focus:border-ptk-navy outline-none transition-all bg-gray-50/50"
                    placeholder="Enter your password"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 bg-ptk-navy hover:bg-[#084A8A] text-white font-semibold rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-lg shadow-ptk-navy/25 hover:shadow-ptk-navy/40"
              >
                {loading && <Loader2 className="w-5 h-5 animate-spin" />}
                {isSignUp ? 'Create Account' : 'Sign In'}
              </button>
            </form>

            {/* Toggle Sign In / Sign Up */}
            <div className="mt-8 text-center">
              <p className="text-sm text-gray-600">
                {isSignUp ? 'Already have an account?' : "Don't have an account?"}
                <button
                  onClick={() => setIsSignUp(!isSignUp)}
                  className="ml-1.5 text-ptk-navy hover:text-[#084A8A] font-semibold transition-colors"
                >
                  {isSignUp ? 'Sign In' : 'Create Account'}
                </button>
              </p>
            </div>
          </div>

          {/* Footer */}
          <p className="text-center text-xs text-gray-400 mt-8">
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
