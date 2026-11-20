import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/foto_kegiatan.dart';

class FotoKegiatanDatabase {
  final supabase = Supabase.instance.client;

  Future<List<String>> getAccessibleFotoKegiatanIds() async {
    const studentPageSize = 500;
    final studentIds = <String>[];
    var offset = 0;

    while (true) {
      final response = await supabase
          .from('students')
          .select('id')
          .order('id')
          .range(offset, offset + studentPageSize - 1);
      final page = (response as List)
          .map((data) => data['id'] as String)
          .toList();
      studentIds.addAll(page);

      if (page.length < studentPageSize) break;
      offset += studentPageSize;
    }

    return getFotoKegiatanIdsForStudents(studentIds);
  }

  Future<List<String>> getFotoKegiatanIdsForStudents(
    List<String> studentIds,
  ) async {
    const studentBatchSize = 100;
    const pageSize = 500;
    final fotoKegiatanIds = <String>{};

    for (var start = 0; start < studentIds.length; start += studentBatchSize) {
      final studentBatch = studentIds
          .skip(start)
          .take(studentBatchSize)
          .toList();
      var offset = 0;

      while (true) {
        final response = await supabase
            .from('foto_student_access')
            .select('foto_kegiatan_id')
            .inFilter('student_id', studentBatch)
            .order('id')
            .range(offset, offset + pageSize - 1);
        final page = (response as List)
            .map((data) => data['foto_kegiatan_id'] as String)
            .toList();
        fotoKegiatanIds.addAll(page);

        if (page.length < pageSize) break;
        offset += pageSize;
      }
    }

    return fotoKegiatanIds.toList();
  }

  Future<List<FotoKegiatan>> getFotoKegiatanPage({
    required int offset,
    required int limit,
    List<String>? accessibleFotoKegiatanIds,
  }) async {
    if (accessibleFotoKegiatanIds != null &&
        accessibleFotoKegiatanIds.isEmpty) {
      return [];
    }

    var query = supabase
        .from('foto_kegiatan')
        .select(
          'id, link_foto, nama_kegiatan, thumbnail_foto, classes_name, '
          'only_ppi, created_at',
        );
    if (accessibleFotoKegiatanIds != null) {
      query = query.inFilter('id', accessibleFotoKegiatanIds);
    }

    final response = await query
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((data) => FotoKegiatan.fromMap(data))
        .toList();
  }

  Future<List<FotoKegiatan>> getAllFotoKegiatan() async {
    final response = await supabase
        .from('foto_kegiatan')
        .select(
          'id, link_foto, nama_kegiatan, thumbnail_foto, classes_name, '
          'only_ppi, created_at',
        );

    // response is expected to be a List<dynamic>
    final fotoKegiatanList = (response as List)
        .map((data) => FotoKegiatan.fromMap(data))
        .toList();
    return fotoKegiatanList;
  }

  Future<List<FotoKegiatan>> getFotoKegiatanByStudentId(
    String studentId,
  ) async {
    final fotoStudentAccess = await supabase
        .from('foto_student_access')
        .select('foto_kegiatan_id')
        .eq('student_id', studentId)
        .then(
          (data) => (data as List)
              .map((e) => e['foto_kegiatan_id'] as String)
              .toList(),
        );
    if (fotoStudentAccess.isEmpty) return [];

    final response = await supabase
        .from('foto_kegiatan')
        .select(
          'id, link_foto, nama_kegiatan, thumbnail_foto, classes_name, '
          'only_ppi, created_at',
        )
        .inFilter('id', fotoStudentAccess)
        .order('created_at', ascending: false);
    // response is expected to be a List<dynamic>
    final fotoKegiatanList = (response as List)
        .map((data) => FotoKegiatan.fromMap(data))
        .toList();
    return fotoKegiatanList;
  }

  Future<void> addFotoKegiatan(
    String namaKegiatan,
    List<String> classNames,
    String thumbnailFoto,
    String linkFoto,
    bool ppiOnly,
  ) async {
    await supabase
        .from('foto_kegiatan')
        .insert({
          'nama_kegiatan': namaKegiatan,
          'classes_name': classNames,
          'link_foto': linkFoto,
          'thumbnail_foto': thumbnailFoto,
          'only_ppi': ppiOnly,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
  }

  Future<void> deleteFotoKegiatan(String fotoKegiatanId) async {
    await supabase.from('foto_kegiatan').delete().eq('id', fotoKegiatanId);
  }
}
