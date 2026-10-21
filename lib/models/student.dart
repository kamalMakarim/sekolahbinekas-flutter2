class Student {
  final String id;
  final String parent_auth_id;
  final String name;
  final int batch;
  final String class_name;

  Student({
    required this.id,
    required this.parent_auth_id,
    required this.name,
    required this.batch,
    required this.class_name,
  });

  //map -> Student
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      parent_auth_id: map['parent_auth_id'] as String,
      name: map['name'] as String,
      batch: map['batch'] as int,
      class_name: map['class_name'] as String,
    );
  }

  //Student -> map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_auth_id': parent_auth_id,
      'name': name,
      'batch': batch,
      'class_name': class_name,
    };
  }
}