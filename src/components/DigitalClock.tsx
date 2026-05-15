'use client';

import { useState, useEffect } from 'react';
import { format } from 'date-fns';

export function DigitalClock() {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => {
      setTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  return (
    <div className="text-center">
      <div className="text-5xl font-bold text-gray-900 tracking-wider">
        {format(time, 'HH:mm:ss')}
      </div>
      <div className="text-lg text-gray-600 mt-2">
        {format(time, 'EEEE, MMMM d, yyyy')}
      </div>
    </div>
  );
}
