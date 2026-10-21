import 'package:flutter/material.dart';
import 'package:sekolahbinekas/models/foto_kegiatan.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_logic.dart';
import 'package:url_launcher/url_launcher.dart';

class EditFotoKegiatanScreen extends StatefulWidget {
  const EditFotoKegiatanScreen({super.key});

  @override
  State<EditFotoKegiatanScreen> createState() => _EditFotoKegiatanScreenState();
}

class _EditFotoKegiatanScreenState extends State<EditFotoKegiatanScreen> {
  List<FotoKegiatan>? fotoKegiatanList;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final fotos = await FotoKegiatanLogic().loadAllFotoKegiatan();
    setState(() {
      fotoKegiatanList = fotos;
    });
  }

  Future<void> _deleteFotoKegiatan(FotoKegiatan fotoKegiatan) async {
    await FotoKegiatanLogic().deleteFotoKegiatan(fotoKegiatan);
    _initPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delete Foto Kegiatan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: fotoKegiatanList == null
          ? Center(child: CircularProgressIndicator())
          : fotoKegiatanList!.isEmpty
          ? Center(child: Text('No photos available'))
          : ListView.builder(
              itemCount: fotoKegiatanList!.length,
              itemBuilder: (context, index) {
                final foto = fotoKegiatanList![index];
                return GestureDetector(
                  onTap: () {
                    launchUrl(
                      Uri.parse(foto.link_foto),
                      mode: LaunchMode.externalApplication,
                    );
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
                        Expanded(
                          child: Column(
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
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFotoKegiatan(foto),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
