class Invoice {
  final String id;
  final String studentId;
  final DateTime billMonth;
  final String status;
  final String itemName;
  final int pricePerItem;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.studentId,
    required this.billMonth,
    required this.status,
    required this.itemName,
    required this.pricePerItem,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      billMonth: DateTime.parse(map['bill_month'] as String),
      status: map['status'] as String,
      itemName: map['item_name'] as String,
      pricePerItem: map['price_per_item'] as int,
      quantity: map['quantity'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'bill_month': billMonth.toIso8601String().split('T').first,
      'status': status,
      'item_name': itemName,
      'price_per_item': pricePerItem,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}