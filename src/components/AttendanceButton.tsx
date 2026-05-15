'use client';

import { LogIn, LogOut, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AttendanceButtonProps {
  type: 'in' | 'out';
  disabled?: boolean;
  loading?: boolean;
  onClick: () => void;
}

export function AttendanceButton({ type, disabled, loading, onClick }: AttendanceButtonProps) {
  const isCheckIn = type === 'in';
  
  return (
    <button
      onClick={onClick}
      disabled={disabled || loading}
      className={cn(
        'w-full py-4 px-6 rounded-xl font-semibold text-lg transition-all duration-200 flex items-center justify-center gap-3',
        isCheckIn
          ? 'bg-blue-600 hover:bg-blue-700 text-white disabled:bg-gray-300 disabled:text-gray-500'
          : 'bg-orange-600 hover:bg-orange-700 text-white disabled:bg-gray-300 disabled:text-gray-500',
        'shadow-lg hover:shadow-xl active:scale-95 disabled:scale-100'
      )}
    >
      {loading ? (
        <Loader2 className="w-6 h-6 animate-spin" />
      ) : isCheckIn ? (
        <>
          <LogIn className="w-6 h-6" />
          Clock In
        </>
      ) : (
        <>
          <LogOut className="w-6 h-6" />
          Clock Out
        </>
      )}
    </button>
  );
}
