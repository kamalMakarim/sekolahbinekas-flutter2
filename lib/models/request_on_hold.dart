class RequestOnHold {
  final String id;
  final String reason;
  final String studentId;
  final String requestStatus;

  RequestOnHold({
    required this.id,
    required this.reason,
    required this.studentId,
    required this.requestStatus,
  });

  //map -> RequestOnHold
  factory RequestOnHold.fromMap(Map<String, dynamic> map) {
    return RequestOnHold(
      id: map['id'] as String,
      reason: map['reason'] as String,
      studentId: map['student_id'] as String,
      requestStatus: map['request_status'] as String,
    );
  }

  //Serialize RequestOnHold to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'student_id': studentId,
      'request_status': requestStatus,
    };
  }
}