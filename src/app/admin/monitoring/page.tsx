'use client';

import { useEffect, useState, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { formatDistance } from '@/lib/utils';
import { Badge } from '@/components/ui/Badge';
import { StatsCard } from '@/components/ui/StatsCard';
import { format } from 'date-fns';
import { Radio, Clock, MapPin, Users, Activity } from 'lucide-react';

interface LiveAttendance {
  id: string;
  user_id: string;
  check_in_time: string;
  status: string;
  distance_from_office: number;
  latitude: number;
  longitude: number;
  user_name?: string;
}

export default function MonitoringPage() {
  const [liveRecords, setLiveRecords] = useState<LiveAttendance[]>([]);
  const [totalToday, setTotalToday] = useState(0);
  const [totalPresent, setTotalPresent] = useState(0);
  const [recentCount, setRecentCount] = useState(0);

  // Fetch initial today's data
  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];

    const fetchToday = async () => {
      const { data } = await supabase
        .from('attendance')
        .select('*, profiles:user_id(full_name)')
        .gte('check_in_time', today)
        .order('check_in_time', { ascending: false })
        .limit(100);

      if (data) {
        const mapped = data.map((r: any) => ({
          id: r.id,
          user_id: r.user_id,
          check_in_time: r.check_in_time,
          status: r.status,
          distance_from_office: r.distance_from_office,
          latitude: r.latitude,
          longitude: r.longitude,
          user_name: r.profiles?.full_name || 'Unknown',
        }));
        setLiveRecords(mapped);
        setTotalToday(mapped.length);
        setTotalPresent(mapped.filter((r) => r.status === 'present').length);
      }
    };

    fetchToday();
  }, []);

  // Subscribe to real-time attendance inserts
  useEffect(() => {
    const channel = supabase
      .channel('attendance_realtime')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'attendance' },
        async (payload) => {
          const newRecord = payload.new as any;

          // Fetch user name
          const { data: profile } = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', newRecord.user_id)
            .single();

          const live: LiveAttendance = {
            id: newRecord.id,
            user_id: newRecord.user_id,
            check_in_time: newRecord.check_in_time,
            status: newRecord.status,
            distance_from_office: newRecord.distance_from_office,
            latitude: newRecord.latitude,
            longitude: newRecord.longitude,
            user_name: profile?.full_name || 'Unknown',
          };

          setLiveRecords((prev) => [live, ...prev]);
          setTotalToday((prev) => prev + 1);
          if (live.status === 'present') {
            setTotalPresent((prev) => prev + 1);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // Update recent count every 10 seconds
  useEffect(() => {
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    const count = liveRecords.filter((r) => r.check_in_time >= fiveMinAgo).length;
    setRecentCount(count);

    const interval = setInterval(() => {
      const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
      setRecentCount(liveRecords.filter((r) => r.check_in_time >= fiveMinAgo).length);
    }, 10000);

    return () => clearInterval(interval);
  }, [liveRecords]);

  return (
    <div className="space-y-5">
      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard icon={<Activity className="w-5 h-5" />} value={totalToday} label="Clock-ins Today" color="blue" />
        <StatsCard icon={<Clock className="w-5 h-5" />} value={recentCount} label="Last 5 Minutes" color="purple" />
        <StatsCard icon={<Users className="w-5 h-5" />} value={totalPresent} label="Present" color="green" />
        <StatsCard icon={<Radio className="w-5 h-5" />} value="LIVE" label="Real-time Status" color="red" />
      </div>

      {/* Live Feed */}
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <div className="px-5 py-4 border-b flex items-center justify-between">
          <h3 className="font-semibold text-gray-900 flex items-center gap-2">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500" />
            </span>
            Live Clock-in Feed
          </h3>
          <span className="text-sm text-gray-500">{liveRecords.length} records</span>
        </div>

        {liveRecords.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <Radio className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p className="font-medium">Waiting for clock-ins...</p>
            <p className="text-sm mt-1">Real-time feed will appear here when employees clock in</p>
          </div>
        ) : (
          <div className="divide-y max-h-[600px] overflow-y-auto">
            {liveRecords.map((record, idx) => (
              <div
                key={record.id}
                className={`px-5 py-3 flex items-center justify-between hover:bg-gray-50 transition-colors ${
                  idx === 0 ? 'bg-blue-50/50' : ''
                }`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-semibold shrink-0 ${
                    record.status === 'present' ? 'bg-green-100 text-green-700' :
                      record.status === 'late' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-red-100 text-red-700'
                  }`}>
                    {record.user_name?.charAt(0).toUpperCase() || '?'}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-gray-900 truncate">{record.user_name}</p>
                      <Badge variant={
                        record.status === 'present' ? 'success' :
                        record.status === 'late' ? 'warning' : 'danger'
                      }>
                        {record.status.replace('_', ' ')}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-3 text-xs text-gray-500 mt-0.5">
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {format(new Date(record.check_in_time), 'HH:mm:ss')}
                      </span>
                      <span className="flex items-center gap-1">
                        <MapPin className="w-3 h-3" />
                        {formatDistance(record.distance_from_office)}
                      </span>
                    </div>
                  </div>
                </div>
                {idx === 0 && (
                  <span className="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-1 rounded-full shrink-0">
                    Just now
                  </span>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
