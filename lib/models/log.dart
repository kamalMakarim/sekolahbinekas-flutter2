class Log {
  String id;
  String message;
  String userId;
  List<String>? images;
  List<String>? files;
  String className;

  Log({
    required this.id,
    required this.message,
    required this.userId,
    this.images,
    this.files,
    required this.className,
  });

  // Map -> Message
  factory Log.fromMap(Map<String, dynamic> map) {
    return Log(
      id: map['id'] as String,
      message: map['message'] as String,
      userId: map['user_id'] as String,
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      files: map['files'] != null ? List<String>.from(map['files']) : null,
      className: map['class_name'] as String,
    );
  }

  // Message -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'user_id': userId,
      'images': images,
      'files': files,
      'class_name': className,
    };
  }
}
