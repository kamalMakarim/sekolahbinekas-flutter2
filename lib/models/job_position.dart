class JobPosition {
  final String id;
  final String name;

  JobPosition({
    required this.id,
    required this.name,
  });

  //map -> JobPosition
  factory JobPosition.fromMap(Map<String, dynamic> map) {
    return JobPosition(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  //JobPosition -> map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
} 