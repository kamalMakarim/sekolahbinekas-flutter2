import 'package:sekolahbinekas/data/student_database.dart';
import 'package:sekolahbinekas/models/student.dart';
import 'package:sekolahbinekas/data/rapor_database.dart';
import 'package:sekolahbinekas/models/rapor.dart';

class RaporLogic {
  Future<({List<Student>? students, Student? currentStudent})> loadData() async {
    final students = await StudentDatabase().getMyChildren();
    if (students.isEmpty) {
      return (students: null, currentStudent: null);
    }

    final currentStudent = students.first;

    return (students: students, currentStudent: currentStudent);
  }

  Future<List<Rapor>> loadRaporForStudent(Student student) async {
    final raporList = await RaporDatabase().getRaporByStudentId(student.id);
    return raporList;
  }
}
