'use client';

import { useEffect } from 'react';
import { useLeaveRequests, leaveTypeLabels, LeaveRequest } from '@/hooks/useLeaveRequests';
import { Tabs } from '@/components/ui/Tabs';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { FormInput, FormSelect } from '@/components/ui/FormInput';
import { toast } from '@/components/ui/Toast';
import { Calendar, CheckCircle, XCircle, Plus } from 'lucide-react';
import { useState } from 'react';

export default function LeaveRequestsPage() {
  const { requests, loading, fetchRequests, approveLeave, rejectLeave, createLeave } = useLeaveRequests();
  const [activeTab, setActiveTab] = useState('pending');
  const [showCreate, setShowCreate] = useState(false);

  // Form state for create
  const [formData, setFormData] = useState({
    type: 'annual' as LeaveRequest['type'],
    start_date: '',
    end_date: '',
    reason: '',
  });

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  const pending = requests.filter((r) => r.status === 'pending');
  const approved = requests.filter((r) => r.status === 'approved');
  const rejected = requests.filter((r) => r.status === 'rejected' || r.status === 'cancelled');
  const all = requests;

  const tabs = [
    { id: 'pending', label: 'Pending', count: pending.length },
    { id: 'approved', label: 'Approved', count: approved.length },
    { id: 'rejected', label: 'Rejected', count: rejected.length },
    { id: 'all', label: 'All', count: all.length },
  ];

  const getFiltered = () => {
    switch (activeTab) {
      case 'pending': return pending;
      case 'approved': return approved;
      case 'rejected': return rejected;
      default: return all;
    }
  };

  const handleApprove = async (id: string) => {
    const result = await approveLeave(id);
    if (result.success) {
      toast.success('Leave request approved');
    } else {
      toast.error(result.error || 'Failed to approve');
    }
  };

  const handleReject = async (id: string) => {
    const result = await rejectLeave(id);
    if (result.success) {
      toast.success('Leave request rejected');
    } else {
      toast.error(result.error || 'Failed to reject');
    }
  };

  const handleCreate = async () => {
    if (!formData.start_date || !formData.end_date) {
      toast.error('Please fill start and end date');
      return;
    }
    const result = await createLeave({
      type: formData.type,
      start_date: formData.start_date,
      end_date: formData.end_date,
      reason: formData.reason,
    });
    if (result.success) {
      toast.success('Leave request submitted');
      setShowCreate(false);
      setFormData({ type: 'annual', start_date: '', end_date: '', reason: '' });
    } else {
      toast.error(result.error || 'Failed to submit');
    }
  };

  const getStatusBadge = (status: LeaveRequest['status']) => (
    <Badge variant={status === 'approved' ? 'success' : status === 'rejected' ? 'danger' : status === 'cancelled' ? 'default' : 'warning'}>
      {status === 'cancelled' ? 'Cancelled' : status.charAt(0).toUpperCase() + status.slice(1)}
    </Badge>
  );

  return (
    <div className="space-y-5">
      {/* Create button + tabs */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <Tabs tabs={tabs} activeTab={activeTab} onTabChange={setActiveTab} />
        <Button onClick={() => setShowCreate(true)}>
          <Plus className="w-4 h-4" /> New Request
        </Button>
      </div>

      {/* Request Cards */}
      {getFiltered().length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border">
          <Calendar className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-600 font-medium">No leave requests</p>
          <p className="text-sm text-gray-500 mt-1">
            {activeTab === 'pending' ? 'No pending requests to review' : `No ${activeTab} requests`}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {getFiltered().map((req) => (
            <div key={req.id} className="bg-white rounded-xl shadow-sm border p-5">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  {/* Header */}
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-sm font-semibold text-blue-600">
                      {req.user_name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900">{req.user_name}</p>
                      <p className="text-sm text-gray-500">{req.user_email}</p>
                    </div>
                    <div className="ml-auto flex items-center gap-2">
                      {getStatusBadge(req.status)}
                    </div>
                  </div>

                  {/* Details */}
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                    <div>
                      <p className="text-gray-500 text-xs">Type</p>
                      <p className="font-medium">{leaveTypeLabels[req.type]}</p>
                    </div>
                    <div>
                      <p className="text-gray-500 text-xs">From</p>
                      <p className="font-medium">{new Date(req.start_date).toLocaleDateString('id-ID')}</p>
                    </div>
                    <div>
                      <p className="text-gray-500 text-xs">To</p>
                      <p className="font-medium">{new Date(req.end_date).toLocaleDateString('id-ID')}</p>
                    </div>
                    <div>
                      <p className="text-gray-500 text-xs">Days</p>
                      <p className="font-medium">
                        {Math.ceil((new Date(req.end_date).getTime() - new Date(req.start_date).getTime()) / 86400000) + 1}
                      </p>
                    </div>
                  </div>

                  {req.reason && (
                    <p className="mt-3 text-sm text-gray-600 bg-gray-50 p-3 rounded-lg">
                      <span className="font-medium text-gray-700">Reason:</span> {req.reason}
                    </p>
                  )}
                </div>

                {/* Actions */}
                {req.status === 'pending' && (
                  <div className="flex flex-col gap-2 shrink-0">
                    <Button size="sm" onClick={() => handleApprove(req.id)}>
                      <CheckCircle className="w-4 h-4" /> Approve
                    </Button>
                    <Button size="sm" variant="danger" onClick={() => handleReject(req.id)}>
                      <XCircle className="w-4 h-4" /> Reject
                    </Button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Modal */}
      <Modal isOpen={showCreate} onClose={() => setShowCreate(false)} title="Submit Leave Request" size="md">
        <div className="space-y-4">
          <FormSelect
            label="Leave Type"
            value={formData.type}
            onChange={(e) => setFormData({ ...formData, type: e.target.value as LeaveRequest['type'] })}
            options={Object.entries(leaveTypeLabels).map(([value, label]) => ({ value, label }))}
          />
          <div className="grid grid-cols-2 gap-4">
            <FormInput
              label="Start Date"
              type="date"
              value={formData.start_date}
              onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
              required
            />
            <FormInput
              label="End Date"
              type="date"
              value={formData.end_date}
              onChange={(e) => setFormData({ ...formData, end_date: e.target.value })}
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Reason</label>
            <textarea
              value={formData.reason}
              onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
              placeholder="Reason for leave..."
              className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              rows={3}
            />
          </div>
          <div className="flex gap-2 pt-2">
            <Button onClick={handleCreate} className="flex-1">Submit Request</Button>
            <Button variant="secondary" onClick={() => setShowCreate(false)}>Cancel</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}