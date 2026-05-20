import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/user_profile.dart';
import '../models/wallet_request.dart';
import '../utils/constants.dart';
import 'payos_service.dart';
import 'support_bot_service.dart';

enum FavoriteToggleResult {
  success,
  unauthenticated,
  permissionDenied,
  networkError,
  timeout,
}

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
  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _walletRequests =>
      _firestore.collection('walletRequests');
  CollectionReference<Map<String, dynamic>> get _bankTransactions =>
      _firestore.collection('bankTransactions');

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserProfile> ensureUserProfile(User firebaseUser) async {
    final fallbackProfile = UserProfile(
      id: firebaseUser.uid,
      name: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!
          : 'Nguoi dung EduShare',
      email: firebaseUser.email ?? '',
      phone: '',
      university: '',
      isAdmin: AdminConfig.isAdminEmail(firebaseUser.email),
      joinDate: DateTime.now(),
    );

    try {
      final doc = _users.doc(firebaseUser.uid);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set(fallbackProfile.toFirestore());
        return fallbackProfile;
      }

      return UserProfile.fromMap({'id': firebaseUser.uid, ...snapshot.data()!});
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
      return UserProfile.fromMap({'id': userId, ...snapshot.data()!});
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<UserProfile?> getPrimaryAdminProfile() async {
    final users = await getAllUsers();
    for (final user in users) {
      if (user.isAdmin || AdminConfig.isAdminEmail(user.email)) {
        return user;
      }
    }
    return null;
  }

  Future<List<UserProfile>> getAllUsers() async {
    try {
      final snapshot = await _users.get();
      final users = snapshot.docs
          .map((doc) => UserProfile.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
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

  Future<List<WalletRequest>> getAllWalletRequests() async {
    try {
      final snapshot = await _walletRequests.get();
      final requests = snapshot.docs
          .map((doc) => WalletRequest.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<List<WalletRequest>> getCurrentUserWalletRequests() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _walletRequests
          .where('userUid', isEqualTo: user.uid)
          .get();
      final requests = snapshot.docs
          .map((doc) => WalletRequest.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<WalletRequest?> requestWalletDeposit(double requestedAmount) async {
    final user = _auth.currentUser;
    if (user == null || requestedAmount <= 0) return null;

    final profile = await ensureUserProfile(user);
    final requestRef = _walletRequests.doc();
    final payosOrderCode = _buildPayosOrderCode();
    final note =
        'NAP-${user.uid.substring(0, user.uid.length < 6 ? user.uid.length : 6).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final creditedAmount = requestedAmount * AdminConfig.walletTopupCreditRate;
    final now = DateTime.now().toIso8601String();

    try {
      final initialData = {
        'userUid': user.uid,
        'userName': profile.name,
        'userEmail': profile.email,
        'type': 'deposit',
        'requestedAmount': requestedAmount,
        'creditedAmount': creditedAmount,
        'status': 'pending',
        'transferNote': note,
        'bankName': '',
        'bankBin': '',
        'bankAccountNumber': '',
        'bankAccountHolder': '',
        'note': 'Nap ${requestedAmount.toStringAsFixed(0)}d vao vi EduShare',
        'paymentProvider': 'payos',
        'payosOrderCode': payosOrderCode,
        'payosStatus': '',
        'payosPaymentLinkId': '',
        'payosCheckoutUrl': '',
        'payosQrCode': '',
        'createdAt': now,
      };
      await requestRef.set(initialData);

      final payosLink = await PayosService.instance.createWalletTopupLink(
        requestId: requestRef.id,
        orderCode: payosOrderCode,
        amount: requestedAmount.round(),
        description: note,
        buyerName: profile.name,
        buyerEmail: profile.email,
      );
      final payosData = payosLink == null
          ? const <String, dynamic>{'paymentProvider': 'bank_transfer'}
          : <String, dynamic>{
              'paymentProvider': 'payos',
              'payosPaymentLinkId': payosLink.paymentLinkId,
              'payosCheckoutUrl': payosLink.checkoutUrl,
              'payosQrCode': payosLink.qrCode,
              'payosStatus': payosLink.status,
            };
      await requestRef.set(payosData, SetOptions(merge: true));

      await _notifyAdmins(
        title: 'Co yeu cau nap tien moi',
        body:
            '${profile.name} vua tao yeu cau nap ${requestedAmount.toStringAsFixed(0)}d vao vi EduShare.',
        type: 'wallet_deposit_requested',
      );
      return WalletRequest.fromMap({
        'id': requestRef.id,
        ...initialData,
        ...payosData,
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  int _buildPayosOrderCode() {
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return microseconds % 9007199254740991;
  }

  Future<WalletRequest?> requestWalletWithdrawal(double amount) async {
    final user = _auth.currentUser;
    if (user == null || amount <= 0) return null;

    final profile = await ensureUserProfile(user);
    if (!profile.hasBankAccount || profile.walletBalance < amount) {
      return null;
    }

    final requestRef = _walletRequests.doc();
    final note =
        'RUT-${user.uid.substring(0, user.uid.length < 6 ? user.uid.length : 6).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      final batch = _firestore.batch();
      batch.set(requestRef, {
        'userUid': user.uid,
        'userName': profile.name,
        'userEmail': profile.email,
        'type': 'withdrawal',
        'requestedAmount': amount,
        'creditedAmount': amount,
        'status': 'pending',
        'transferNote': note,
        'bankName': profile.bankName,
        'bankBin': profile.bankBin,
        'bankAccountNumber': profile.bankAccountNumber,
        'bankAccountHolder': profile.bankAccountHolder,
        'note': 'Rut ${amount.toStringAsFixed(0)}d tu vi EduShare',
        'createdAt': DateTime.now().toIso8601String(),
      });
      batch.set(_users.doc(user.uid), {
        'walletBalance': profile.walletBalance - amount,
      }, SetOptions(merge: true));
      await batch.commit();

      await _notifyAdmins(
        title: 'Co yeu cau rut tien moi',
        body:
            '${profile.name} muon rut ${amount.toStringAsFixed(0)}d khoi vi EduShare.',
        type: 'wallet_withdrawal_requested',
      );

      return WalletRequest.fromMap({
        'id': requestRef.id,
        'userUid': user.uid,
        'userName': profile.name,
        'userEmail': profile.email,
        'type': 'withdrawal',
        'requestedAmount': amount,
        'creditedAmount': amount,
        'status': 'pending',
        'transferNote': note,
        'bankName': profile.bankName,
        'bankBin': profile.bankBin,
        'bankAccountNumber': profile.bankAccountNumber,
        'bankAccountHolder': profile.bankAccountHolder,
        'note': 'Rut ${amount.toStringAsFixed(0)}d tu vi EduShare',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
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
    try {
      final snapshot = await _products
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs.map(_productFromDoc).toList();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
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

  Future<List<String>> getRecommendedSearchKeywords({int limit = 10}) async {
    final scores = <String, int>{};

    void addKeyword(String? value, int weight) {
      final normalized = _normalizeRecommendationText(value);
      if (normalized == null) return;
      scores.update(
        normalized,
        (current) => current + weight,
        ifAbsent: () => weight,
      );
    }

    final profile = await getCurrentUserProfile();
    final favoriteProducts = await getFavoriteProducts();
    final purchaseHistory = await getPurchaseHistory();
    final conversations = await _getCurrentUserConversationsForRecommendation();
    final featuredProducts = await getFeaturedProducts();
    final recentProducts = await getRecentProducts();

    addKeyword(profile?.university, 18);

    for (final product in favoriteProducts) {
      addKeyword(product.category, 16);
      addKeyword(product.author, 12);
      addKeyword(product.title, 10);
      addKeyword(_typeRecommendationLabel(product.type), 10);
      addKeyword(product.university, 11);
    }

    for (final order in purchaseHistory) {
      addKeyword(order.productTitle, 18);
      addKeyword(order.productAuthor, 14);
      addKeyword(order.productUniversity, 14);
      addKeyword(_typeRecommendationLabel(order.productType), 12);
    }

    for (final conversation in conversations) {
      addKeyword(conversation.productTitle, 12);
      addKeyword(_typeRecommendationLabel(conversation.productType), 10);
    }

    for (final product in featuredProducts) {
      addKeyword(product.category, 6);
      addKeyword(product.title, 5);
      addKeyword(product.author, 4);
    }

    for (final product in recentProducts) {
      addKeyword(product.category, 4);
      addKeyword(product.author, 3);
      addKeyword(_typeRecommendationLabel(product.type), 3);
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.length.compareTo(b.key.length);
      });

    return sorted.take(limit).map((entry) => entry.key).toList();
  }

  Future<List<Product>> getRecommendedProducts({int limit = 6}) async {
    final currentUserId = _auth.currentUser?.uid;
    final allProducts = await getAllProducts();
    if (allProducts.isEmpty) return const [];

    final profile = await getCurrentUserProfile();
    final favoriteProducts = await getFavoriteProducts();
    final purchaseHistory = await getPurchaseHistory();
    final conversations = await _getCurrentUserConversationsForRecommendation();

    final favoriteIds = favoriteProducts.map((item) => item.id).toSet();
    final favoriteCategories = favoriteProducts
        .map((item) => _normalizeRecommendationText(item.category))
        .whereType<String>()
        .toSet();
    final favoriteAuthors = favoriteProducts
        .map((item) => _normalizeRecommendationText(item.author))
        .whereType<String>()
        .toSet();
    final purchasedTitles = purchaseHistory
        .map((item) => _normalizeRecommendationText(item.productTitle))
        .whereType<String>()
        .toSet();
    final purchasedUniversities = purchaseHistory
        .map((item) => _normalizeRecommendationText(item.productUniversity))
        .whereType<String>()
        .toSet();
    final purchasedTypes = purchaseHistory
        .map((item) => _normalizeRecommendationText(item.productType))
        .whereType<String>()
        .toSet();
    final chattedTitles = conversations
        .map((item) => _normalizeRecommendationText(item.productTitle))
        .whereType<String>()
        .toSet();
    final chattedTypes = conversations
        .map((item) => _normalizeRecommendationText(item.productType))
        .whereType<String>()
        .toSet();
    final profileUniversity = _normalizeRecommendationText(profile?.university);

    final candidates = allProducts.where((product) {
      if (currentUserId == null) return true;
      return product.sellerUid != currentUserId;
    }).toList();

    candidates.sort((a, b) {
      final scoreA = _recommendationScoreForProduct(
        a,
        favoriteIds: favoriteIds,
        favoriteCategories: favoriteCategories,
        favoriteAuthors: favoriteAuthors,
        purchasedTitles: purchasedTitles,
        purchasedUniversities: purchasedUniversities,
        purchasedTypes: purchasedTypes,
        chattedTitles: chattedTitles,
        chattedTypes: chattedTypes,
        profileUniversity: profileUniversity,
      );
      final scoreB = _recommendationScoreForProduct(
        b,
        favoriteIds: favoriteIds,
        favoriteCategories: favoriteCategories,
        favoriteAuthors: favoriteAuthors,
        purchasedTitles: purchasedTitles,
        purchasedUniversities: purchasedUniversities,
        purchasedTypes: purchasedTypes,
        chattedTitles: chattedTitles,
        chattedTypes: chattedTypes,
        profileUniversity: profileUniversity,
      );
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return candidates.take(limit).toList();
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
      final records = snapshot.docs
          .map((doc) => PurchaseRecord.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
      records.sort((a, b) {
        final aWeight = _attentionWeight(a.status);
        final bWeight = _attentionWeight(b.status);
        if (aWeight != bWeight) {
          return bWeight.compareTo(aWeight);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return records;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<List<PurchaseRecord>> getAllOrders({List<String>? statuses}) async {
    try {
      final snapshot = await _orders.get();
      var records = snapshot.docs
          .map((doc) => PurchaseRecord.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
      if (statuses != null && statuses.isNotEmpty) {
        records = records
            .where((order) => statuses.contains(order.status))
            .toList();
      }
      records.sort((a, b) {
        final aWeight = _attentionWeight(a.status);
        final bWeight = _attentionWeight(b.status);
        if (aWeight != bWeight) {
          return bWeight.compareTo(aWeight);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return records;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<PurchaseRecord?> getOrderById(String orderId) async {
    try {
      final snapshot = await _orders.doc(orderId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return PurchaseRecord.fromMap({'id': snapshot.id, ...snapshot.data()!});
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
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
    final profile = await ensureUserProfile(user);
    final currentProducts = await _loadProductsForCheckout(items);
    _ensureProductsInStock(items, currentProducts);

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    final orderIds = <String>[];

    for (final item in items) {
      final orderRef = _orders.doc();
      orderIds.add(orderRef.id);
      final sellerPayoutAmount = item.totalPrice * AdminConfig.sellerPayoutRate;
      final platformFeeAmount = item.totalPrice - sellerPayoutAmount;
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
        'transferNote':
            transferNotesBySeller?[item.product.sellerUid ?? ''] ?? '',
        'recipientName': profile.name,
        'recipientPhone': profile.phone,
        'shippingAddress': profile.shippingAddress,
        'shippingLatitude': profile.shippingLatitude,
        'shippingLongitude': profile.shippingLongitude,
        'sellerPayoutAmount': sellerPayoutAmount,
        'platformFeeAmount': platformFeeAmount,
        'payoutReleased': false,
        'payoutMessage': '',
        'createdAt': now,
      });
    }
    _queueStockUpdates(batch, items, currentProducts);

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      return const [];
    }
    return orderIds;
  }

  Future<List<String>> createWalletPaidOrdersFromCart(
    List<CartItem> items,
  ) async {
    final user = _auth.currentUser;
    if (user == null || items.isEmpty) return const [];

    final profile = await ensureUserProfile(user);
    final currentProducts = await _loadProductsForCheckout(items);
    _ensureProductsInStock(items, currentProducts);
    final totalAmount = items.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
    if (profile.walletBalance < totalAmount) {
      throw StateError('insufficient_wallet_balance');
    }

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    final orderIds = <String>[];

    for (final item in items) {
      final orderRef = _orders.doc();
      orderIds.add(orderRef.id);
      final sellerPayoutAmount = item.totalPrice * AdminConfig.sellerPayoutRate;
      final platformFeeAmount = item.totalPrice - sellerPayoutAmount;
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
        'status': 'awaiting_shipment',
        'paymentMethod': 'wallet',
        'transferNote':
            'WALLET-${user.uid.substring(0, user.uid.length < 6 ? user.uid.length : 6).toUpperCase()}',
        'recipientName': profile.name,
        'recipientPhone': profile.phone,
        'shippingAddress': profile.shippingAddress,
        'shippingLatitude': profile.shippingLatitude,
        'shippingLongitude': profile.shippingLongitude,
        'sellerPayoutAmount': sellerPayoutAmount,
        'platformFeeAmount': platformFeeAmount,
        'payoutReleased': false,
        'payoutMessage': '',
        'createdAt': now,
      });
    }
    _queueStockUpdates(batch, items, currentProducts);

    batch.set(_users.doc(user.uid), {
      'walletBalance': profile.walletBalance - totalAmount,
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      return const [];
    }

    return orderIds;
  }

  Future<Map<String, Product>> _loadProductsForCheckout(
    List<CartItem> items,
  ) async {
    final products = <String, Product>{};
    for (final item in items) {
      final productId = item.product.id;
      if (products.containsKey(productId)) continue;

      final snapshot = await _products.doc(productId).get();
      final freshProduct = snapshot.exists && snapshot.data() != null
          ? _productFromSnapshot(snapshot)
          : item.product;
      products[productId] = freshProduct;
    }
    return products;
  }

  void _ensureProductsInStock(
    List<CartItem> items,
    Map<String, Product> currentProducts,
  ) {
    final requestedQuantities = <String, int>{};
    for (final item in items) {
      requestedQuantities.update(
        item.product.id,
        (current) => current + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    for (final entry in requestedQuantities.entries) {
      final product = currentProducts[entry.key];
      final requestedQuantity = entry.value;
      final availableQuantity = product?.stockQuantity ?? 0;
      if (product == null ||
          availableQuantity <= 0 ||
          requestedQuantity > availableQuantity) {
        throw StateError('out_of_stock');
      }
    }
  }

  void _queueStockUpdates(
    WriteBatch batch,
    List<CartItem> items,
    Map<String, Product> currentProducts,
  ) {
    final requestedQuantities = <String, int>{};
    for (final item in items) {
      requestedQuantities.update(
        item.product.id,
        (current) => current + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    for (final entry in requestedQuantities.entries) {
      final product = currentProducts[entry.key];
      if (product == null) continue;
      final nextStock = product.stockQuantity - entry.value;
      batch.set(_products.doc(entry.key), {
        'stockQuantity': nextStock < 0 ? 0 : nextStock,
      }, SetOptions(merge: true));
    }
  }

  Future<bool> isFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _favorites
          .doc('${user.uid}_$productId')
          .get()
          .timeout(const Duration(seconds: 4));
      return doc.exists;
    } on TimeoutException {
      return false;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return false;
      rethrow;
    }
  }

  Future<FavoriteToggleResult> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return FavoriteToggleResult.unauthenticated;

    try {
      final docRef = _favorites.doc('${user.uid}_${product.id}');
      final snapshot = await docRef.get().timeout(const Duration(seconds: 4));

      if (snapshot.exists) {
        await docRef.delete().timeout(const Duration(seconds: 4));
        return FavoriteToggleResult.success;
      }

      await docRef
          .set({
            'userUid': user.uid,
            'productId': product.id,
            'createdAt': DateTime.now().toIso8601String(),
            'product': product.toFirestore(),
          })
          .timeout(const Duration(seconds: 4));
      return FavoriteToggleResult.success;
    } on TimeoutException {
      return FavoriteToggleResult.timeout;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return FavoriteToggleResult.permissionDenied;
      }
      if (error.code == 'unavailable' ||
          error.code == 'network-request-failed') {
        return FavoriteToggleResult.networkError;
      }
      rethrow;
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
          (a, b) => (b.data()['createdAt'] ?? '').toString().compareTo(
            (a.data()['createdAt'] ?? '').toString(),
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

  Future<void> adminDeleteProduct(String productId) async {
    try {
      await _products.doc(productId).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> adminSetUserBanStatus(String userId, bool isBanned) async {
    try {
      await _users.doc(userId).set({
        'isBanned': isBanned,
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> adminDeleteUser(String userId) async {
    try {
      final batch = _firestore.batch();
      final userSnapshot = await _users.doc(userId).get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};

      final userProducts = await _products
          .where('sellerUid', isEqualTo: userId)
          .get();
      for (final doc in userProducts.docs) {
        batch.delete(doc.reference);
      }

      final userFavorites = await _favorites
          .where('userUid', isEqualTo: userId)
          .get();
      for (final doc in userFavorites.docs) {
        batch.delete(doc.reference);
      }

      final userNotifications = await _notifications
          .where('userUid', isEqualTo: userId)
          .get();
      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      final userWalletRequests = await _walletRequests
          .where('userUid', isEqualTo: userId)
          .get();
      for (final doc in userWalletRequests.docs) {
        batch.delete(doc.reference);
      }

      batch.set(_users.doc(userId), {
        'name': userData['name'] ?? 'Tai khoan da bi xoa',
        'email': userData['email'] ?? '',
        'phone': '',
        'university': '',
        'avatarBase64': null,
        'walletBalance': 0,
        'totalPurchases': 0,
        'totalSales': 0,
        'isBanned': true,
        'deletedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> confirmAdminPayment(String orderId) async {
    await _updateOrderWithNotification(
      orderId: orderId,
      updates: {
        'status': 'awaiting_shipment',
        'adminConfirmedAt': DateTime.now().toIso8601String(),
      },
      notifyUserField: 'buyerUid',
      title: 'Admin da xac nhan thanh toan',
      body:
          'Don hang $orderId da duoc admin xac nhan da nhan tien vao tai khoan trung gian.',
      type: 'order_payment_confirmed',
    );
  }

  Future<bool> autoConfirmOrderPayment(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _orders.doc(orderId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return false;
    if ((data['status'] as String? ?? '') != 'pending_admin_confirmation') {
      return false;
    }

    final buyerUid = data['buyerUid'] as String? ?? '';
    if (buyerUid != user.uid && !AdminConfig.isAdminEmail(user.email)) {
      return false;
    }

    try {
      await _updateOrderWithNotification(
        orderId: orderId,
        updates: {
          'status': 'awaiting_shipment',
          'adminConfirmedAt': DateTime.now().toIso8601String(),
          'autoConfirmedAt': DateTime.now().toIso8601String(),
          'paymentAutoConfirmed': true,
        },
        notifyUserField: 'buyerUid',
        title: 'Thanh toan da duoc tu dong xac nhan',
        body:
            'He thong da ghi nhan thanh toan cho don $orderId. Don hang dang cho nguoi ban giao.',
        type: 'order_payment_confirmed',
      );

      final sellerUid = data['sellerUid'] as String? ?? '';
      if (sellerUid.trim().isNotEmpty) {
        await _createNotification(
          userUid: sellerUid,
          orderId: orderId,
          title: 'Co don hang da thanh toan',
          body:
              'Don $orderId da duoc he thong xac nhan thanh toan va dang cho giao hang.',
          type: 'order_payment_confirmed',
        );
      }
      return true;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return false;
      rethrow;
    }
  }

  Future<int> autoConfirmOrderPayments(List<String> orderIds) async {
    var confirmedCount = 0;
    for (final orderId in orderIds) {
      final confirmed = await autoConfirmOrderPayment(orderId);
      if (confirmed) confirmedCount++;
    }
    return confirmedCount;
  }

  Future<void> markOrderDelivered(String orderId) async {
    await _updateOrderWithNotification(
      orderId: orderId,
      updates: {
        'status': 'delivered_pending_release',
        'deliveredAt': DateTime.now().toIso8601String(),
      },
      notifyUserField: 'sellerUid',
      title: 'Don hang da duoc giao',
      body:
          'Don hang $orderId da duoc admin danh dau giao thanh cong. Buoc tiep theo la giai ngan 95% cho ban.',
      type: 'order_delivered',
    );
  }

  Future<void> releaseSellerPayout(String orderId) async {
    final snapshot = await _orders.doc(orderId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return;

    final payoutAmount = (data['sellerPayoutAmount'] as num?)?.toDouble() ?? 0;
    final sellerUid = data['sellerUid'] as String? ?? '';
    final sellerProfile = sellerUid.trim().isEmpty
        ? null
        : await getUserProfileById(sellerUid);
    final currentWallet = sellerProfile?.walletBalance ?? 0;
    final message =
        'Admin da cong ${payoutAmount.toStringAsFixed(0)}d vao vi EduShare cua ban, tuong ung 95% gia tri don hang $orderId.';

    try {
      final batch = _firestore.batch();
      batch.set(_orders.doc(orderId), {
        'status': 'completed',
        'payoutReleased': true,
        'payoutReleasedAt': DateTime.now().toIso8601String(),
        'payoutMessage': message,
      }, SetOptions(merge: true));
      if (sellerUid.trim().isNotEmpty) {
        batch.set(_users.doc(sellerUid), {
          'walletBalance': currentWallet + payoutAmount,
        }, SetOptions(merge: true));
      }
      await batch.commit();

      if (sellerUid.trim().isNotEmpty) {
        await _createNotification(
          userUid: sellerUid,
          orderId: orderId,
          title: 'Admin da giai ngan tien hang',
          body: message,
          type: 'seller_payout_released',
        );
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> approveWalletDeposit(String requestId) async {
    await _completeWalletDeposit(requestId, autoConfirmed: false);
  }

  Future<bool> autoConfirmWalletDepositFromBankTransaction(
    String requestId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _walletRequests.doc(requestId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return false;
    if ((data['userUid'] as String? ?? '') != user.uid &&
        !AdminConfig.isAdminEmail(user.email)) {
      return false;
    }

    final payosConfirmed = await _autoConfirmWalletDepositFromPayos(
      requestId,
      data,
    );
    if (payosConfirmed) return true;

    final transaction = await _findMatchingBankTransaction(data);
    if (transaction == null) return false;

    return _completeWalletDeposit(
      requestId,
      autoConfirmed: true,
      bankTransactionId: transaction.id,
    );
  }

  Future<bool> _autoConfirmWalletDepositFromPayos(
    String requestId,
    Map<String, dynamic> requestData,
  ) async {
    final payosId = (requestData['payosPaymentLinkId'] as String? ?? '').trim();
    final payosOrderCode = requestData['payosOrderCode'];
    final lookupId = payosId.isNotEmpty ? payosId : payosOrderCode?.toString();
    if (lookupId == null || lookupId.trim().isEmpty) return false;

    final payment = await PayosService.instance.getPaymentLink(lookupId);
    if (payment == null) return false;

    await _walletRequests.doc(requestId).set({
      'payosStatus': payment.status,
      'payosPaymentLinkId': payment.paymentLinkId,
      'payosCheckoutUrl': payment.checkoutUrl,
      'payosQrCode': payment.qrCode,
      'payosLastCheckedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (!payment.isPaid) return false;
    return _completeWalletDeposit(
      requestId,
      autoConfirmed: true,
      payosPaymentLinkId: payment.paymentLinkId,
      payosOrderCode: payment.orderCode,
      payosStatus: payment.status,
    );
  }

  Future<bool> _completeWalletDeposit(
    String requestId, {
    required bool autoConfirmed,
    String? bankTransactionId,
    String? payosPaymentLinkId,
    int? payosOrderCode,
    String? payosStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    String userUid = '';
    double creditedAmount = 0;

    try {
      final completed = await _firestore.runTransaction<bool>((transaction) async {
        final requestDoc = _walletRequests.doc(requestId);
        final snapshot = await transaction.get(requestDoc);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return false;
        if ((data['status'] as String? ?? '') != 'pending') return false;
        if ((data['type'] as String? ?? '') != 'deposit') return false;

        userUid = data['userUid'] as String? ?? '';
        if (userUid.trim().isEmpty) return false;
        creditedAmount = (data['creditedAmount'] as num?)?.toDouble() ?? 0;
        if (creditedAmount <= 0) return false;

        transaction.set(requestDoc, {
          'status': 'completed',
          'completedAt': now,
          if (autoConfirmed) ...{
            'autoConfirmedAt': now,
            'paymentAutoConfirmed': true,
          },
          if (bankTransactionId != null) 'bankTransactionId': bankTransactionId,
          if (payosPaymentLinkId != null)
            'payosPaymentLinkId': payosPaymentLinkId,
          if (payosOrderCode != null) 'payosOrderCode': payosOrderCode,
          if (payosStatus != null) 'payosStatus': payosStatus,
        }, SetOptions(merge: true));
        transaction.set(_users.doc(userUid), {
          'walletBalance': FieldValue.increment(creditedAmount),
        }, SetOptions(merge: true));
        if (bankTransactionId != null) {
          transaction.set(_bankTransactions.doc(bankTransactionId), {
            'used': true,
            'matchedWalletRequestId': requestId,
            'matchedUserUid': userUid,
            'matchedAt': now,
          }, SetOptions(merge: true));
        }
        return true;
      });

      if (!completed) return false;

      await _createNotification(
        userUid: userUid,
        orderId: '',
        title: autoConfirmed
            ? 'Nap tien da duoc tu dong xac nhan'
            : 'Nap tien da duoc xac nhan',
        body:
            '${autoConfirmed ? 'He thong' : 'Admin'} da xac nhan nap tien. Vi EduShare cua ban duoc cong ${creditedAmount.toStringAsFixed(0)}d.',
        type: 'wallet_deposit_completed',
      );
      return true;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return false;
      rethrow;
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _findMatchingBankTransaction(Map<String, dynamic> requestData) async {
    final requestedAmount =
        (requestData['requestedAmount'] as num?)?.toDouble() ?? 0;
    final transferNote = (requestData['transferNote'] as String? ?? '')
        .trim()
        .toUpperCase();
    final payosPaymentLinkId =
        (requestData['payosPaymentLinkId'] as String? ?? '').trim();
    final payosOrderCode = requestData['payosOrderCode']?.toString() ?? '';
    if (requestedAmount <= 0 || transferNote.isEmpty) return null;

    try {
      final snapshot = await _bankTransactions
          .where('used', isEqualTo: false)
          .limit(80)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final content = _bankTransactionContent(data).toUpperCase();
        final sameAmount = amount.round() == requestedAmount.round();
        final samePayosLink =
            payosPaymentLinkId.isNotEmpty &&
            (data['paymentLinkId'] as String? ?? '') == payosPaymentLinkId;
        final samePayosOrder =
            payosOrderCode.isNotEmpty &&
            data['orderCode']?.toString() == payosOrderCode;
        if (sameAmount &&
            (content.contains(transferNote) ||
                samePayosLink ||
                samePayosOrder)) {
          return doc;
        }
      }
      return null;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  String _bankTransactionContent(Map<String, dynamic> data) {
    return [
      data['description'],
      data['content'],
      data['addInfo'],
      data['note'],
      data['transferNote'],
    ].whereType<String>().join(' ');
  }

  Future<void> cancelWalletRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _walletRequests.doc(requestId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return;

    final userUid = data['userUid'] as String? ?? '';
    final status = data['status'] as String? ?? '';
    final type = data['type'] as String? ?? '';

    if (userUid != user.uid || status != 'pending') return;

    try {
      if (type == 'withdrawal') {
        final profile = await ensureUserProfile(user);
        final amount = (data['requestedAmount'] as num?)?.toDouble() ?? 0;
        final batch = _firestore.batch();
        batch.set(_walletRequests.doc(requestId), {
          'status': 'cancelled',
          'completedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        batch.set(_users.doc(user.uid), {
          'walletBalance': profile.walletBalance + amount,
        }, SetOptions(merge: true));
        await batch.commit();
      } else {
        await _walletRequests.doc(requestId).set({
          'status': 'cancelled',
          'completedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> completeWalletWithdrawal(String requestId) async {
    final snapshot = await _walletRequests.doc(requestId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return;
    if ((data['status'] as String? ?? '') != 'pending') return;

    final userUid = data['userUid'] as String? ?? '';
    if (userUid.trim().isEmpty) return;
    final amount = (data['requestedAmount'] as num?)?.toDouble() ?? 0;

    try {
      await _walletRequests.doc(requestId).set({
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await _createNotification(
        userUid: userUid,
        orderId: '',
        title: 'Rut tien da hoan tat',
        body:
            'Admin da xu ly yeu cau rut ${amount.toStringAsFixed(0)}d tu vi EduShare cua ban.',
        type: 'wallet_withdrawal_completed',
      );
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  String buildConversationId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids.first}_${ids.last}';
  }

  Future<String?> ensureConversation({
    required String sellerUid,
    required String sellerName,
    required String productId,
    required String productTitle,
    required String productType,
    String? productImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || sellerUid.trim().isEmpty) {
      return null;
    }
    if (currentUser.uid == sellerUid) return null;

    final buyerProfile = await ensureUserProfile(currentUser);
    final sellerProfile = await getUserProfileById(sellerUid);
    final conversationId = buildConversationId(currentUser.uid, sellerUid);
    final now = DateTime.now();
    final conversationRef = _conversations.doc(conversationId);

    try {
      DateTime createdAt = now;
      String lastMessage = '';
      String lastSenderUid = '';

      try {
        final snapshot = await conversationRef.get();
        if (snapshot.exists) {
          createdAt =
              DateTime.tryParse(
                (snapshot.data()?['createdAt'] ?? now.toIso8601String())
                    .toString(),
              ) ??
              now;
          lastMessage = snapshot.data()?['lastMessage'] as String? ?? '';
          lastSenderUid = snapshot.data()?['lastSenderUid'] as String? ?? '';
        }
      } on FirebaseException catch (error) {
        // Lần đầu khởi tạo conversation, rules hiện tại có thể chặn get()
        // trên document chưa tồn tại. Khi đó mình vẫn tiếp tục set() vì create
        // mới là thao tác được cho phép.
        if (error.code != 'permission-denied') rethrow;
      }

      final conversation = ChatConversation(
        id: conversationId,
        participantIds: [currentUser.uid, sellerUid],
        participantNames: {
          currentUser.uid: buyerProfile.name,
          sellerUid: sellerProfile?.name ?? sellerName,
        },
        buyerUid: currentUser.uid,
        sellerUid: sellerUid,
        productId: productId,
        productTitle: productTitle,
        productType: productType,
        productImageUrl: productImageUrl,
        lastMessage: lastMessage,
        lastSenderUid: lastSenderUid,
        createdAt: createdAt,
        updatedAt: now,
      );

      await conversationRef.set(
        conversation.toFirestore(),
        SetOptions(merge: true),
      );
      return conversationId;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<String?> ensureConversationForProduct({
    required Product product,
  }) async {
    return ensureConversation(
      sellerUid: product.sellerUid ?? '',
      sellerName: product.author,
      productId: product.id,
      productTitle: product.title,
      productType: product.type,
      productImageUrl: product.imageUrl,
    );
  }

  Future<String?> ensureAdminConversation({
    String topic = 'Ho tro EduShare',
  }) async {
    final admin = await getPrimaryAdminProfile();
    if (admin == null) return null;

    return ensureConversation(
      sellerUid: admin.id,
      sellerName: admin.name,
      productId: 'support_admin',
      productTitle: topic,
      productType: 'dung_cu',
      productImageUrl: null,
    );
  }

  Stream<List<ChatConversation>> watchConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(const []);
    }

    return _conversations
        .where('participantIds', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map(
                (doc) =>
                    ChatConversation.fromMap({'id': doc.id, ...doc.data()}),
              )
              .toList();
          conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return conversations;
        });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromMap({'id': doc.id, ...doc.data()}))
              .toList();
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  Future<void> sendChatMessage({
    required String conversationId,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    final senderProfile = await ensureUserProfile(currentUser);
    final messageRef = _conversations
        .doc(conversationId)
        .collection('messages')
        .doc();
    final now = DateTime.now();
    final message = ChatMessage(
      id: messageRef.id,
      conversationId: conversationId,
      senderUid: currentUser.uid,
      senderName: senderProfile.name,
      text: normalizedText,
      createdAt: now,
    );

    try {
      final conversationSnapshot = await _conversations
          .doc(conversationId)
          .get();
      final conversationData =
          conversationSnapshot.data() ?? const <String, dynamic>{};
      await messageRef.set(message.toFirestore());
      await _conversations.doc(conversationId).set({
        'lastMessage': normalizedText,
        'lastSenderUid': currentUser.uid,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      final participantIds =
          (conversationData['participantIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList();
      final partnerUid = participantIds.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => '',
      );
      if (partnerUid.isNotEmpty) {
        await _createNotification(
          userUid: partnerUid,
          orderId: '',
          title: 'Tin nhan moi tu ${senderProfile.name}',
          body: normalizedText,
          type: 'chat_message',
        );
      }

      final productId = conversationData['productId'] as String? ?? '';
      final senderIsAdmin =
          senderProfile.isAdmin ||
          AdminConfig.isAdminEmail(currentUser.email?.trim().toLowerCase());
      if (productId == 'support_admin' &&
          !senderIsAdmin &&
          partnerUid.isNotEmpty) {
        await _sendAutomaticSupportReply(
          conversationId: conversationId,
          adminUid: partnerUid,
        );
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Stream<List<AppNotification>> watchNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(const []);
    }

    return _notifications
        .where('userUid', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .where((doc) => doc.data()['isDeleted'] != true)
              .map(
                (doc) => AppNotification.fromMap({'id': doc.id, ...doc.data()}),
              )
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).set({
        'isRead': true,
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> markAllNotificationsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final unreadNotifications = await _notifications
          .where('userUid', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (unreadNotifications.docs.isEmpty) return;

      var batch = _firestore.batch();
      var operationCount = 0;
      for (final doc in unreadNotifications.docs) {
        batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
        operationCount++;
        if (operationCount == 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }
      if (operationCount > 0) {
        await batch.commit();
      }
    } on FirebaseException {
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final userNotifications = await _notifications
          .where('userUid', isEqualTo: currentUser.uid)
          .get();
      if (userNotifications.docs.isEmpty) return;

      var batch = _firestore.batch();
      var operationCount = 0;
      for (final doc in userNotifications.docs) {
        batch.set(doc.reference, {
          'isDeleted': true,
          'deletedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        operationCount++;
        if (operationCount == 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }
      if (operationCount > 0) {
        await batch.commit();
      }
    } on FirebaseException {
      rethrow;
    }
  }

  Product _productFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap({'id': doc.id, ...doc.data()});
  }

  Product _productFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap({'id': doc.id, ...?doc.data()});
  }

  int _attentionWeight(String status) {
    return switch (status) {
      'pending_admin_confirmation' => 5,
      'awaiting_shipment' => 4,
      'delivered_pending_release' => 3,
      'pending_payment' => 2,
      'pending_cod' => 1,
      _ => 0,
    };
  }

  Future<void> _updateOrderWithNotification({
    required String orderId,
    required Map<String, dynamic> updates,
    required String notifyUserField,
    required String title,
    required String body,
    required String type,
  }) async {
    final snapshot = await _orders.doc(orderId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return;

    try {
      await _orders.doc(orderId).set(updates, SetOptions(merge: true));
      final userUid = data[notifyUserField] as String? ?? '';
      if (userUid.trim().isEmpty) return;
      await _createNotification(
        userUid: userUid,
        orderId: orderId,
        title: title,
        body: body,
        type: type,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> _createNotification({
    required String userUid,
    required String orderId,
    required String title,
    required String body,
    required String type,
  }) async {
    if (userUid.trim().isEmpty) return;

    try {
      final notificationRef = _notifications.doc();
      await notificationRef.set({
        'userUid': userUid,
        'orderId': orderId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> _sendAutomaticSupportReply({
    required String conversationId,
    required String adminUid,
  }) async {
    final messagesRef = _conversations
        .doc(conversationId)
        .collection('messages');
    final recentSnapshot = await messagesRef
        .orderBy('createdAt', descending: true)
        .limit(25)
        .get();

    final docs = recentSnapshot.docs;
    final latestText = docs.isEmpty
        ? ''
        : (docs.first.data()['text'] as String? ?? '').trim();
    if (latestText == _lastSupportBotText) return;

    final now = DateTime.now().add(const Duration(milliseconds: 250));
    final botReply = const SupportBotService().replyFor(latestText);
    final autoReplyRef = messagesRef.doc();
    final autoReply = ChatMessage(
      id: autoReplyRef.id,
      conversationId: conversationId,
      senderUid: adminUid,
      senderName: 'EduShare AI',
      text: botReply,
      createdAt: now,
    );

    await autoReplyRef.set(autoReply.toFirestore());
    await _conversations.doc(conversationId).set({
      'lastMessage': botReply,
      'lastSenderUid': adminUid,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));
  }

  static const String _lastSupportBotText =
      'Mình là EduShare AI, có thể hỗ trợ nhanh về đơn hàng, thanh toán, ví EduShare, giao hàng, bản đồ, thông báo, tài khoản và đăng bán sản phẩm. Bạn mô tả vấn đề cụ thể hơn để mình hướng dẫn đúng hơn nhé.';

  Future<void> _notifyAdmins({
    required String title,
    required String body,
    required String type,
  }) async {
    final adminIds = await _getAdminUserIds();
    for (final adminId in adminIds) {
      await _createNotification(
        userUid: adminId,
        orderId: '',
        title: title,
        body: body,
        type: type,
      );
    }
  }

  Future<List<String>> _getAdminUserIds() async {
    try {
      final snapshot = await _users.get();
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final email = (data['email'] as String?)?.trim().toLowerCase();
            final isAdmin =
                data['isAdmin'] as bool? ?? data['is_admin'] as bool? ?? false;
            return isAdmin || AdminConfig.isAdminEmail(email);
          })
          .map((doc) => doc.id)
          .toSet()
          .toList();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return [];
      rethrow;
    }
  }

  Future<List<ChatConversation>>
  _getCurrentUserConversationsForRecommendation() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const [];

    try {
      final snapshot = await _conversations
          .where('participantIds', arrayContains: currentUser.uid)
          .get();
      return snapshot.docs
          .map((doc) => ChatConversation.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return const [];
      rethrow;
    }
  }

  int _recommendationScoreForProduct(
    Product product, {
    required Set<String> favoriteIds,
    required Set<String> favoriteCategories,
    required Set<String> favoriteAuthors,
    required Set<String> purchasedTitles,
    required Set<String> purchasedUniversities,
    required Set<String> purchasedTypes,
    required Set<String> chattedTitles,
    required Set<String> chattedTypes,
    required String? profileUniversity,
  }) {
    var score = 0;
    final normalizedCategory = _normalizeRecommendationText(product.category);
    final normalizedAuthor = _normalizeRecommendationText(product.author);
    final normalizedTitle = _normalizeRecommendationText(product.title);
    final normalizedUniversity = _normalizeRecommendationText(
      product.university,
    );
    final normalizedType = _normalizeRecommendationText(product.type);

    if (favoriteIds.contains(product.id)) score += 100;
    if (normalizedCategory != null &&
        favoriteCategories.contains(normalizedCategory)) {
      score += 24;
    }
    if (normalizedAuthor != null &&
        favoriteAuthors.contains(normalizedAuthor)) {
      score += 14;
    }
    if (normalizedTitle != null && purchasedTitles.contains(normalizedTitle)) {
      score += 18;
    }
    if (normalizedUniversity != null &&
        purchasedUniversities.contains(normalizedUniversity)) {
      score += 18;
    }
    if (profileUniversity != null &&
        normalizedUniversity == profileUniversity) {
      score += 20;
    }
    if (normalizedType != null && purchasedTypes.contains(normalizedType)) {
      score += 14;
    }
    if (normalizedTitle != null && chattedTitles.contains(normalizedTitle)) {
      score += 12;
    }
    if (normalizedType != null && chattedTypes.contains(normalizedType)) {
      score += 10;
    }
    if (product.isFeatured) score += 8;
    if (product.isNew) score += 6;
    if (product.isFree) score += 3;
    return score;
  }

  String? _normalizeRecommendationText(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _typeRecommendationLabel(String? type) {
    return switch (_normalizeRecommendationText(type)) {
      'sach' => 'Sach giao trinh',
      'may_tinh' => 'May tinh hoc tap',
      've' => 'Do ve my thuat',
      'dung_cu' => 'Dung cu hoc tap',
      _ => type?.trim(),
    };
  }
}
