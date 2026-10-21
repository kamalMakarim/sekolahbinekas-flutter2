class Organization {
  final String id;
  final String name;

  Organization({
    required this.id,
    required this.name,
  });

  //map -> Organization
  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  //Organization -> map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
} 