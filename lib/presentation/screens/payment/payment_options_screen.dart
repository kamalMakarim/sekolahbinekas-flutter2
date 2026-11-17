import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sekolahbinekas/data/payment_option_database.dart';
import 'package:sekolahbinekas/models/payment_option.dart';
import 'package:sekolahbinekas/models/student.dart';

class PaymentOptionsScreen extends StatefulWidget {
  final Student student;

  const PaymentOptionsScreen({required this.student, super.key});

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  final _paymentOptionDatabase = PaymentOptionDatabase();
  List<PaymentOption> _paymentOptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentOptions();
  }

  Future<void> _loadPaymentOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final options = await _paymentOptionDatabase.getPaymentOptionsByStudentId(
        widget.student.id,
      );
      if (!mounted) return;
      setState(() {
        _paymentOptions = options.map(PaymentOption.fromMap).toList();
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Failed to load payment options for ${widget.student.id}: $error',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Metode pembayaran tidak dapat dimuat. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode pembayaran'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xfff7f9fc),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadPaymentOptions)
          : _paymentOptions.isEmpty
          ? const Center(child: Text('Metode pembayaran belum tersedia.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Pembayaran untuk ${widget.student.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._paymentOptions.map(
                  (option) => _PaymentOptionTile(option: option),
                ),
              ],
            ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final PaymentOption option;

  const _PaymentOptionTile({required this.option});

  bool get _isQris => option.paymentMethod.trim().toLowerCase() == 'qris';

  @override
  Widget build(BuildContext context) {
    final value = _isQris ? option.key : option.VANumber;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.paymentMethod.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isQris && value.isNotEmpty)
              Center(
                child: QrImageView(
                  data: value,
                  size: 220,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) =>
                      const Text('QRIS tidak dapat ditampilkan.'),
                ),
              )
            else if (value.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin nomor VA',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: option.VANumber),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nomor VA disalin')),
                      );
                    },
                  ),
                ],
              )
            else
              const Text('Ikuti instruksi pembayaran'),
          ],
        ),
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
