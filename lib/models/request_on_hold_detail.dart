class RequestOnHoldDetail {
  final String id;
  final String requestOnHoldId;
  final String invoiceId;
  final int quantity;

  RequestOnHoldDetail({
    required this.id,
    required this.requestOnHoldId,
    required this.invoiceId,
    required this.quantity,
  });

  //map -> RequestOnHoldDetail
  factory RequestOnHoldDetail.fromMap(Map<String, dynamic> map) {
    return RequestOnHoldDetail(
      id: map['id'] as String,
      requestOnHoldId: map['request_on_hold_id'] as String,
      invoiceId: map['invoice_id'] as String,
      quantity: map['qty'] as int,
    );
  }

  //Serialize RequestOnHoldDetail to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'request_on_hold_id': requestOnHoldId,
      'invoice_id': invoiceId,
      'qty': quantity,
    };
  }
}