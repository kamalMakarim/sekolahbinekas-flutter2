import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sekolahbinekas/models/request_on_hold.dart';

String holdCurrency(int amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(amount);

class HoldRequestCard extends StatelessWidget {
  const HoldRequestCard({super.key, required this.request, this.actions});

  final RequestOnHold request;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (request.requestStatus) {
      'pending' => ('Menunggu', Colors.orange, Icons.schedule),
      'approved' => ('Disetujui', Colors.green, Icons.check_circle_outline),
      'rejected' => ('Ditolak', Colors.red, Icons.cancel_outlined),
      _ => (request.requestStatus, Colors.grey, Icons.info_outline),
    };
    final total = request.invoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.pricePerItem * invoice.quantity,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${request.className}  •  ${DateFormat('d MMM yyyy', 'id_ID').format(request.createdAt.toLocal())}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            const Text('Alasan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(request.reason),
            const SizedBox(height: 14),
            const Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (request.invoices.isEmpty)
              const Text('Detail invoice tidak tersedia.')
            else
              ...request.invoices.map((invoice) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${invoice.name} • ${DateFormat('MMM yyyy', 'id_ID').format(invoice.billMonth)}'
                  '\n${invoice.quantity} x ${holdCurrency(invoice.pricePerItem)}',
                ),
              )),
            if (request.invoices.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Total: ${holdCurrency(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            if (request.requestStatus != 'pending') ...[
              const SizedBox(height: 8),
              Text(
                'Diproses ${DateFormat('d MMM yyyy', 'id_ID').format(request.updatedAt.toLocal())}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            if (actions != null) ...[
              const SizedBox(height: 12),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}

class HoldEmptyState extends StatelessWidget {
  const HoldEmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey.shade300),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade600)),
      ],
    ),
  );
}
