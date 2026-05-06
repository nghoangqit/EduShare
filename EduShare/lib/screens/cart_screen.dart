import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onExploreProducts;

  const CartScreen({super.key, this.onExploreProducts});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  bool _processingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            if (cart.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return Column(
              children: [
                _buildHeader(context, cart),
                Expanded(
                  child: cart.items.isEmpty
                      ? _buildEmpty()
                      : _buildItemList(cart),
                ),
                if (cart.items.isNotEmpty) _buildCheckoutBar(cart),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B5D56), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gio hang (${cart.totalCount})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cart.items.isEmpty
                          ? 'San sang de them nhung mon do ban can'
                          : '${cart.items.length} dong san pham dang cho thanh toan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearCart(context, cart),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Xoa tat ca',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (cart.items.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _cartMetric(
                    icon: Icons.inventory_2_outlined,
                    label: 'So luong',
                    value: '${cart.totalCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _cartMetric(
                    icon: Icons.payments_outlined,
                    label: 'Tam tinh',
                    value: cart.totalPrice == 0
                        ? 'Mien phi'
                        : Formatter.price(cart.totalPrice),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cartMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withValues(alpha: 0.55),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2F4F0)),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_checkout_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Gio hang trong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Them san pham ban quan tam de bat dau mua sam va theo doi don hang de dang hon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _exploreProducts,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Kham pha san pham'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exploreProducts() {
    widget.onExploreProducts?.call();
  }

  Widget _buildItemList(CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      itemCount: cart.items.length,
      itemBuilder: (_, i) => _buildCartItem(cart.items[i], cart),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => cart.removeItem(item.product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 84,
                height: 84,
                child: Image.asset(
                  imageForProductType(item.product.type),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.product.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.product.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Don gia',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.product.isFree
                                ? 'Mien phi'
                                : Formatter.price(item.product.price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (!item.product.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              _qtyButton(
                                Icons.remove,
                                () => cart.updateQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              _qtyButton(
                                Icons.add,
                                () => cart.updateQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildCheckoutBar(CartProvider cart) {
    final hasFreeOnly = cart.items.every((i) => i.product.isFree);
    final totalPrice = cart.totalPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tong thanh toan',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cart.totalCount} san pham',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  hasFreeOnly ? 'Mien phi' : Formatter.price(totalPrice),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _processingOrder ? null : () => _checkout(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: _processingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      hasFreeOnly
                          ? 'Nhan hang mien phi'
                          : 'Thanh toan - ${Formatter.price(totalPrice)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(CartProvider cart) async {
    setState(() => _processingOrder = true);
    final payableItems = cart.items
        .where((item) => !item.product.isFree)
        .toList();
    if (payableItems.isEmpty) {
      await _completeOrder(
        cart,
        transferNotesBySeller: const {},
        status: 'paid',
        paymentMethod: 'free',
      );
      return;
    }

    final paymentMethod = await _showPaymentMethodSheet(cart);
    if (!mounted) return;
    if (paymentMethod == null) {
      setState(() => _processingOrder = false);
      return;
    }

    if (paymentMethod == 'cod') {
      await _completeOrder(
        cart,
        transferNotesBySeller: const {},
        status: 'pending_cod',
        paymentMethod: 'cod',
      );
      return;
    }

    final groups = await _buildSellerGroups(cart.items);
    if (!mounted) return;

    setState(() => _processingOrder = false);
    final approved = await _showTransferSheet(groups);
    if (!mounted) return;
    if (approved != true) return;
    await _createPendingOnlineOrders(cart, groups);
  }

  Future<void> _completeOrder(
    CartProvider cart, {
    required Map<String, String> transferNotesBySeller,
    required String status,
    required String paymentMethod,
  }) async {
    setState(() => _processingOrder = true);
    await _dataService.createOrdersFromCart(
      cart.items,
      transferNotesBySeller: transferNotesBySeller,
      status: status,
      paymentMethod: paymentMethod,
    );
    await cart.clearCart();
    if (!mounted) return;
    setState(() => _processingOrder = false);
    _showOrderSuccess();
  }

  Future<void> _createPendingOnlineOrders(
    CartProvider cart,
    List<_SellerPaymentGroup> groups,
  ) async {
    final transferNotesBySeller = {
      for (final group in groups) group.sellerUid: group.transferNote,
    };

    setState(() => _processingOrder = true);
    final orderIds = await _dataService.createOrdersFromCart(
      cart.items,
      transferNotesBySeller: transferNotesBySeller,
      status: 'pending_payment',
      paymentMethod: 'online',
    );
    await cart.clearCart();
    if (!mounted) return;
    setState(() => _processingOrder = false);

    final totalAmount = groups.fold<double>(
      0,
      (sum, group) => sum + group.totalAmount,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PendingPaymentScreen(
          groups: groups,
          orderCount: orderIds.length,
          totalAmount: totalAmount,
        ),
      ),
    );
  }

  Future<List<_SellerPaymentGroup>> _buildSellerGroups(
    List<CartItem> items,
  ) async {
    final grouped = <String, List<CartItem>>{};
    for (final item in items.where((entry) => !entry.product.isFree)) {
      final sellerUid = item.product.sellerUid ?? 'unknown';
      grouped.putIfAbsent(sellerUid, () => []).add(item);
    }

    final groups = <_SellerPaymentGroup>[];
    for (final entry in grouped.entries) {
      final sellerProfile = await _dataService.getUserProfileById(entry.key);
      final totalAmount = entry.value.fold<double>(
        0,
        (total, item) => total + item.totalPrice,
      );
      final transferNote = _buildTransferNote(entry.key);
      groups.add(
        _SellerPaymentGroup(
          sellerUid: entry.key,
          sellerName: sellerProfile?.name.trim().isNotEmpty == true
              ? sellerProfile!.name
              : entry.value.first.product.author,
          sellerProfile: sellerProfile,
          items: entry.value,
          totalAmount: totalAmount,
          transferNote: transferNote,
        ),
      );
    }
    return groups;
  }

  String _buildTransferNote(String sellerUid) {
    final buyerUid = context.read<AuthProvider>().currentUser?.uid ?? 'buyer';
    final sellerPart = sellerUid.length > 6
        ? sellerUid.substring(0, 6)
        : sellerUid;
    final buyerPart = buyerUid.length > 6 ? buyerUid.substring(0, 6) : buyerUid;
    return 'EDUSHARE-$buyerPart-$sellerPart';
  }

  String _buildVietQrUrl(_SellerPaymentGroup group) {
    final profile = group.sellerProfile;
    if (profile == null || !profile.hasBankAccount) return '';

    final amount = group.totalAmount.round();
    final encodedInfo = Uri.encodeComponent(group.transferNote);
    final encodedName = Uri.encodeComponent(profile.bankAccountHolder);
    return 'https://img.vietqr.io/image/'
        '${profile.bankBin}-${profile.bankAccountNumber}-compact2.png'
        '?amount=$amount&addInfo=$encodedInfo&accountName=$encodedName';
  }

  Future<bool?> _showTransferSheet(
    List<_SellerPaymentGroup> groups,
  ) {
    final validGroups = groups
        .where((group) => group.sellerProfile?.hasBankAccount == true)
        .length;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, _) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.86,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      children: [
                        const Text(
                          'Thanh toan bang QR ngan hang',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          validGroups == groups.length
                              ? 'Moi nguoi ban co tai khoan ngan hang rieng. Ban co the quet QR tung nguoi ban, sau do tao don o trang thai cho xac nhan thanh toan.'
                              : 'Can nguoi ban cap nhat day du thong tin ngan hang truoc khi thanh toan.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...groups.map((group) {
                          final profile = group.sellerProfile;
                          final hasBank = profile?.hasBankAccount == true;
                          final bankProfile = hasBank ? profile! : null;
                          final qrUrl = hasBank ? _buildVietQrUrl(group) : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.sellerName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${group.items.length} san pham - ${Formatter.price(group.totalAmount)}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (!hasBank)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF5F5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'Nguoi ban chua cap nhat day du thong tin ngan hang. Ban chua the thanh toan online cho don nay.',
                                      style: TextStyle(
                                        color: AppColors.red,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  )
                                else ...[
                                  Center(
                                    child: Container(
                                      width: 250,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7FBFF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFB7D3F2),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.network(
                                              qrUrl,
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => Container(
                                                    width: 180,
                                                    height: 180,
                                                    color: Colors.white,
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                      Icons.qr_code_2_rounded,
                                                      size: 72,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'QR chuyen khoan',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Quet ma de chuyen khoan dung so tien va noi dung.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.textGray,
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _paymentInfoRow(
                                    'Ngan hang',
                                    bankProfile!.bankName,
                                  ),
                                  _paymentInfoRow(
                                    'Ma BIN',
                                    bankProfile.bankBin,
                                  ),
                                  _paymentInfoRow(
                                    'So tai khoan',
                                    bankProfile.bankAccountNumber,
                                    copyValue: bankProfile.bankAccountNumber,
                                  ),
                                  _paymentInfoRow(
                                    'Chu tai khoan',
                                    bankProfile.bankAccountHolder,
                                  ),
                                  _paymentInfoRow(
                                    'Noi dung CK',
                                    group.transferNote,
                                    copyValue: group.transferNote,
                                  ),
                                  _paymentInfoRow(
                                    'So tien',
                                    Formatter.price(group.totalAmount),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Text(
                                      'App hien tao don o trang thai cho xac nhan thanh toan. Khi backend doi soat giao dich duoc tich hop, he thong se tu dong doi sang da thanh toan sau khi nhan xac nhan hop le.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGray,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: validGroups == groups.length
                                ? () => Navigator.pop(sheetContext, true)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Tao don cho xac nhan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Dong'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showPaymentMethodSheet(CartProvider cart) {
    final totalPrice = cart.totalPrice;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Text(
                'Chon cach thanh toan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Don hang cua ban: ${Formatter.price(totalPrice)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 18),
              _paymentMethodTile(
                icon: Icons.local_shipping_outlined,
                title: 'Thanh toan khi nhan hang',
                subtitle: 'Xac nhan don truoc, thanh toan sau khi nhan hang.',
                accent: AppColors.blue,
                onTap: () => Navigator.pop(sheetContext, 'cod'),
              ),
              const SizedBox(height: 12),
              _paymentMethodTile(
                icon: Icons.qr_code_2_rounded,
                title: 'Thanh toan online',
                subtitle: 'Quet QR chuyen khoan ngan hang theo thong tin tung nguoi ban.',
                accent: AppColors.primary,
                onTap: () => Navigator.pop(sheetContext, 'online'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Dong'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _paymentInfoRow(String label, String value, {String? copyValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (copyValue != null)
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Da sao chep thong tin thanh toan.'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  void _showOrderSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SuccessCheckmark(),
            const SizedBox(height: 18),
            const Text(
              'Dat hang thanh cong!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thong tin thanh toan da duoc xac nhan va don hang cua ban da duoc ghi nhan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Tuyet voi!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCart(
    BuildContext context,
    CartProvider cart,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoa gio hang?'),
        content: const Text('Tat ca san pham trong gio se bi xoa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoa', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await cart.clearCart();
  }
}

class _SellerPaymentGroup {
  final String sellerUid;
  final String sellerName;
  final UserProfile? sellerProfile;
  final List<CartItem> items;
  final double totalAmount;
  final String transferNote;

  const _SellerPaymentGroup({
    required this.sellerUid,
    required this.sellerName,
    required this.sellerProfile,
    required this.items,
    required this.totalAmount,
    required this.transferNote,
  });
}

class _PendingPaymentScreen extends StatelessWidget {
  final List<_SellerPaymentGroup> groups;
  final int orderCount;
  final double totalAmount;

  const _PendingPaymentScreen({
    required this.groups,
    required this.orderCount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Cho xac nhan thanh toan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF7FF),
                    border: Border.all(color: const Color(0xFFB7D3F2)),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Don da duoc tao',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'He thong dang cho backend xac nhan giao dich chuyen khoan ngan hang. Don hang se chuyen sang da thanh toan sau khi giao dich hop le duoc ghi nhan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _pendingMetric(
                        label: 'So don',
                        value: '$orderCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pendingMetric(
                        label: 'Tong tien',
                        value: Formatter.price(totalAmount),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...groups.map(
            (group) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.sellerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (group.sellerProfile?.hasBankAccount == true) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://img.vietqr.io/image/'
                        '${group.sellerProfile!.bankBin}-${group.sellerProfile!.bankAccountNumber}-compact2.png'
                        '?amount=${group.totalAmount.round()}'
                        '&addInfo=${Uri.encodeComponent(group.transferNote)}'
                        '&accountName=${Uri.encodeComponent(group.sellerProfile!.bankAccountHolder)}',
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 170,
                          color: const Color(0xFFF7FBFF),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 72,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Ngan hang: ${group.sellerProfile?.bankName ?? ''}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'So tai khoan: ${group.sellerProfile?.bankAccountNumber ?? ''}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chu tai khoan: ${group.sellerProfile?.bankAccountHolder ?? ''}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Noi dung GD: ${group.transferNote}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'So tien: ${Formatter.price(group.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Da hieu',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCheckmark extends StatefulWidget {
  const _SuccessCheckmark();

  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<_SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE9F9F1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF16A34A),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
