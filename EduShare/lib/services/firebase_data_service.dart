import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/user_profile.dart';

class FirebaseDataService {
  FirebaseDataService._();

  static final FirebaseDataService instance = FirebaseDataService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection('favorites');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<UserProfile> ensureUserProfile(User firebaseUser) async {
    final fallbackProfile = UserProfile(
      id: firebaseUser.uid,
      name: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!
          : 'Nguoi dung EduShare',
      email: firebaseUser.email ?? '',
      phone: '',
      university: '',
      joinDate: DateTime.now(),
    );

    try {
      final doc = _users.doc(firebaseUser.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set(fallbackProfile.toFirestore());
        return fallbackProfile;
      }

      return UserProfile.fromMap({
        'id': firebaseUser.uid,
        ...snapshot.data()!,
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return fallbackProfile;
      }
      rethrow;
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return ensureUserProfile(user);
  }

  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final snapshot = await _users.doc(userId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfile.fromMap({
        'id': userId,
        ...snapshot.data()!,
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _users
          .doc(profile.id)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _products
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map(_productFromDoc).toList();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.isFeatured).toList();
  }

  Future<List<Product>> getRecentProducts() async {
    final snapshot = await _products
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map(_productFromDoc).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final q = query.trim().toLowerCase();
    return products.where((product) {
      return product.title.toLowerCase().contains(q) ||
          product.category.toLowerCase().contains(q) ||
          product.author.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<Product>> getProductsBySeller(String sellerUid) async {
    try {
      final snapshot = await _products
          .where('sellerUid', isEqualTo: sellerUid)
          .get();
      final products = snapshot.docs.map(_productFromDoc).toList();
      products.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
      return products;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<List<PurchaseRecord>> getPurchaseHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _orders
          .where('buyerUid', isEqualTo: user.uid)
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        return PurchaseRecord.fromMap({'id': doc.id, ...data});
      }).toList();
      records.sort((a, b) {
        final aPending = a.status == 'pending_payment' ? 1 : 0;
        final bPending = b.status == 'pending_payment' ? 1 : 0;
        if (aPending != bPending) {
          return bPending.compareTo(aPending);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return records;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<List<String>> createOrdersFromCart(
    List<CartItem> items, {
    Map<String, String>? transferNotesBySeller,
    String status = 'paid',
    String paymentMethod = 'online',
  }) async {
    final user = _auth.currentUser;
    if (user == null || items.isEmpty) return const [];

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    final orderIds = <String>[];

    for (final item in items) {
      final orderRef = _orders.doc();
      orderIds.add(orderRef.id);
      batch.set(orderRef, {
        'buyerUid': user.uid,
        'productId': item.product.id,
        'productTitle': item.product.title,
        'productAuthor': item.product.author,
        'productUniversity': item.product.university,
        'productType': item.product.type,
        'productImageUrl': item.product.imageUrl,
        'sellerUid': item.product.sellerUid ?? '',
        'productPrice': item.product.price,
        'quantity': item.quantity,
        'totalPrice': item.totalPrice,
        'status': status,
        'paymentMethod': paymentMethod,
        'transferNote': transferNotesBySeller?[item.product.sellerUid ?? ''] ?? '',
        'createdAt': now,
      });
    }

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      return const [];
    }
    return orderIds;
  }

  Future<bool> isFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _favorites.doc('${user.uid}_$productId').get();
      return doc.exists;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return false;
      rethrow;
    }
  }

  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _favorites.doc('${user.uid}_${product.id}');
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        await docRef.delete();
        return;
      }

      await docRef.set({
        'userUid': user.uid,
        'productId': product.id,
        'createdAt': DateTime.now().toIso8601String(),
        'product': product.toFirestore(),
      });
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<List<Product>> getFavoriteProducts() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _favorites
          .where('userUid', isEqualTo: user.uid)
          .get();

      final docs = [...snapshot.docs]
        ..sort(
          (a, b) => ((b.data()['createdAt'] ?? '') as String).compareTo(
            (a.data()['createdAt'] ?? '') as String,
          ),
        );

      final favorites = <Product>[];
      for (final doc in docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        if (productId == null || productId.trim().isEmpty) continue;

        final productDoc = await _products.doc(productId).get();
        if (productDoc.exists && productDoc.data() != null) {
          favorites.add(_productFromSnapshot(productDoc));
          continue;
        }

        final cached = data['product'];
        if (cached is Map<String, dynamic>) {
          favorites.add(Product.fromMap({'id': productId, ...cached}));
        }
      }
      return favorites;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<int> getFavoriteCount() async {
    final products = await getFavoriteProducts();
    return products.length;
  }

  Future<int> getSellingCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final products = await getProductsBySeller(user.uid);
    return products.length;
  }

  Future<int> getPurchaseCount() async {
    final orders = await getPurchaseHistory();
    return orders.fold<int>(0, (total, order) => total + order.quantity);
  }

  Future<void> insertProduct(Product product) async {
    await _products.doc(product.id).set(product.toFirestore());
  }

  Product _productFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap({'id': doc.id, ...doc.data()});
  }

  Product _productFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap({'id': doc.id, ...?doc.data()});
  }
}
