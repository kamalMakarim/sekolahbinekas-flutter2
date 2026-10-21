class JobLevel {
  final String id;
  final String name;

  JobLevel({
    required this.id,
    required this.name,
  });

  //map -> JobLevel
  factory JobLevel.fromMap(Map<String, dynamic> map) {
    return JobLevel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  //JobLevel -> map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
} 