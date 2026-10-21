class UnreadCount {
  final String id;
  final String authId;
  final int count;
  final String studentId;


  UnreadCount({
    required this.id,
    required this.authId,
    required this.count,
    required this.studentId,
  });

  // Map -> UnreadCount
  factory UnreadCount.fromMap(Map<String, dynamic> map) {
    return UnreadCount(
      id: map['id'] as String,
      authId: map['auth_id'] as String,
      count: map['count'] as int,
      studentId: map['student_id'] as String,
    );
  }

  // UnreadCount -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_id': authId,
      'count': count,
      'student_id': studentId,
    };
  }
}