class Product {
  final String id;
  final String title;
  final String author;
  final String university;
  final double price;
  final double? originalPrice;
  final String category;
  final String type;
  final bool isNew;
  final bool isFree;
  final int discount;
  final String imageEmoji;
  final String? imageUrl;
  final String? description;
  final String condition;
  final bool isFeatured;
  final DateTime? createdAt;
  final String? sellerUid;

  const Product({
    required this.id,
    required this.title,
    required this.author,
    required this.university,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.type,
    this.isNew = false,
    this.isFree = false,
    this.discount = 0,
    required this.imageEmoji,
    this.imageUrl,
    this.description,
    this.condition = 'Như mới',
    this.isFeatured = false,
    this.createdAt,
    this.sellerUid,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    final dynamic isNewValue = map['is_new'] ?? map['isNew'] ?? false;
    final dynamic isFreeValue = map['is_free'] ?? map['isFree'] ?? false;
    final dynamic isFeaturedValue = map['is_featured'] ?? map['isFeatured'] ?? false;

    bool normalizeBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value == 1;
      return false;
    }

    return Product(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      university: map['university'] as String,
      price: (map['price'] as num).toDouble(),
      originalPrice: map['original_price'] != null
          ? (map['original_price'] as num).toDouble()
          : (map['originalPrice'] != null ? (map['originalPrice'] as num).toDouble() : null),
      category: map['category'] as String,
      type: map['type'] as String,
      isNew: normalizeBool(isNewValue),
      isFree: normalizeBool(isFreeValue),
      discount: (map['discount'] as num?)?.toInt() ?? 0,
      imageEmoji: map['image_emoji'] as String? ?? map['imageEmoji'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? map['imageUrl'] as String?,
      description: map['description'] as String?,
      condition: map['condition'] as String? ?? 'Như mới',
      isFeatured: normalizeBool(isFeaturedValue),
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : (map['createdAt'] is String ? DateTime.tryParse(map['createdAt'] as String) : null),
      sellerUid: map['seller_uid'] as String? ?? map['sellerUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'university': university,
      'price': price,
      'original_price': originalPrice,
      'category': category,
      'type': type,
      'is_new': isNew ? 1 : 0,
      'is_free': isFree ? 1 : 0,
      'discount': discount,
      'image_emoji': imageEmoji,
      'image_url': imageUrl,
      'description': description,
      'condition': condition,
      'is_featured': isFeatured ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'seller_uid': sellerUid,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'university': university,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'type': type,
      'isNew': isNew,
      'isFree': isFree,
      'discount': discount,
      'imageEmoji': imageEmoji,
      'imageUrl': imageUrl,
      'description': description,
      'condition': condition,
      'isFeatured': isFeatured,
      'createdAt': createdAt?.toIso8601String(),
      'sellerUid': sellerUid,
    };
  }
}
