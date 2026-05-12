import 'package:cloud_firestore/cloud_firestore.dart';

class WalletRequest {
  final String id;
  final String userUid;
  final String userName;
  final String userEmail;
  final String type;
  final double requestedAmount;
  final double creditedAmount;
  final String status;
  final String transferNote;
  final String bankName;
  final String bankBin;
  final String bankAccountNumber;
  final String bankAccountHolder;
  final String note;
  final DateTime createdAt;
  final DateTime? completedAt;

  const WalletRequest({
    required this.id,
    required this.userUid,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.requestedAmount,
    required this.creditedAmount,
    required this.status,
    required this.transferNote,
    required this.bankName,
    required this.bankBin,
    required this.bankAccountNumber,
    required this.bankAccountHolder,
    required this.note,
    required this.createdAt,
    this.completedAt,
  });

  factory WalletRequest.fromMap(Map<String, dynamic> map) {
    return WalletRequest(
      id: map['id'] as String,
      userUid: map['userUid'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      type: map['type'] as String? ?? 'deposit',
      requestedAmount: (map['requestedAmount'] as num?)?.toDouble() ?? 0,
      creditedAmount: (map['creditedAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      transferNote: map['transferNote'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      bankBin: map['bankBin'] as String? ?? '',
      bankAccountNumber: map['bankAccountNumber'] as String? ?? '',
      bankAccountHolder: map['bankAccountHolder'] as String? ?? '',
      note: map['note'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDate(map['completedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}
