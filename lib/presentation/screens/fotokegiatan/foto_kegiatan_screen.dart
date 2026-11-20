import 'package:flutter/material.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'package:sekolahbinekas/models/foto_kegiatan.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_logic.dart';
import 'package:url_launcher/url_launcher.dart';

class FotoKegiatanScreen extends StatefulWidget {
  const FotoKegiatanScreen({super.key});

  @override
  State<FotoKegiatanScreen> createState() => _FotoKegiatanScreenState();
}

class _FotoKegiatanScreenState extends State<FotoKegiatanScreen> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final _fotoKegiatanLogic = FotoKegiatanLogic();
  List<String> _accessibleFotoKegiatanIds = [];
  List<FotoKegiatan> _fotoKegiatanList = [];
  bool _isMultimedia = false;
  bool _showAllFotoKegiatan = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearEnd);
    _initPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final role = await UserDatabase().getUserRole();
      final accessibleIds = await _fotoKegiatanLogic
          .loadAccessibleFotoKegiatanIds();
      if (!mounted) return;

      setState(() {
        _isMultimedia = role == 'multimedia';
        _accessibleFotoKegiatanIds = accessibleIds;
        _isInitialized = true;
        _isLoading = false;
      });
      await _loadPage(reset: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load photos: $error';
        _isLoading = false;
      });
    }
  }

  void _loadMoreWhenNearEnd() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMore)) return;
    final offset = reset ? 0 : _fotoKegiatanList.length;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (reset) {
        _fotoKegiatanList = [];
        _hasMore = true;
      }
    });

    try {
      final photos = await _fotoKegiatanLogic.loadFotoKegiatanPage(
        offset: offset,
        limit: _pageSize,
        accessibleFotoKegiatanIds: _showAllFotoKegiatan
            ? null
            : _accessibleFotoKegiatanIds,
      );
      if (!mounted) return;
      setState(() {
        _fotoKegiatanList.addAll(photos);
        _hasMore = photos.length == _pageSize;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load photos: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPhoto(FotoKegiatan foto) async {
    try {
      final opened = await launchUrl(
        Uri.parse(foto.link_foto),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan foto.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka tautan foto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Foto Kegiatan'),
        actions: [
          if (_isMultimedia)
            IconButton(
              tooltip: _showAllFotoKegiatan
                  ? 'Tampilkan foto siswa'
                  : 'Tampilkan semua foto',
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _showAllFotoKegiatan = !_showAllFotoKegiatan;
                      });
                      _loadPage(reset: true);
                    },
              icon: Icon(
                _showAllFotoKegiatan
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
            ),
        ],
      ),
      body: _fotoKegiatanList.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fotoKegiatanList.isEmpty && _errorMessage != null
          ? _buildError(
              onRetry: _isInitialized
                  ? () => _loadPage(reset: true)
                  : _initPage,
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _itemCount,
              itemBuilder: (context, index) {
                if (index == 0) return _buildIntroCard(context);
                if (_fotoKegiatanList.isEmpty) {
                  return _buildEmptyState(context);
                }

                final photoIndex = index - 1;
                if (photoIndex < _fotoKegiatanList.length) {
                  return _buildPhotoCard(_fotoKegiatanList[photoIndex]);
                }

                if (_errorMessage != null) {
                  return _buildError(onRetry: _loadPage);
                }
                return _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox(height: 12);
              },
            ),
    );
  }

  int get _itemCount {
    final hasFooter = _isLoading || _hasMore || _errorMessage != null;
    return 1 +
        (_fotoKegiatanList.isEmpty ? 1 : _fotoKegiatanList.length) +
        (hasFooter && _fotoKegiatanList.isNotEmpty ? 1 : 0);
  }

  Widget _buildIntroCard(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onPrimary;

    return Card(
      color: Colors.blue,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kenangan kegiatan siswa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showAllFotoKegiatan
                        ? 'Menampilkan semua foto kegiatan.'
                        : 'Foto kegiatan yang dapat Anda akses.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: textColor.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(FotoKegiatan foto) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPhoto(foto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    foto.thumbnail_foto,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                if (foto.only_ppi)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Khusus PPI',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foto.nama_kegiatan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        foto.createdAt?.toLocal().toString().split(' ')[0] ??
                            'Tanggal tidak tersedia',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  if (foto.classes_name.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: foto.classes_name
                          .take(3)
                          .map(
                            (className) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(className),
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall,
                              backgroundColor: colorScheme.surfaceContainerLow,
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 52,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada foto kegiatan',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Foto kegiatan yang tersedia akan muncul di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          if (_isMultimedia && !_showAllFotoKegiatan) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() => _showAllFotoKegiatan = true);
                      _loadPage(reset: true);
                    },
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Tampilkan semua foto'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError({required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage ?? 'Unable to load photos'),
          TextButton(
            onPressed: _isLoading ? null : onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
