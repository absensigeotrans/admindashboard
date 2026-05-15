class AttendanceModel {
  final String? id;
  final String userId;
  final String? shiftId;
  final String? officeId;
  final DateTime checkInTime;
  final double? checkInLat;
  final double? checkInLon;
  final DateTime? checkOutTime;
  final double? checkOutLat;
  final double? checkOutLon;
  final bool isValid;
  final bool isMocked;

  AttendanceModel({
    this.id,
    required this.userId,
    this.shiftId,
    this.officeId,
    required this.checkInTime,
    this.checkInLat,
    this.checkInLon,
    this.checkOutTime,
    this.checkOutLat,
    this.checkOutLon,
    this.isValid = true,
    this.isMocked = false,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      shiftId: json['shift_id'],
      officeId: json['office_id'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkInLat: json['check_in_latitude'],
      checkInLon: json['check_in_longitude'],
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      checkOutLat: json['check_out_latitude'],
      checkOutLon: json['check_out_longitude'],
      isValid: json['is_valid'] ?? true,
      isMocked: json['is_mocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'shift_id': shiftId,
      'office_id': officeId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_in_latitude': checkInLat,
      'check_in_longitude': checkInLon,
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_out_latitude': checkOutLat,
      'check_out_longitude': checkOutLon,
      'is_valid': isValid,
      'is_mocked': isMocked,
    };
  }
}
