import 'package:flutter/material.dart';
import 'package:sekolahbinekas/presentation/screens/bukom/bukom_bs_screen.dart';
import 'package:sekolahbinekas/models/tingkat_classes.dart';
import 'package:sekolahbinekas/data/tingkat_classes_database.dart';
import 'package:sekolahbinekas/data/user_database.dart';

class ClassSelectionScreen extends StatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  TingkatClasses? selectedClass;
  late List<TingkatClasses> classOptions = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final userRole = await UserDatabase().getUserRole();
    final tingkat = userRole == 'bidang_study_tk' ? 'TK' : 'SD';
    print("Loading classes for tingkat: $tingkat");
    final classes = await TingkatClassesDatabase().getByTingkat(tingkat);
    setState(() {
      classOptions = classes..sort((a, b) => a.tahun.compareTo(b.tahun));
      selectedClass = classes.isNotEmpty ? classes[0] : null;
    });
  }

  void _proceedToNextScreen(TingkatClasses kelas) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BukomBsScreen(kelas: kelas)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kelas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: classOptions.length,
                itemBuilder: (context, index) {
                  final classOption = classOptions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        '(${classOption.tahun}) ${classOption.class_name}',
                      ),
                      onTap: () => _proceedToNextScreen(classOption),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
