class FotoKegiatan{
  final String id;
  final String link_foto;
  final String nama_kegiatan;
  final String thumbnail_foto;
  final List<String> classes_name;
  DateTime? createdAt;

  FotoKegiatan({
    required this.id,
    required this.link_foto,
    required this.nama_kegiatan,
    required this.thumbnail_foto,
    required this.classes_name,
    this.createdAt,
  });

  factory FotoKegiatan.fromMap(Map<String, dynamic> map) {
    return FotoKegiatan(
      id: map['id'] as String,
      link_foto: map['link_foto'] as String,
      nama_kegiatan: map['nama_kegiatan'] as String,
      thumbnail_foto: map['thumbnail_foto'] as String,
      classes_name: List<String>.from(map['classes_name'] as List<dynamic>),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'link_foto': link_foto,
      'nama_kegiatan': nama_kegiatan,
      'thumbnail_foto': thumbnail_foto,
      'classes_name': classes_name,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}