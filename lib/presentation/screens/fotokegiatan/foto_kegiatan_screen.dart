import 'package:flutter/material.dart';
import 'package:sekolahbinekas/models/foto_kegiatan.dart';
import 'package:sekolahbinekas/models/student.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_logic.dart';
import 'package:url_launcher/url_launcher.dart';

class FotoKegiatanScreen extends StatefulWidget {
  const FotoKegiatanScreen({super.key});

  @override
  State<FotoKegiatanScreen> createState() => _FotoKegiatanScreenState();
}

class _FotoKegiatanScreenState extends State<FotoKegiatanScreen> {
  List<Student>? students;
  Student? currentStudent;
  List<FotoKegiatan>? fotoKegiatanList;

  @override
  void initState() {
    super.initState();
    _initPage().then((_) => _loadFotoKegiatan());
  }

  Future<void> _initPage() async {
    final data = await FotoKegiatanLogic().loadData();
    setState(() {
      students = data.students;
      currentStudent = data.currentStudent;
    });
  }

  Future<void> _loadFotoKegiatan() async {
    if (currentStudent != null) {
      final fotos = await FotoKegiatanLogic().loadFotoKegiatanForStudent(
        currentStudent!,
      );
      setState(() {
        fotoKegiatanList = fotos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: DropdownButton<Student>(
          isExpanded: true,
          value: currentStudent,
          underline: SizedBox(),
          dropdownColor: Colors.blue,
          borderRadius: BorderRadius.circular(10),
          items: (students ?? []).map((student) {
            return DropdownMenuItem(
              value: student,
              child: Text(student.name, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              // Load messages for the selected student
              List<FotoKegiatan> newFotoKegiatan = await FotoKegiatanLogic()
                  .loadFotoKegiatanForStudent(value);
              setState(() {
                currentStudent = value;
                fotoKegiatanList = newFotoKegiatan;
              });
            }
          },
        ),
      ),
      body: fotoKegiatanList == null
            ? Center(child: Text('No photos available'))
            : fotoKegiatanList!.isEmpty
            ? Center(child: Text('No photos available'))
            : ListView.builder(
              itemCount: fotoKegiatanList!.length,
              itemBuilder: (context, index) {
                final foto = fotoKegiatanList![index];
                return GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(foto.link_foto), mode: LaunchMode.externalApplication);
                  },
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.all(10),
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          foto.thumbnail_foto,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              foto.nama_kegiatan,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              '${foto.createdAt?.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  ),
                );
              },
            ),
    
    );
  }
}
