import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sekolahbinekas/data/invoice_database.dart';
import 'package:sekolahbinekas/data/request_on_hold_database.dart';
import 'package:sekolahbinekas/data/student_database.dart';
import 'package:sekolahbinekas/models/invoice.dart';
import 'package:sekolahbinekas/models/request_on_hold.dart';
import 'package:sekolahbinekas/models/student.dart';

import 'hold_request_widgets.dart';

class ParentHoldRequestScreen extends StatefulWidget {
  const ParentHoldRequestScreen({super.key});

  @override
  State<ParentHoldRequestScreen> createState() => _ParentHoldRequestScreenState();
}

class _ParentHoldRequestScreenState extends State<ParentHoldRequestScreen> {
  final _studentsDb = StudentDatabase();
  final _invoicesDb = InvoiceDatabase();
  final _requestsDb = RequestOnHoldDatabase();
  final _reason = TextEditingController();
  final _selected = <String>{};
  List<Student> _students = [];
  Student? _student;
  List<Invoice> _invoices = [];
  List<RequestOnHold> _requests = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final students = await _studentsDb.getMyChildren();
      if (!mounted) return;
      setState(() {
        _students = students;
        _student = students.isEmpty ? null : students.first;
        _loading = false;
      });
      if (_student != null) await _loadStudent();
    } catch (error) {
      debugPrint('Failed to load students for hold request: $error');
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Data anak tidak dapat dimuat. Silakan coba lagi.'; });
    }
  }

  Future<void> _loadStudent() async {
    final student = _student;
    if (student == null) return;
    final version = ++_loadVersion;
    setState(() { _loading = true; _error = null; _selected.clear(); });
    try {
      final invoices = await _invoicesDb.getInvoicesByStudentId(student.id, null, ['issued']);
      final requests = await _requestsDb.getRequestOnHolds(studentId: student.id);
      if (!mounted || version != _loadVersion) return;
      setState(() { _invoices = invoices; _requests = requests; _loading = false; });
    } catch (error) {
      debugPrint('Failed to load hold requests: $error');
      if (!mounted || version != _loadVersion) return;
      setState(() { _loading = false; _error = 'Data pengajuan tidak dapat dimuat. Silakan coba lagi.'; });
    }
  }

  Future<void> _submit() async {
    final student = _student;
    final reason = _reason.text.trim();
    if (student == null || _selected.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih invoice dan isi alasan pengajuan.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _requestsDb.submit(studentId: student.id, reason: reason, invoiceIds: _selected.toList());
      if (!mounted) return;
      _reason.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan berhasil dikirim.')));
      await _loadStudent();
    } catch (error) {
      debugPrint('Failed to submit hold request: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan gagal. Invoice mungkin sudah berubah atau sedang diajukan; muat ulang dan coba lagi.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingInvoiceIds = _requests
        .where((request) => request.requestStatus == 'pending')
        .expand((request) => request.invoices.map((invoice) => invoice.id))
        .toSet();
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      appBar: AppBar(
        title: const Text('Pengajuan penahanan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loading || _submitting
                ? null
                : (_student == null ? _loadStudents : _loadStudent),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ajukan penahanan invoice', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Pilih invoice dan jelaskan alasan Anda. Tim keuangan akan meninjau pengajuan ini.'),
          const SizedBox(height: 20),
          if (_students.isNotEmpty)
            DropdownButtonFormField<Student>(
              initialValue: _student,
              decoration: const InputDecoration(labelText: 'Anak', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              items: _students.map((student) => DropdownMenuItem(value: student, child: Text('${student.name} • ${student.class_name}'))).toList(),
              onChanged: _submitting ? null : (student) {
                if (student == null || student == _student) return;
                setState(() { _student = student; _reason.clear(); });
                _loadStudent();
              },
            ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) ...[
            const SizedBox(height: 20),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _student == null ? _loadStudents : _loadStudent, child: const Text('Coba lagi')),
          ] else if (_student == null)
            const HoldEmptyState(message: 'Tidak ada data anak yang terhubung dengan akun Anda.')
          else ...[
            const SizedBox(height: 24),
            const Text('Pilih invoice terbit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Penahanan berlaku untuk seluruh jumlah invoice yang dipilih.'),
            const SizedBox(height: 10),
            if (_invoices.isEmpty)
              const HoldEmptyState(message: 'Tidak ada invoice terbit untuk diajukan.')
            else
              ..._invoices.map((invoice) => Card(
                elevation: 0,
                child: CheckboxListTile(
                  value: _selected.contains(invoice.id),
                  onChanged: _submitting || pendingInvoiceIds.contains(invoice.id) ? null : (checked) => setState(() {
                    if (checked == true) { _selected.add(invoice.id); } else { _selected.remove(invoice.id); }
                  }),
                  title: Text(invoice.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormat('MMM yyyy', 'id_ID').format(invoice.billMonth)} • ${invoice.quantity} x ${holdCurrency(invoice.pricePerItem)}${pendingInvoiceIds.contains(invoice.id) ? '\nSedang menunggu peninjauan' : ''}'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              )),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              enabled: !_submitting,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Alasan pengajuan', hintText: 'Ceritakan alasan Anda mengajukan penahanan', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submitting || _invoices.isEmpty ? null : _submit,
              icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined),
              label: Text(_submitting ? 'Mengirim...' : 'Kirim pengajuan'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 28),
            const Text('Riwayat pengajuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_requests.isEmpty)
              const HoldEmptyState(message: 'Belum ada pengajuan untuk anak ini.')
            else
              ..._requests.map((request) => HoldRequestCard(request: request)),
          ],
        ],
      ),
    );
  }
}
