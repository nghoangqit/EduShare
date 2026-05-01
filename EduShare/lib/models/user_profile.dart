class UserProfile {
  final String id;
  String name;
  String email;
  String phone;
  String university;
  String avatarEmoji;
  String? avatarBase64;
  int totalPurchases;
  int totalSales;
  double rating;
  DateTime joinDate;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.university,
    this.avatarEmoji = 'avatar',
    this.avatarBase64,
    this.totalPurchases = 0,
    this.totalSales = 0,
    this.rating = 0.0,
    required this.joinDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      university: map['university'] as String? ?? '',
      avatarEmoji: map['avatar_emoji'] as String? ?? map['avatarEmoji'] as String? ?? 'avatar',
      avatarBase64: map['avatar_base64'] as String? ?? map['avatarBase64'] as String?,
      totalPurchases: (map['total_purchases'] as num?)?.toInt() ?? (map['totalPurchases'] as num?)?.toInt() ?? 0,
      totalSales: (map['total_sales'] as num?)?.toInt() ?? (map['totalSales'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      joinDate: DateTime.tryParse((map['join_date'] ?? map['joinDate'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'university': university,
      'avatar_emoji': avatarEmoji,
      'avatar_base64': avatarBase64,
      'total_purchases': totalPurchases,
      'total_sales': totalSales,
      'rating': rating,
      'join_date': joinDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'university': university,
      'avatarEmoji': avatarEmoji,
      'avatarBase64': avatarBase64,
      'totalPurchases': totalPurchases,
      'totalSales': totalSales,
      'rating': rating,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  bool get isIncomplete {
    final normalizedName = name.trim().toLowerCase();
    return normalizedName.isEmpty ||
        normalizedName == 'nguoi dung edushare' ||
        phone.trim().isEmpty ||
        university.trim().isEmpty;
  }

  bool get hasCustomAvatar => avatarBase64 != null && avatarBase64!.trim().isNotEmpty;
}
