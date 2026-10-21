class User{
  final String id;
  final String display_name;
  String? profile_picture;
  String? role;
  String? class_name;
  String? zipline_token;

  User({
    required this.id,
    required this.display_name,
    this.role,
    this.profile_picture,
    this.class_name,
    this.zipline_token,
  });

  //map -> User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      display_name: map['display_name'] as String,
      role: map['role'] as String?,
      profile_picture: map['profile_picture'] as String?,
      class_name: map['class_name'] as String? ?? '', 
      zipline_token: map['zipline_token'] as String?,
    );
  }

  //User -> map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': display_name,
      'role': role ?? 'parent',
      'profile_picture': profile_picture ?? '',
      'class_name': class_name ?? '',
      'zipline_token': zipline_token ?? '',
    };
  }
}