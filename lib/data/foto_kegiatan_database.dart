import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/foto_kegiatan.dart';

class FotoKegiatanDatabase {
  final supabase = Supabase.instance.client;

  Future<List<FotoKegiatan>> getAllFotoKegiatan() async {
    final response = await supabase
        .from('foto_kegiatan')
        .select(
          'id, link_foto, nama_kegiatan, thumbnail_foto, classes_name, created_at',
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
    final response = await supabase
        .from('foto_kegiatan')
        .select(
          'id, link_foto, nama_kegiatan, thumbnail_foto, classes_name, created_at',
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
  ) async {
    await supabase
        .from('foto_kegiatan')
        .insert({
          'nama_kegiatan': namaKegiatan,
          'classes_name': classNames,
          'link_foto': linkFoto,
          'thumbnail_foto': thumbnailFoto,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
  }

  Future<void> deleteFotoKegiatan(String fotoKegiatanId) async {
    await supabase.from('foto_kegiatan').delete().eq('id', fotoKegiatanId);
  }
}
