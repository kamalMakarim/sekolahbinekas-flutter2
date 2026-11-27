class RequestOnHold {
  final String id;
  final String reason;
  final String studentId;
  final String requestStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String studentName;
  final String className;
  final List<HoldInvoice> invoices;

  RequestOnHold({
    required this.id,
    required this.reason,
    required this.studentId,
    required this.requestStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.studentName,
    required this.className,
    required this.invoices,
  });

  //map -> RequestOnHold
  factory RequestOnHold.fromMap(Map<String, dynamic> map) {
    return RequestOnHold(
      id: map['id'] as String,
      reason: map['reason'] as String,
      studentId: map['student_id'] as String,
      requestStatus: map['request_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      studentName: (map['students'] as Map<String, dynamic>)['name'] as String,
      className:
          (map['students'] as Map<String, dynamic>)['class_name'] as String,
      invoices: (map['request_on_hold_detail'] as List<dynamic>)
          .map((detail) => HoldInvoice.fromMap(detail as Map<String, dynamic>))
          .toList(),
    );
  }

  //Serialize RequestOnHold to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'student_id': studentId,
      'request_status': requestStatus,
    };
  }
}

class HoldInvoice {
    final String id;
    final String name;
    final DateTime billMonth;
    final int quantity;
    final int pricePerItem;

    HoldInvoice({
      required this.id,
      required this.name,
      required this.billMonth,
      required this.quantity,
      required this.pricePerItem,
    });

    factory HoldInvoice.fromMap(Map<String, dynamic> map) {
      final invoice = map['invoices'] as Map<String, dynamic>;
      return HoldInvoice(
        id: map['invoice_id'] as String,
        name: invoice['item_name'] as String,
        billMonth: DateTime.parse(invoice['bill_month'] as String),
        quantity: map['qty'] as int,
        pricePerItem: invoice['price_per_item'] as int,
      );
    }
}