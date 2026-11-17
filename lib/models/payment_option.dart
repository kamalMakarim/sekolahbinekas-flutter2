class PaymentOption {
  final String id;
  final String paymentMethod;
  final String VANumber;
  final String key;
  final String studentId;

  PaymentOption({
    required this.id,
    required this.paymentMethod,
    required this.VANumber,
    required this.key,
    required this.studentId,
  });

  factory PaymentOption.fromMap(Map<String, dynamic> map) {
    return PaymentOption(
      id: map['id']?.toString() ?? '',
      paymentMethod: map['payment_method']?.toString() ?? '',
      VANumber: map['va_number']?.toString() ?? '',
      key: map['key']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_method': paymentMethod,
      'va_number': VANumber,
      'key': key,
      'student_id': studentId,
    };
  }
}
