import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

class UserProfile {
  final String id;
  String name;
  String email;
  String phone;
  String university;
  String shippingAddress;
  double? shippingLatitude;
  double? shippingLongitude;
  String avatarEmoji;
  String? avatarBase64;
  String bankName;
  String bankBin;
  String bankAccountNumber;
  String bankAccountHolder;
  int totalPurchases;
  int totalSales;
  double rating;
  double walletBalance;
  bool isAdmin;
  bool isBanned;
  DateTime joinDate;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.university,
    this.shippingAddress = '',
    this.shippingLatitude,
    this.shippingLongitude,
    this.avatarEmoji = 'avatar',
    this.avatarBase64,
    this.bankName = '',
    this.bankBin = '',
    this.bankAccountNumber = '',
    this.bankAccountHolder = '',
    this.totalPurchases = 0,
    this.totalSales = 0,
    this.rating = 0.0,
    this.walletBalance = 0.0,
    this.isAdmin = false,
    this.isBanned = false,
    required this.joinDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      university: map['university'] as String? ?? '',
      shippingAddress:
          map['shipping_address'] as String? ??
          map['shippingAddress'] as String? ??
          '',
      shippingLatitude:
          (map['shipping_latitude'] as num?)?.toDouble() ??
          (map['shippingLatitude'] as num?)?.toDouble(),
      shippingLongitude:
          (map['shipping_longitude'] as num?)?.toDouble() ??
          (map['shippingLongitude'] as num?)?.toDouble(),
      avatarEmoji:
          map['avatar_emoji'] as String? ??
          map['avatarEmoji'] as String? ??
          'avatar',
      avatarBase64:
          map['avatar_base64'] as String? ?? map['avatarBase64'] as String?,
      bankName:
          map['bank_name'] as String? ??
          map['bankName'] as String? ??
          map['momo_provider'] as String? ??
          map['momoProvider'] as String? ??
          '',
      bankBin: map['bank_bin'] as String? ?? map['bankBin'] as String? ?? '',
      bankAccountNumber:
          map['bank_account_number'] as String? ??
          map['bankAccountNumber'] as String? ??
          map['momo_number'] as String? ??
          map['momoNumber'] as String? ??
          '',
      bankAccountHolder:
          map['bank_account_holder'] as String? ??
          map['bankAccountHolder'] as String? ??
          map['momo_name'] as String? ??
          map['momoName'] as String? ??
          '',
      totalPurchases:
          (map['total_purchases'] as num?)?.toInt() ??
          (map['totalPurchases'] as num?)?.toInt() ??
          0,
      totalSales:
          (map['total_sales'] as num?)?.toInt() ??
          (map['totalSales'] as num?)?.toInt() ??
          0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      walletBalance:
          (map['wallet_balance'] as num?)?.toDouble() ??
          (map['walletBalance'] as num?)?.toDouble() ??
          0.0,
      isAdmin:
          map['is_admin'] as bool? ??
          map['isAdmin'] as bool? ??
          AdminConfig.isAdminEmail(map['email'] as String?),
      isBanned: map['is_banned'] as bool? ?? map['isBanned'] as bool? ?? false,
      joinDate:
          _parseDate(map['join_date'] ?? map['joinDate'] ?? DateTime.now()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'university': university,
      'shipping_address': shippingAddress,
      'shipping_latitude': shippingLatitude,
      'shipping_longitude': shippingLongitude,
      'avatar_emoji': avatarEmoji,
      'avatar_base64': avatarBase64,
      'bank_name': bankName,
      'bank_bin': bankBin,
      'bank_account_number': bankAccountNumber,
      'bank_account_holder': bankAccountHolder,
      'momo_provider': bankName,
      'momo_number': bankAccountNumber,
      'momo_name': bankAccountHolder,
      'total_purchases': totalPurchases,
      'total_sales': totalSales,
      'rating': rating,
      'wallet_balance': walletBalance,
      'is_admin': isAdmin,
      'is_banned': isBanned,
      'join_date': joinDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'university': university,
      'shippingAddress': shippingAddress,
      'shippingLatitude': shippingLatitude,
      'shippingLongitude': shippingLongitude,
      'avatarEmoji': avatarEmoji,
      'avatarBase64': avatarBase64,
      'bankName': bankName,
      'bankBin': bankBin,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolder': bankAccountHolder,
      'momoProvider': bankName,
      'momoNumber': bankAccountNumber,
      'momoName': bankAccountHolder,
      'totalPurchases': totalPurchases,
      'totalSales': totalSales,
      'rating': rating,
      'walletBalance': walletBalance,
      'isAdmin': isAdmin,
      'isBanned': isBanned,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  bool get isIncomplete {
    final normalizedName = name.trim().toLowerCase();
    return normalizedName.isEmpty ||
        normalizedName == 'nguoi dung edushare' ||
        phone.trim().isEmpty ||
        university.trim().isEmpty ||
        shippingAddress.trim().isEmpty;
  }

  bool get hasCustomAvatar =>
      avatarBase64 != null && avatarBase64!.trim().isNotEmpty;

  bool get hasShippingLocation =>
      shippingLatitude != null && shippingLongitude != null;

  bool get hasBankAccount =>
      bankName.trim().isNotEmpty &&
      bankBin.trim().isNotEmpty &&
      bankAccountNumber.trim().isNotEmpty &&
      bankAccountHolder.trim().isNotEmpty;

  bool get hasMomoAccount => hasBankAccount;

  String get momoProvider => bankName;
  set momoProvider(String value) => bankName = value;

  String get momoNumber => bankAccountNumber;
  set momoNumber(String value) => bankAccountNumber = value;

  String get momoName => bankAccountHolder;
  set momoName(String value) => bankAccountHolder = value;

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
