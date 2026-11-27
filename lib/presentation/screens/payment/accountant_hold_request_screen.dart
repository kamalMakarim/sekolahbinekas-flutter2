import 'package:flutter/material.dart';
import 'package:sekolahbinekas/data/request_on_hold_database.dart';
import 'package:sekolahbinekas/models/request_on_hold.dart';

import 'hold_request_widgets.dart';

class AccountantHoldRequestScreen extends StatefulWidget {
  const AccountantHoldRequestScreen({super.key});

  @override
  State<AccountantHoldRequestScreen> createState() => _AccountantHoldRequestScreenState();
}

class _AccountantHoldRequestScreenState extends State<AccountantHoldRequestScreen> {
  final _database = RequestOnHoldDatabase();
  List<RequestOnHold> _requests = [];
  bool _loading = true;
  String? _error;
  String? _processing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final requests = await _database.getRequestOnHolds();
      if (!mounted) return;
      setState(() { _requests = requests; _loading = false; });
    } catch (error) {
      debugPrint('Failed to load hold requests: $error');
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Pengajuan tidak dapat dimuat. Silakan coba lagi.'; });
    }
  }

  Future<void> _decide(RequestOnHold request, bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Setujui pengajuan?' : 'Tolak pengajuan?'),
        content: Text(approve
            ? 'Seluruh invoice terpilih untuk ${request.studentName} akan ditahan.'
            : 'Pengajuan untuk ${request.studentName} akan ditolak. Status invoice tidak berubah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(approve ? 'Setujui' : 'Tolak')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _processing = request.id);
    try {
      await _database.decide(request.id, approve: approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Pengajuan disetujui.' : 'Pengajuan ditolak.')));
      await _load();
    } catch (error) {
      debugPrint('Failed to decide hold request: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan tidak dapat diproses. Status invoice atau pengajuan mungkin sudah berubah; muat ulang dan coba lagi.')));
    } finally {
      if (mounted) setState(() => _processing = null);
    }
  }

  Widget _list(List<RequestOnHold> requests, {required bool pending}) {
    if (requests.isEmpty) {
      return ListView(children: [
        HoldEmptyState(message: pending ? 'Tidak ada pengajuan yang menunggu.' : 'Belum ada riwayat pengajuan.'),
      ]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(pending ? 'Perlu ditinjau' : 'Pengajuan yang sudah diproses', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${requests.length} pengajuan'),
          const SizedBox(height: 14),
          ...requests.map((request) => HoldRequestCard(
            request: request,
            actions: pending ? Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _processing != null ? null : () => _decide(request, false), child: const Text('Tolak'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: _processing != null ? null : () => _decide(request, true), child: Text(_processing == request.id ? 'Memproses...' : 'Setujui'))),
              ],
            ) : null,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      appBar: AppBar(
        title: const Text('Pengajuan penahanan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loading || _processing != null ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: const TabBar(labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorColor: Colors.white, tabs: [Tab(text: 'Menunggu'), Tab(text: 'Riwayat')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Coba lagi'))]))
          : TabBarView(children: [
              _list(_requests.where((request) => request.requestStatus == 'pending').toList(), pending: true),
              _list(_requests.where((request) => request.requestStatus != 'pending').toList(), pending: false),
            ]),
    ),
  );
}
