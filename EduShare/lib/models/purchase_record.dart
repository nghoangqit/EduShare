import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseRecord {
  final String id;
  final String buyerUid;
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
  final String recipientName;
  final String recipientPhone;
  final String shippingAddress;
  final double sellerPayoutAmount;
  final double platformFeeAmount;
  final bool payoutReleased;
  final String payoutMessage;
  final DateTime createdAt;
  final DateTime? adminConfirmedAt;
  final DateTime? deliveredAt;
  final DateTime? payoutReleasedAt;

  const PurchaseRecord({
    required this.id,
    required this.buyerUid,
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
    required this.recipientName,
    required this.recipientPhone,
    required this.shippingAddress,
    required this.sellerPayoutAmount,
    required this.platformFeeAmount,
    required this.payoutReleased,
    required this.payoutMessage,
    required this.createdAt,
    this.adminConfirmedAt,
    this.deliveredAt,
    this.payoutReleasedAt,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      id: map['id'] as String,
      buyerUid: map['buyerUid'] as String? ?? '',
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
      recipientName: map['recipientName'] as String? ?? '',
      recipientPhone: map['recipientPhone'] as String? ?? '',
      shippingAddress: map['shippingAddress'] as String? ?? '',
      sellerPayoutAmount: (map['sellerPayoutAmount'] as num?)?.toDouble() ?? 0,
      platformFeeAmount: (map['platformFeeAmount'] as num?)?.toDouble() ?? 0,
      payoutReleased: map['payoutReleased'] as bool? ?? false,
      payoutMessage: map['payoutMessage'] as String? ?? '',
      createdAt: _parseFirestoreDate(map['createdAt']) ?? DateTime.now(),
      adminConfirmedAt: _parseFirestoreDate(map['adminConfirmedAt']),
      deliveredAt: _parseFirestoreDate(map['deliveredAt']),
      payoutReleasedAt: _parseFirestoreDate(map['payoutReleasedAt']),
    );
  }

  static DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) return null;
      return DateTime.tryParse(normalized);
    }
    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'];
      final nanoseconds = value['_nanoseconds'];
      if (seconds is int) {
        final millis =
            (seconds * 1000) + ((nanoseconds as int? ?? 0) ~/ 1000000);
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
    return DateTime.tryParse(value.toString());
  }
}
