class ReadCheck {
  final String id;
  final DateTime createdAt;
  final String authId;
  final String messageId;
  final String display_name; // additional field for convenience
  final String? profile_picture; // additional field for convenience

  ReadCheck({
    required this.id,
    required this.createdAt,
    required this.authId,
    required this.messageId,
    required this.display_name,
    this.profile_picture,
  });

  factory ReadCheck.fromMap(Map<String, dynamic> map) {
    return ReadCheck(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      authId: map['auth_id'],
      messageId: map['message_id'],
      display_name: map['display_name'],
      profile_picture: map['profile_picture'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'auth_id': authId,
      'message_id': messageId,
      'display_name': display_name,
      'profile_picture': profile_picture ?? '',
    };
  }
}