import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../utils/helpers.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edushare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        university TEXT NOT NULL,
        price REAL NOT NULL,
        original_price REAL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        is_new INTEGER DEFAULT 0,
        is_free INTEGER DEFAULT 0,
        discount INTEGER DEFAULT 0,
        image_emoji TEXT NOT NULL,
        image_url TEXT,
        description TEXT,
        condition TEXT DEFAULT 'Như mới',
        is_featured INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        seller_uid TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        university TEXT NOT NULL,
        avatar_emoji TEXT DEFAULT 'avatar',
        total_purchases INTEGER DEFAULT 0,
        total_sales INTEGER DEFAULT 0,
        rating REAL DEFAULT 0.0,
        join_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT,
        logged_in_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        quantity INTEGER DEFAULT 1,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    await _seedData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE user_profile ADD COLUMN password TEXT NOT NULL DEFAULT '123456'",
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_session (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          user_id TEXT,
          logged_in_at TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'products', 'image_url', 'TEXT');
      await _addColumnIfMissing(db, 'products', 'seller_uid', 'TEXT');
    }
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('user_profile', {
      'id': 'user_1',
      'name': 'Trần Ngọc Hoàng',
      'password': '123456',
      'email': 'hoangtn.24itb@vku.udn.vn',
      'phone': '0388431406',
      'university': 'ĐH CNTT & TT Việt - Hàn',
      'avatar_emoji': 'avatar',
      'total_purchases': 12,
      'total_sales': 5,
      'rating': 4.8,
      'join_date': '2023-09-01T00:00:00.000',
    });

    final products = [
      {
        'id': 'p1',
        'title': 'Giáo trình Giải tích 1 - Nguyễn Đình Trí',
        'author': 'Minh Ánh',
        'university': 'ĐH Bách Khoa HN',
        'price': 45000.0,
        'original_price': 550000.0,
        'category': 'Toán - Tin',
        'type': 'sach',
        'is_new': 1,
        'is_free': 0,
        'discount': 42,
        'image_emoji': '',
        'condition': 'Như mới',
        'is_featured': 1,
        'description': 'Sách giải tích 1 còn mới, có highlight nhẹ vài trang đầu. Phù hợp sinh viên năm nhất.',
        'created_at': now,
      },
      {
        'id': 'p2',
        'title': 'Máy tính Casio fx-580VN X',
        'author': 'Thu Hà',
        'university': 'ĐH Kinh tế Quốc dân',
        'price': 380000.0,
        'original_price': 650000.0,
        'category': 'Máy tính',
        'type': 'may_tinh',
        'is_new': 1,
        'is_free': 0,
        'discount': 42,
        'image_emoji': '',
        'condition': 'Như mới',
        'is_featured': 1,
        'description': 'Máy tính Casio chính hãng, pin mới thay, đầy đủ hộp và hướng dẫn.',
        'created_at': now,
      },
      {
        'id': 'p4',
        'title': 'Giáo trình Kinh tế vi mô',
        'author': 'Lan Phương',
        'university': 'ĐH Ngoại thương',
        'price': 55000.0,
        'original_price': 150000.0,
        'category': 'Kinh tế',
        'type': 'sach',
        'is_new': 0,
        'is_free': 0,
        'discount': 63,
        'image_emoji': '',
        'condition': 'Tốt',
        'is_featured': 1,
        'description': 'Sách kinh tế vi mô bản mới nhất, không viết, không highlight.',
        'created_at': now,
      },
      {
        'id': 'r1',
        'title': 'Từ điển Anh-Việt Oxford',
        'author': 'Minh Tuấn',
        'university': 'ĐH Ngoại ngữ HN',
        'price': 120000.0,
        'original_price': 200000.0,
        'category': 'Ngoại ngữ',
        'type': 'sach',
        'is_new': 1,
        'is_free': 0,
        'discount': 40,
        'image_emoji': '',
        'condition': 'Như mới',
        'is_featured': 0,
        'description': 'Từ điển Oxford bản mới, giấy đẹp, chưa dùng đến.',
        'created_at': now,
      },
      {
        'id': 'r2',
        'title': 'Laptop Dell Inspiron 15',
        'author': 'Thanh Hải',
        'university': 'ĐH CNTT TP.HCM',
        'price': 8500000.0,
        'original_price': 12000000.0,
        'category': 'Máy tính',
        'type': 'may_tinh',
        'is_new': 0,
        'is_free': 0,
        'discount': 29,
        'image_emoji': '',
        'condition': 'Tốt',
        'is_featured': 0,
        'description': 'Laptop Dell i5, RAM 8GB, SSD 256GB. Dùng 1 năm, pin còn tốt 80%.',
        'created_at': now,
      },
      {
        'id': 'r3',
        'title': 'Tập vở 200 trang (10 quyển)',
        'author': 'Hồng Linh',
        'university': 'ĐH Sư phạm HN',
        'price': 35000.0,
        'original_price': null,
        'category': 'Dụng cụ',
        'type': 'dung_cu',
        'is_new': 1,
        'is_free': 0,
        'discount': 0,
        'image_emoji': '',
        'condition': 'Như mới',
        'is_featured': 0,
        'description': 'Bộ 10 quyển vở 200 trang chất lượng cao, chưa dùng.',
        'created_at': now,
      },
      {
        'id': 'r4',
        'title': 'Cơ học kết cấu - Lê Ngọc Hồng',
        'author': 'Văn Đức',
        'university': 'ĐH Xây Dựng HN',
        'price': 60000.0,
        'original_price': 180000.0,
        'category': 'Khoa học',
        'type': 'sach',
        'is_new': 0,
        'is_free': 0,
        'discount': 67,
        'image_emoji': '',
        'condition': 'Trung bình',
        'is_featured': 0,
        'description': 'Sách cơ học kết cấu có ghi chú tay, hữu ích cho người học.',
        'created_at': now,
      },
    ];

    for (final p in products) {
      await db.insert('products', p);
    }
  }

  Future<UserProfile?> login(String email, String password) async {
    final db = await database;
    final maps = await db.query(
      'user_profile',
      where: 'LOWER(email) = LOWER(?) AND password = ?',
      whereArgs: [email.trim(), password],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    await db.insert(
      'app_session',
      {
        'id': 1,
        'user_id': maps.first['id'] as String,
        'logged_in_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return UserProfile.fromMap(_normalizeProfileMap(maps.first));
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('app_session', where: 'id = ?', whereArgs: [1]);
  }

  Future<UserProfile?> getCurrentUser() async {
    final db = await database;
    final session = await db.query(
      'app_session',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (session.isEmpty || session.first['user_id'] == null) return null;

    final userId = session.first['user_id'] as String;
    final maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserProfile.fromMap(_normalizeProfileMap(maps.first));
  }

  Future<List<Product>> getFeaturedProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'is_featured = ?',
      whereArgs: [1],
    );
    return maps.map(_normalizeProductMap).map(Product.fromMap).toList();
  }

  Future<List<Product>> getRecentProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'is_featured = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return maps.map(_normalizeProductMap).map(Product.fromMap).toList();
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'created_at DESC');
    return maps.map(_normalizeProductMap).map(Product.fromMap).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'title LIKE ? OR category LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map(_normalizeProductMap).map(Product.fromMap).toList();
  }

  Future<void> insertProduct(Product product, {bool isFeatured = false}) async {
    final db = await database;
    await db.insert(
      'products',
      {
        ...product.toMap(),
        'is_featured': isFeatured ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map(_normalizeProductMap).map(Product.fromMap).toList();
  }

  Future<void> addToCart(String productId) async {
    final db = await database;
    final existing = await db.query(
      'cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'cart',
        {'quantity': (existing.first['quantity'] as int) + 1},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    } else {
      await db.insert('cart', {
        'product_id': productId,
        'quantity': 1,
        'added_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeFromCart(String productId) async {
    final db = await database;
    await db.delete('cart', where: 'product_id = ?', whereArgs: [productId]);
  }

  Future<void> updateCartQuantity(String productId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await removeFromCart(productId);
    } else {
      await db.update(
        'cart',
        {'quantity': quantity},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCartWithProducts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.quantity, p.*
      FROM cart c
      JOIN products p ON c.product_id = p.id
      ORDER BY c.added_at DESC
    ''');
    return rows.map(_normalizeProductMap).toList();
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart');
  }

  Future<UserProfile?> getUserProfile() async {
    return getCurrentUser();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await database;
    await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Map<String, dynamic> _normalizeProductMap(Map<String, dynamic> map) {
    return {
      ...map,
      'title': repairVietnamese((map['title'] ?? '') as String),
      'author': repairVietnamese((map['author'] ?? '') as String),
      'university': repairVietnamese((map['university'] ?? '') as String),
      'category': repairVietnamese((map['category'] ?? '') as String),
      'description': map['description'] == null
          ? null
          : repairVietnamese(map['description'] as String),
      'condition': repairVietnamese((map['condition'] ?? 'Như mới') as String),
    };
  }

  Map<String, dynamic> _normalizeProfileMap(Map<String, dynamic> map) {
    return {
      ...map,
      'name': repairVietnamese((map['name'] ?? '') as String),
      'email': repairVietnamese((map['email'] ?? '') as String),
      'phone': repairVietnamese((map['phone'] ?? '') as String),
      'university': repairVietnamese((map['university'] ?? '') as String),
      'password': map['password'] ?? '123456',
    };
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
