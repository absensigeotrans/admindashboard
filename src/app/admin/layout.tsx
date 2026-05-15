'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Sidebar, MobileMenuButton } from '@/components/admin/Sidebar';
import { ToastContainer } from '@/components/ui/Toast';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, profile, loading: authLoading } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (authLoading) return;
    if (!user || profile?.role !== 'admin') {
      window.location.href = '/login';
    }
  }, [user, profile, authLoading]);

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (!user || profile?.role !== 'admin') return null;

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0">
        {/* Mobile top bar */}
        <header className="bg-white shadow-sm border-b sticky top-0 z-30 lg:hidden">
          <div className="px-4 py-3 flex items-center gap-3">
            <MobileMenuButton onClick={() => setSidebarOpen(true)} />
            <span className="font-bold text-gray-900">GeoAttend Admin</span>
          </div>
        </header>

        <main className="flex-1 p-4 sm:p-6">
          {children}
        </main>
      </div>

      <ToastContainer />
    </div>
  );
}
