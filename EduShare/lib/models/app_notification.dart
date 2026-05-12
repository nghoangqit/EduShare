import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userUid;
  final String title;
  final String body;
  final String type;
  final String orderId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userUid,
    required this.title,
    required this.body,
    required this.type,
    required this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userUid: map['userUid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      orderId: map['orderId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
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
