import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseRecord {
  final String id;
  final String userUid;
  final String title;
  final String category;
  final String type;
  final double amount;
  final String note;
  final DateTime occurredAt;
  final DateTime createdAt;

  const ExpenseRecord({
    required this.id,
    required this.userUid,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.note,
    required this.occurredAt,
    required this.createdAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toFirestore() {
    return {
      'userUid': userUid,
      'title': title,
      'category': category,
      'type': type,
      'amount': amount,
      'note': note,
      'occurredAt': occurredAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseRecord.fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] as String,
      userUid: map['userUid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Khac',
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String? ?? '',
      occurredAt: _parseDate(map['occurredAt']) ?? DateTime.now(),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
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
