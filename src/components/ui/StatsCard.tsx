'use client';

interface StatsCardProps {
  icon: React.ReactNode;
  value: number | string;
  label: string;
  trend?: string;
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'purple';
}

const colorMap = {
  blue: { bg: 'bg-blue-100', text: 'text-blue-600' },
  green: { bg: 'bg-green-100', text: 'text-green-600' },
  yellow: { bg: 'bg-yellow-100', text: 'text-yellow-600' },
  red: { bg: 'bg-red-100', text: 'text-red-600' },
  purple: { bg: 'bg-purple-100', text: 'text-purple-600' },
};

export function StatsCard({ icon, value, label, trend, color = 'blue' }: StatsCardProps) {
  const { bg, text } = colorMap[color];

  return (
    <div className="bg-white rounded-xl shadow-sm border p-5 flex items-center gap-4">
      <div className={`p-3 rounded-xl ${bg}`}>
        <span className={`block ${text}`}>{icon}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-2xl font-bold text-gray-900 truncate">{value}</p>
        <p className="text-sm text-gray-500">{label}</p>
        {trend && (
          <p className="text-xs text-gray-400 mt-0.5">{trend}</p>
        )}
      </div>
    </div>
  );
}