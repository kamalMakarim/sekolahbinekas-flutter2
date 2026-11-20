import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sekolahbinekas/models/tingkat_classes.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_logic.dart';

class AddFotoKegiatanScreen extends StatefulWidget {
  const AddFotoKegiatanScreen({super.key});

  @override
  State<AddFotoKegiatanScreen> createState() => _AddFotoKegiatanScreenState();
}

class _AddFotoKegiatanScreenState extends State<AddFotoKegiatanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _linkController = TextEditingController();
  final _fotoKegiatanLogic = FotoKegiatanLogic();

  List<TingkatClasses>? _tingkatClasses;
  final List<TingkatClasses> _selectedClasses = [];
  File? _selectedImage;
  bool _ppiOnly = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final classes = await _fotoKegiatanLogic.loadAllTingkatClasses();
      if (!mounted) return;
      setState(() {
        _tingkatClasses = classes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat daftar kelas: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFile(type: FileType.image);
      if (result?.path == null || !mounted) return;

      setState(() {
        _selectedImage = File(result!.path!);
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Gagal memilih gambar: $error');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClasses.isEmpty || _selectedImage == null) {
      _showMessage('Pilih kelas dan gambar terlebih dahulu.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _fotoKegiatanLogic.addFotoKegiatan(
        namaKegiatan: _namaController.text.trim(),
        tingkatClasses: _selectedClasses,
        image: _selectedImage!,
        linkFoto: _linkController.text.trim(),
        ppiOnly: _ppiOnly,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage('Gagal menyimpan foto kegiatan: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Tambah Foto Kegiatan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildLoadError()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionCard(
                        icon: Icons.event_outlined,
                        title: 'Informasi kegiatan',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _namaController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Nama kegiatan',
                                prefixIcon: Icon(Icons.title),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Masukkan nama kegiatan'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _linkController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Tautan foto atau album',
                                prefixIcon: Icon(Icons.link),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final uri = Uri.tryParse(value?.trim() ?? '');
                                if (uri == null ||
                                    !uri.hasScheme ||
                                    !{'http', 'https'}.contains(uri.scheme) ||
                                    uri.host.isEmpty) {
                                  return 'Masukkan tautan http atau https yang valid';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        icon: Icons.school_outlined,
                        title: 'Pilih kelas',
                        subtitle: _selectedClasses.isEmpty
                            ? 'Tentukan siswa yang dapat melihat foto ini'
                            : '${_selectedClasses.length} kelas dipilih',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sortedClasses.map((kelas) {
                            final selected = _selectedClasses.contains(kelas);
                            return FilterChip(
                              label: Text(
                                '${kelas.tahun} · ${kelas.class_name}',
                              ),
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _selectedClasses.add(kelas);
                                  } else {
                                    _selectedClasses.remove(kelas);
                                  }
                                });
                              },
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.primary,
                              side: BorderSide(
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: SwitchListTile.adaptive(
                          value: _ppiOnly,
                          onChanged: (value) =>
                              setState(() => _ppiOnly = value),
                          secondary: Icon(
                            Icons.verified_user_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text(
                            'Khusus siswa PPI',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Jika aktif, hanya siswa yang terdaftar dalam program PPI yang mendapat akses.',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        icon: Icons.image_outlined,
                        title: 'Gambar kegiatan',
                        subtitle: 'Pilih gambar pratinjau untuk kegiatan ini',
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: _selectedImage == null
                                    ? ColoredBox(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.photo_outlined,
                                          size: 48,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickImage,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                _selectedImage == null
                                    ? 'Pilih gambar'
                                    : 'Ganti gambar',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submitForm,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSubmitting ? 'Menyimpan...' : 'Simpan kegiatan',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<TingkatClasses> get _sortedClasses {
    final classes = List<TingkatClasses>.from(_tingkatClasses ?? []);
    classes.sort((a, b) {
      final level = a.tingkat.toString().compareTo(b.tingkat.toString());
      if (level != 0) return level;
      final year = a.tahun.toString().compareTo(b.tahun.toString());
      if (year != 0) return year;
      return a.class_name.compareTo(b.class_name);
    });
    return classes;
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(_loadError ?? 'Gagal memuat data'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
