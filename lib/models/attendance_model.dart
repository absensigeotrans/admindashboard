class AttendanceModel {
  final String? id;
  final String userId;
  final String? shiftId;
  final String? officeId;
  final DateTime checkInTime;
  final double? checkInLat;
  final double? checkInLon;
  final double? checkInAccuracy;
  final Map<String, dynamic>? checkInLocationData;
  final DateTime? checkOutTime;
  final double? checkOutLat;
  final double? checkOutLon;
  final double? checkOutAccuracy;
  final Map<String, dynamic>? checkOutLocationData;
  final bool isValid;
  final double? distanceFromOffice;
  final bool isMocked;

  AttendanceModel({
    this.id,
    required this.userId,
    this.shiftId,
    this.officeId,
    required this.checkInTime,
    this.checkInLat,
    this.checkInLon,
    this.checkInAccuracy,
    this.checkInLocationData,
    this.checkOutTime,
    this.checkOutLat,
    this.checkOutLon,
    this.checkOutAccuracy,
    this.checkOutLocationData,
    this.isValid = true,
    this.distanceFromOffice,
    this.isMocked = false,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'] ?? '',
      shiftId: json['shift_id'],
      officeId: json['office_id'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkInLat: (json['check_in_latitude'] as num?)?.toDouble(),
      checkInLon: (json['check_in_longitude'] as num?)?.toDouble(),
      checkInAccuracy: (json['check_in_accuracy'] as num?)?.toDouble(),
      checkInLocationData: json['check_in_location_data'],
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      checkOutLat: (json['check_out_latitude'] as num?)?.toDouble(),
      checkOutLon: (json['check_out_longitude'] as num?)?.toDouble(),
      checkOutAccuracy: (json['check_out_accuracy'] as num?)?.toDouble(),
      checkOutLocationData: json['check_out_location_data'],
      isValid: json['is_valid'] ?? true,
      distanceFromOffice: (json['distance_from_office'] as num?)?.toDouble(),
      isMocked: json['is_mocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (shiftId != null) 'shift_id': shiftId,
      if (officeId != null) 'office_id': officeId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_in_latitude': checkInLat,
      'check_in_longitude': checkInLon,
      'check_in_accuracy': checkInAccuracy,
      'check_in_location_data': checkInLocationData,
      if (checkOutTime != null) 'check_out_time': checkOutTime!.toIso8601String(),
      'check_out_latitude': checkOutLat,
      'check_out_longitude': checkOutLon,
      'check_out_accuracy': checkOutAccuracy,
      'check_out_location_data': checkOutLocationData,
      'is_valid': isValid,
      'distance_from_office': distanceFromOffice,
      'is_mocked': isMocked,
    };
  }
}
