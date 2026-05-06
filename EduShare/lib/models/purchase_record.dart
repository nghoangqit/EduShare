class PurchaseRecord {
  final String id;
  final String productId;
  final String productTitle;
  final String productAuthor;
  final String productUniversity;
  final String productType;
  final String? productImageUrl;
  final String sellerUid;
  final double productPrice;
  final int quantity;
  final double totalPrice;
  final String status;
  final String paymentMethod;
  final String transferNote;
  final DateTime createdAt;

  const PurchaseRecord({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productAuthor,
    required this.productUniversity,
    required this.productType,
    this.productImageUrl,
    required this.sellerUid,
    required this.productPrice,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.transferNote,
    required this.createdAt,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      id: map['id'] as String,
      productId: map['productId'] as String? ?? '',
      productTitle: map['productTitle'] as String? ?? '',
      productAuthor: map['productAuthor'] as String? ?? '',
      productUniversity: map['productUniversity'] as String? ?? '',
      productType: map['productType'] as String? ?? 'sach',
      productImageUrl: map['productImageUrl'] as String?,
      sellerUid: map['sellerUid'] as String? ?? '',
      productPrice: (map['productPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'confirmed',
      paymentMethod: map['paymentMethod'] as String? ?? 'online',
      transferNote: map['transferNote'] as String? ?? '',
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
