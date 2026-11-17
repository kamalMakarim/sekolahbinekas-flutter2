import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sekolahbinekas/data/invoice_database.dart';
import 'package:sekolahbinekas/data/student_database.dart';
import 'package:sekolahbinekas/models/invoice.dart';
import 'package:sekolahbinekas/models/student.dart';

import 'payment_options_screen.dart';

class InvoicePaymentScreen extends StatefulWidget {
  const InvoicePaymentScreen({super.key});

  @override
  State<InvoicePaymentScreen> createState() => _InvoicePaymentScreenState();
}

class _InvoicePaymentScreenState extends State<InvoicePaymentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _studentDatabase = StudentDatabase();
  final _invoiceDatabase = InvoiceDatabase();

  List<Student> _students = [];
  Student? _selectedStudent;
  List<Invoice> _invoices = [];
  DateTime _selectedPaidMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month - 1,
  );
  bool _isLoadingStudents = true;
  bool _isLoadingInvoices = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadInvoices();
    }
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _studentDatabase.getMyChildren();
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudent = students.isEmpty ? null : students.first;
        _isLoadingStudents = false;
      });
      if (_selectedStudent != null) {
        await _loadInvoices();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
        _errorMessage = 'Tidak dapat memuat data anak. Silakan coba lagi.';
      });
    }
  }

  Future<void> _loadInvoices() async {
    final student = _selectedStudent;
    if (student == null) return;
    setState(() {
      _isLoadingInvoices = true;
      _errorMessage = null;
    });

    try {
      final status = switch (_tabController.index) {
        0 => ['issued'],
        1 => ['on_hold'],
        _ => ['paid'],
      };
      final invoices = await _invoiceDatabase.getInvoicesByStudentId(
        student.id,
        _tabController.index == 2
            ? DateFormat('yyyy-MM-dd').format(_selectedPaidMonth)
            : null,
        status,
      );
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _isLoadingInvoices = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingInvoices = false;
        _errorMessage = 'Tidak dapat memuat invoice. Silakan coba lagi.';
      });
    }
  }

  void _selectStudent(Student? student) {
    if (student == null) return;
    setState(() {
      _selectedStudent = student;
      _selectedPaidMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month - 1,
      );
    });
    _loadInvoices();
  }

  Future<void> _choosePaidMonth() async {
    final now = DateTime.now();
    final firstMonth = DateTime(now.year - 5, 1);
    final lastMonth = DateTime(now.year + 1, 12);
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        var selectedYear = _selectedPaidMonth.year;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih bulan invoice'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: selectedYear,
                      items: [
                        for (
                          var year = firstMonth.year;
                          year <= lastMonth.year;
                          year++
                        )
                          DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                      ],
                      onChanged: (year) {
                        if (year != null) {
                          setDialogState(() => selectedYear = year);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        for (var month = 1; month <= 12; month++)
                          OutlinedButton(
                            onPressed: () {
                              final selectedMonth = DateTime(
                                selectedYear,
                                month,
                                1,
                              );
                              if (selectedMonth.isBefore(firstMonth) ||
                                  selectedMonth.isAfter(lastMonth)) {
                                return;
                              }
                              Navigator.of(context).pop(selectedMonth);
                            },
                            child: Text(
                              DateFormat(
                                'MMM',
                                'id_ID',
                              ).format(DateTime(selectedYear, month, 1)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedPaidMonth = selected);
    _loadInvoices();
  }

  int get _total {
    return _invoices.fold(
      0,
      (total, invoice) => total + _invoiceTotal(invoice),
    );
  }

  int _invoiceTotal(Invoice invoice) => invoice.pricePerItem * invoice.quantity;

  String _formatCurrency(int amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);

  Future<void> _payAllIssued() async {
    final student = _selectedStudent;
    if (_invoices.isEmpty || student == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentOptionsScreen(student: student)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingStudents
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _students.isEmpty
          ? _ErrorState(message: _errorMessage!, onRetry: _loadStudents)
          : RefreshIndicator(
              onRefresh: _loadInvoices,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StudentPicker(
                    students: _students,
                    selectedStudent: _selectedStudent,
                    onChanged: _selectStudent,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: const [
                        Tab(text: 'Terbit'),
                        Tab(text: 'Ditahan'),
                        Tab(text: 'Lunas'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tabController.index == 2)
                    _PaidMonthPicker(
                      selectedMonth: _selectedPaidMonth,
                      onTap: _choosePaidMonth,
                    ),
                  if (_tabController.index == 2) const SizedBox(height: 12),
                  if (_errorMessage != null)
                    _ErrorBanner(message: _errorMessage!),
                  if (_isLoadingInvoices)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_invoices.isEmpty)
                    const _EmptyInvoices()
                  else ...[
                    ..._invoices.map(
                      (invoice) => _InvoiceCard(
                        invoice: invoice,
                        total: _invoiceTotal(invoice),
                        formatCurrency: _formatCurrency,
                      ),
                    ),
                    if (_tabController.index == 0) ...[
                      const SizedBox(height: 8),
                      _TotalCard(
                        total: _total,
                        formatCurrency: _formatCurrency,
                        onPay: _payAllIssued,
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _StudentPicker extends StatelessWidget {
  final List<Student> students;
  final Student? selectedStudent;
  final ValueChanged<Student?> onChanged;

  const _StudentPicker({
    required this.students,
    required this.selectedStudent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih anak', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Student>(
          value: selectedStudent,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: students
              .map(
                (student) => DropdownMenuItem(
                  value: student,
                  child: Text('${student.name} • ${student.class_name}'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final int total;
  final String Function(int) formatCurrency;

  const _InvoiceCard({
    required this.invoice,
    required this.total,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xfffff1d8),
              child: Icon(Icons.receipt_long, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(invoice.billMonth),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    '${invoice.quantity} x ${formatCurrency(invoice.pricePerItem)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(total),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int total;
  final String Function(int) formatCurrency;
  final VoidCallback onPay;

  const _TotalCard({
    required this.total,
    required this.formatCurrency,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total yang harus dibayar',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPay,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                child: const Text('Bayar semua invoice terbit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidMonthPicker extends StatelessWidget {
  final DateTime? selectedMonth;
  final VoidCallback onTap;

  const _PaidMonthPicker({required this.selectedMonth, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month),
      label: Text(
        selectedMonth == null
            ? 'Pilih periode bulan'
            : DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth!),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _EmptyInvoices extends StatelessWidget {
  const _EmptyInvoices();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada invoice pada periode ini'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }
}
