import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/user_profile.dart';

class FirebaseDataService {
  FirebaseDataService._();

  static final FirebaseDataService instance = FirebaseDataService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _products => _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<UserProfile> ensureUserProfile(User firebaseUser) async {
    final doc = _users.doc(firebaseUser.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      final profile = UserProfile(
        id: firebaseUser.uid,
        name: firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!
            : 'Nguoi dung EduShare',
        email: firebaseUser.email ?? '',
        phone: '',
        university: '',
        joinDate: DateTime.now(),
      );
      await doc.set(profile.toFirestore());
      return profile;
    }

    return UserProfile.fromMap({
      'id': firebaseUser.uid,
      ...snapshot.data()!,
    });
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return ensureUserProfile(user);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _users.doc(profile.id).set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<List<Product>> getAllProducts() async {
    final snapshot = await _products.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_productFromDoc).toList();
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

  Future<void> insertProduct(Product product) async {
    await _products.doc(product.id).set(product.toFirestore());
  }

  Product _productFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap({
      'id': doc.id,
      ...doc.data(),
    });
  }
}
