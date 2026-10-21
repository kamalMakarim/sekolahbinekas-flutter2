import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tingkat_classes.dart';

class TingkatClassesDatabase {
  final supabase = Supabase.instance.client;

  Future<List<TingkatClasses>> getAllTingkatClasses() async {
    final response = await supabase
        .from('tingkat_classes')
        .select('id, tingkat, class_name, tahun');

    // response is expected to be a List<dynamic>
    final tingkatClassesList = (response as List)
        .map((data) => TingkatClasses.fromMap(data))
        .toList();
    return tingkatClassesList;
  }

  Future<List<TingkatClasses>> getByTingkat(String tingkat) async {
    final response = await supabase
        .from('tingkat_classes')
        .select('id, tingkat, class_name, tahun')
        .eq('tingkat', tingkat);

    final tingkatClassesList = (response as List)
        .map((data) => TingkatClasses.fromMap(data))
        .toList();
    return tingkatClassesList;
  }
}