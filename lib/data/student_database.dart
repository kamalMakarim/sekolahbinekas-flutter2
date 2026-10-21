import 'package:sekolahbinekas/data/user_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';

class StudentDatabase {
  final supabase = Supabase.instance.client;

  Future<List<Student>> getAllStudents() async {
    String currentUserId = await UserDatabase().getCurrentUserId();
    String? currentUserClass = await UserDatabase().getCurrentUserClassName();
    final response = await supabase
      .from('students')
      .select('id, parent_auth_id, name, batch, class_name')
      .or(
        currentUserClass != null && currentUserClass.isNotEmpty
        ? 'parent_auth_id.eq.$currentUserId,class_name.eq.$currentUserClass'
        : 'parent_auth_id.eq.$currentUserId'
      );

    // response is expected to be a List<dynamic>
    final students = (response as List)
        .map((data) => Student.fromMap(data))
        .toList();
    return students;
  }

  Future<List<Student>> getStudentsByClass(String className) async {
    final response = await supabase
        .from('students')
        .select('id, parent_auth_id, name, batch, class_name')
        .eq('class_name', className);

    // response is expected to be a List<dynamic>
    final students = (response as List)
        .map((data) => Student.fromMap(data))
        .toList();
    return students;
  }

  Future<List<Student>>getMyChildren() async {
    String currentUserId = await UserDatabase().getCurrentUserId();
    final response = await supabase
        .from('students')
        .select('id, parent_auth_id, name, batch, class_name')
        .eq('parent_auth_id', currentUserId);

    // response is expected to be a List<dynamic>
    final students = (response as List)
        .map((data) => Student.fromMap(data))
        .toList();
    return students;
  }
}
