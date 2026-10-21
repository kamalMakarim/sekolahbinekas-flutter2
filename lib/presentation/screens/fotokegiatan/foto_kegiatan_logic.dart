import 'package:sekolahbinekas/data/student_database.dart';
import 'package:sekolahbinekas/data/tingkat_classes_database.dart';
import 'package:sekolahbinekas/models/student.dart';
import 'package:sekolahbinekas/data/foto_kegiatan_database.dart';
import 'package:sekolahbinekas/models/foto_kegiatan.dart';
import 'package:sekolahbinekas/models/tingkat_classes.dart';
import 'dart:io';
import 'package:sekolahbinekas/data/image_database.dart';

class FotoKegiatanLogic {
  Future<({List<Student>? students, Student? currentStudent})> loadData() async {
    final students = await StudentDatabase().getAllStudents();
    if (students.isEmpty) {
      return (students: null, currentStudent: null);
    }

    final currentStudent = students.first;

    return (students: students, currentStudent: currentStudent);
  }

  Future<List<FotoKegiatan>> loadFotoKegiatanForStudent(Student student) async {
    final fotoKegiatanList = await FotoKegiatanDatabase()
        .getFotoKegiatanByStudentId(student.id);
    return fotoKegiatanList;
  }

  Future<List<FotoKegiatan>> loadAllFotoKegiatan() async {
    final fotoKegiatanList = await FotoKegiatanDatabase().getAllFotoKegiatan();
    return fotoKegiatanList;
  }

  Future<bool> addFotoKegiatan({
    required String namaKegiatan,
    required List<TingkatClasses> tingkatClasses,
    required File image,
    required String linkFoto,
  }) async {
    // Upload images to Zipline first
    List<File> images = [image];
    List<String> imageUrls = await ImageDatabase().uploadImages(images);

    List<String> classNames = tingkatClasses
        .map((tc) => tc.class_name)
        .toList();
    // Save foto kegiatan with image URLs
    await FotoKegiatanDatabase().addFotoKegiatan(
      namaKegiatan,
      classNames,
      imageUrls[0],
      linkFoto,
    );

    return true;
  }

  Future<List<TingkatClasses>> loadAllTingkatClasses() async {
    final tingkatClassesList = await TingkatClassesDatabase()
        .getAllTingkatClasses();
    return tingkatClassesList;
  }

  Future<bool> deleteFotoKegiatan(FotoKegiatan fotoKegiatan) async {
    await FotoKegiatanDatabase().deleteFotoKegiatan(fotoKegiatan.id);
    await ImageDatabase().deleteImage([fotoKegiatan.thumbnail_foto]);
    return true;
  }
}
