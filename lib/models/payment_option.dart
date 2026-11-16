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
      id: map['id'] as String,
      paymentMethod: map['payment_method'] as String,
      VANumber: map['va_number'] as String,
      key: map['key'] as String,
      studentId: map['student_id'] as String, 
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