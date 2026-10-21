class ChangeShiftRequest {
  final String id;
  final String authId;
  final DateTime attendanceDate;
  final String shiftId;
  final String reason;
  final String fileUrl;
  final bool? isApprovedByApprovalLine;
  final bool? isApprovedByHr;
  final String? checkIn;
  final String? checkOut;

  ChangeShiftRequest({
    required this.id,
    required this.authId,
    required this.attendanceDate,
    required this.shiftId,
    required this.reason,
    required this.fileUrl,
    required this.isApprovedByApprovalLine,
    required this.isApprovedByHr,
    this.checkIn,
    this.checkOut,
  });

  factory ChangeShiftRequest.fromMap(Map<String, dynamic> json) {
    return ChangeShiftRequest(
      id: json['id'],
      authId: json['auth_id'],
      attendanceDate: DateTime.parse(json['attendance_date']),
      shiftId: json['shift_id'],
      reason: json['reason'],
      fileUrl: json['file_url'],
      isApprovedByApprovalLine: json['is_approved_by_approval_line'],
      isApprovedByHr: json['is_approved_by_hr'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authId': authId,
      'attendanceDate': attendanceDate.toIso8601String(),
      'shiftId': shiftId,
      'reason': reason,
      'fileUrl': fileUrl,
      'isApprovedByApprovalLine': isApprovedByApprovalLine,
      'isApprovedByHr': isApprovedByHr,
      'checkIn': checkIn,
      'checkOut': checkOut,
    };
  }
}