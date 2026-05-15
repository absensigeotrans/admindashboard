'use client';

import { MapPin, CheckCircle, XCircle } from 'lucide-react';
import { formatDistance } from '@/lib/utils';

interface DistanceIndicatorProps {
  distance: number | null;
  radius: number;
}

export function DistanceIndicator({ distance, radius }: DistanceIndicatorProps) {
  if (distance === null) {
    return (
      <div className="flex items-center gap-2 text-gray-500">
        <MapPin className="w-5 h-5" />
        <span>Waiting for location...</span>
      </div>
    );
  }

  const isWithinRange = distance <= radius;
  const remaining = Math.max(0, radius - distance);

  return (
    <div className={`p-4 rounded-lg ${isWithinRange ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
      <div className="flex items-center gap-3">
        {isWithinRange ? (
          <CheckCircle className="w-6 h-6 text-green-600" />
        ) : (
          <XCircle className="w-6 h-6 text-red-600" />
        )}
        <div>
          <p className={`font-semibold ${isWithinRange ? 'text-green-700' : 'text-red-700'}`}>
            {isWithinRange ? 'Within Range' : 'Outside Range'}
          </p>
          <p className="text-sm text-gray-600">
            Distance: {formatDistance(distance)}
            {!isWithinRange && (
              <span className="text-red-500 ml-2">
                ({formatDistance(remaining)} outside radius)
              </span>
            )}
          </p>
        </div>
      </div>
      {isWithinRange && (
        <p className="text-sm text-green-600 mt-2">
          You can now clock in!
        </p>
      )}
    </div>
  );
}
