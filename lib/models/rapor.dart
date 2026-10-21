class Rapor {
  final String id;
  DateTime? createdAt;
  final String studentId;
  final int semester;
  final String tahunAjaran;
  final String status;
  final String pdf;

  Rapor({
    required this.id,
    this.createdAt,
    required this.studentId,
    required this.semester,
    required this.tahunAjaran,
    required this.status,
    required this.pdf,
  });

  factory Rapor.fromMap(Map<String, dynamic> map) {
    return Rapor(
      id: map['id'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      studentId: map['student_id'] as String,
      semester: map['semester'] as int,
      tahunAjaran: map['tahun_ajaran'] as String,
      status: map['status'] as String,
      pdf: map['pdf'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'student_id': studentId,
      'semester': semester,
      'tahun_ajaran': tahunAjaran,
      'status': status,
      'pdf': pdf,
    };
  }
}
