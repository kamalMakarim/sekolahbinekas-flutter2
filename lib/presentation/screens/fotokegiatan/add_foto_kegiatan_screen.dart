import 'package:flutter/material.dart';
import 'package:sekolahbinekas/models/foto_kegiatan.dart';
import 'package:sekolahbinekas/models/tingkat_classes.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_logic.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddFotoKegiatanScreen extends StatefulWidget {
  const AddFotoKegiatanScreen({super.key});

  @override
  State<AddFotoKegiatanScreen> createState() => _AddFotoKegiatanScreenState();
}

class _AddFotoKegiatanScreenState extends State<AddFotoKegiatanScreen> {
  List<TingkatClasses>? tingkatClasses;
  List<TingkatClasses> selectedClasses = [];
  List<FotoKegiatan>? fotoKegiatanList;
  File? _selectedImage;
  ImageProvider? thumbnailImage;
  String namaKegiatan = '';
  String linkFoto = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final classes = await FotoKegiatanLogic().loadAllTingkatClasses();
    final fotoKegiatanList = await FotoKegiatanLogic().loadAllFotoKegiatan();
    setState(() {
      tingkatClasses = classes;
      this.fotoKegiatanList = fotoKegiatanList;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFile(
      type: FileType.image, // restrict to images
    );

    if (result != null && result.path != null) {
      setState(() {
        _selectedImage = File(result.path!);
        thumbnailImage = FileImage(_selectedImage!);
      });
    }
  }

  Future<void> _submitForm() async {
    if (namaKegiatan.isEmpty ||
        linkFoto.isEmpty ||
        selectedClasses.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select an image')),
      );
      return;
    }
    await FotoKegiatanLogic().addFotoKegiatan(
      namaKegiatan: namaKegiatan,
      tingkatClasses: selectedClasses,
      image: _selectedImage!,
      linkFoto: linkFoto,
    );
    Navigator.of(context).pop(); // Go back after adding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Foto Kegiatan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: tingkatClasses == null
          ? Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nama Kegiatan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title, color: Colors.blue),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    onChanged: (v) => setState(() => namaKegiatan = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Link Foto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link, color: Colors.blue),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    onChanged: (v) => setState(() => linkFoto = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Kelas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (List<TingkatClasses>.from(tingkatClasses!)
                              ..sort((a, b) {
                                final cmp = a.tingkat.toString().compareTo(
                                  b.tingkat.toString(),
                                );
                                if (cmp != 0) return cmp;
                                return a.tahun.toString().compareTo(
                                  b.tahun.toString(),
                                );
                              }))
                            .map(
                              (t) => FilterChip(
                                label: Text('(${t.tahun})${t.class_name}'),
                                selected: selectedClasses.contains(t),
                                checkmarkColor: Colors.white,
                                selectedColor: Colors.blue,
                                onSelected: (sel) {
                                  setState(() {
                                    if (sel) {
                                      selectedClasses.add(t);
                                    } else {
                                      selectedClasses.remove(t);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preview Foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.shade50,
                    ),
                    child: Center(
                      child: thumbnailImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image(
                                image: thumbnailImage!,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 56,
                                  color: Colors.blue.shade300,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No image selected',
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Gambar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
