class TingkatClasses {
  final String id;
  final String tingkat;
  final String class_name;
  final int tahun;

  TingkatClasses({
    required this.id,
    required this.tingkat,
    required this.class_name,
    required this.tahun,
  });

  factory TingkatClasses.fromMap(Map<String, dynamic> map) {
    return TingkatClasses(
      id: map['id'] as String,
      tingkat: map['tingkat'] as String,
      class_name: map['class_name'] as String,
      tahun: map['tahun'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tingkat': tingkat,
      'class_name': class_name,
      'tahun': tahun,
    };
  }
}