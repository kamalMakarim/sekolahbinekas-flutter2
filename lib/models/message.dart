class Message {
  String id;
  String message;
  String studentId;
  List<String>? images;
  List<String>? files;
  String senderId;
  String displayName;
  String? profilePicture;
  String? logId;
  String messageType;
  DateTime? createdAt;

  Message({
    required this.id,
    required this.message,
    required this.studentId,
    this.images,
    this.files,
    required this.senderId,
    required this.displayName,
    required this.messageType,
    this.profilePicture,
    this.logId,
    this.createdAt,
  });

  // Map -> Message
  factory Message.fromMap(Map<String, dynamic> map) {
    // Joined data from users_public will be inside this object if you do the join in Supabase query
    final userData = map['users_public'] ?? {};

    return Message(
      id: map['id'] as String,
      message: map['message'] as String,
      studentId: map['student_id'] as String,
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      files: map['files'] != null ? List<String>.from(map['files']) : null,
      senderId: map['sender_id'] as String,
      displayName: userData['display_name'] ?? 'Unknown',
      messageType: map['message_type'] as String,
      profilePicture: userData['profile_picture'] ?? 'https://zipline.bukom.sekolahbinekas.com/u/5ldroU.jpg',
      logId: map['log_id'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  // Message -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'student_id': studentId,
      'images': images,
      'files': files,
      'sender_id': senderId,
      'display_name': displayName,
      'message_type': messageType,
      'profile_picture': profilePicture ?? '',
      'log_id': logId ?? '',
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
