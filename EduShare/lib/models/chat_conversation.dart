import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String buyerUid;
  final String sellerUid;
  final String productId;
  final String productTitle;
  final String productType;
  final String? productImageUrl;
  final String lastMessage;
  final String lastSenderUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.buyerUid,
    required this.sellerUid,
    required this.productId,
    required this.productTitle,
    required this.productType,
    this.productImageUrl,
    required this.lastMessage,
    required this.lastSenderUid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    final namesRaw = map['participantNames'];
    final names = <String, String>{};
    if (namesRaw is Map) {
      for (final entry in namesRaw.entries) {
        names[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    return ChatConversation(
      id: map['id'] as String,
      participantIds: ((map['participantIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      participantNames: names,
      buyerUid: map['buyerUid'] as String? ?? '',
      sellerUid: map['sellerUid'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productTitle: map['productTitle'] as String? ?? '',
      productType: map['productType'] as String? ?? 'sach',
      productImageUrl: map['productImageUrl'] as String?,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastSenderUid: map['lastSenderUid'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'buyerUid': buyerUid,
      'sellerUid': sellerUid,
      'productId': productId,
      'productTitle': productTitle,
      'productType': productType,
      'productImageUrl': productImageUrl,
      'lastMessage': lastMessage,
      'lastSenderUid': lastSenderUid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String displayNameFor(String currentUserId) {
    if (currentUserId == sellerUid) {
      return participantNames[buyerUid] ?? 'Nguoi mua';
    }
    return participantNames[sellerUid] ?? 'Nguoi ban';
  }

  String partnerUidFor(String currentUserId) {
    return currentUserId == sellerUid ? buyerUid : sellerUid;
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
