'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useOffices } from '@/hooks/useOffices';
import { formatDistance } from '@/lib/utils';
import { ArrowLeft, Plus, MapPin, Save, Trash2 } from 'lucide-react';
import Link from 'next/link';
import { Toast } from '@/components/Toast';

interface OfficeForm {
  name: string;
  latitude: string;
  longitude: string;
  geofence_radius: string;
}

export default function OfficesPage() {
  const { user, profile, loading: authLoading } = useAuth();
  const { offices, loading, fetchOffices, createOffice, updateOffice, deleteOffice } = useOffices();
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<OfficeForm>({
    name: '',
    latitude: '',
    longitude: '',
    geofence_radius: '100',
  });
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  useEffect(() => {
    fetchOffices();
  }, [fetchOffices]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const officeData = {
      name: form.name,
      latitude: parseFloat(form.latitude),
      longitude: parseFloat(form.longitude),
      geofence_radius: parseInt(form.geofence_radius),
    };

    let result;
    if (editingId) {
      result = await updateOffice(editingId, officeData);
    } else {
      result = await createOffice(officeData);
    }

    if (result.success) {
      setToast({
        message: editingId ? 'Office updated successfully!' : 'Office created successfully!',
        type: 'success',
      });
      setIsEditing(false);
      setEditingId(null);
      setForm({ name: '', latitude: '', longitude: '', geofence_radius: '100' });
    } else {
      setToast({ message: result.error || 'Failed to save office', type: 'error' });
    }
  };

  const handleEdit = (office: typeof offices[0]) => {
    setEditingId(office.id);
    setForm({
      name: office.name,
      latitude: office.latitude.toString(),
      longitude: office.longitude.toString(),
      geofence_radius: office.geofence_radius.toString(),
    });
    setIsEditing(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this office?')) return;

    const result = await deleteOffice(id);
    if (result.success) {
      setToast({ message: 'Office deleted successfully!', type: 'success' });
    } else {
      setToast({ message: result.error || 'Failed to delete office', type: 'error' });
    }
  };

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!user || profile?.role !== 'admin') {
    if (typeof window !== 'undefined') {
      window.location.href = '/';
    }
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center gap-4">
          <Link
            href="/admin"
            className="p-2 text-gray-600 hover:text-blue-600 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <h1 className="text-xl font-bold text-gray-900">Office Locations</h1>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 py-6">
        {/* Add New Button */}
        {!isEditing && (
          <button
            onClick={() => setIsEditing(true)}
            className="mb-6 flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
          >
            <Plus className="w-5 h-5" />
            Add Office Location
          </button>
        )}

        {/* Form */}
        {isEditing && (
          <div className="bg-white rounded-xl shadow-sm border p-6 mb-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              {editingId ? 'Edit Office' : 'New Office'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Office Name
                </label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                  className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                  placeholder="e.g., Jakarta Office"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Latitude
                  </label>
                  <input
                    type="number"
                    step="any"
                    value={form.latitude}
                    onChange={(e) => setForm({ ...form, latitude: e.target.value })}
                    required
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                    placeholder="-6.2088"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Longitude
                  </label>
                  <input
                    type="number"
                    step="any"
                    value={form.longitude}
                    onChange={(e) => setForm({ ...form, longitude: e.target.value })}
                    required
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                    placeholder="106.8456"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Geofence Radius (meters)
                </label>
                <input
                  type="number"
                  value={form.geofence_radius}
                  onChange={(e) => setForm({ ...form, geofence_radius: e.target.value })}
                  required
                  min="10"
                  max="10000"
                  className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                  placeholder="100"
                />
                <p className="text-sm text-gray-500 mt-1">
                  Recommended: 100 meters
                </p>
              </div>

              <div className="flex gap-3">
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <Save className="w-5 h-5" />
                  {editingId ? 'Update' : 'Save'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setIsEditing(false);
                    setEditingId(null);
                    setForm({ name: '', latitude: '', longitude: '', geofence_radius: '100' });
                  }}
                  className="px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Offices List */}
        <div className="space-y-4">
          {offices.length === 0 ? (
            <div className="text-center py-12 bg-white rounded-xl shadow-sm border">
              <MapPin className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-600">No office locations configured</p>
              <p className="text-sm text-gray-500 mt-1">
                Add an office to enable geofencing
              </p>
            </div>
          ) : (
            offices.map((office) => (
              <div
                key={office.id}
                className="bg-white rounded-xl shadow-sm border p-4"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="font-semibold text-gray-900">{office.name}</h3>
                    <p className="text-sm text-gray-600 mt-1">
                      {office.latitude.toFixed(6)}, {office.longitude.toFixed(6)}
                    </p>
                    <p className="text-sm text-gray-500 mt-1">
                      Radius: {formatDistance(office.geofence_radius)}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleEdit(office)}
                      className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    >
                      <Save className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(office.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </main>

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
