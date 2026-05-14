import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
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
                  const SizedBox(height: 6),
                  Text(
                    item.product.isOutOfStock
                        ? 'Hang da het, cho nguoi ban bo sung'
                        : 'Ton kho con ${item.product.stockQuantity}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: item.product.isOutOfStock
                          ? AppColors.red
                          : AppColors.textGray,
                      fontWeight: FontWeight.w600,
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
                                () async {
                                  await cart.updateQuantity(
                                    item.product.id,
                                    item.quantity - 1,
                                  );
                                },
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
                                () async {
                                  final updatedQuantity =
                                      await cart.updateQuantity(
                                        item.product.id,
                                        item.quantity + 1,
                                      );
                                  if (!context.mounted) return;
                                  if (updatedQuantity == item.quantity) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          item.product.isOutOfStock
                                              ? 'San pham da het hang.'
                                              : 'Ban chi co the mua toi da ${item.product.stockQuantity} san pham.',
                                        ),
                                        backgroundColor: AppColors.red,
                                      ),
                                    );
                                  }
                                },
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
    final hasUnavailableItems = cart.items.any(
      (item) => item.product.isOutOfStock || item.quantity > item.product.stockQuantity,
    );

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
              onPressed: (_processingOrder || hasUnavailableItems)
                  ? null
                  : () => _checkout(cart),
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
                      hasUnavailableItems
                          ? 'Co san pham da het hang'
                          : hasFreeOnly
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
    final blockedItems = cart.items.where(
      (item) => item.product.isOutOfStock || item.quantity > item.product.stockQuantity,
    );
    if (blockedItems.isNotEmpty) {
      final blockedTitles = blockedItems
          .map((item) => item.product.title)
          .toSet()
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Khong the thanh toan. San pham da het hoac khong du ton: $blockedTitles',
          ),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _processingOrder = true);
    final readyForDelivery = await _ensureShippingInfo();
    if (!mounted) return;
    if (!readyForDelivery) {
      setState(() => _processingOrder = false);
      return;
    }

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
    await _payWithWallet(cart);
  }

  Future<bool> _ensureShippingInfo() async {
    final profile = await _dataService.getCurrentUserProfile();
    if (profile == null) return false;

    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final addressCtrl = TextEditingController(text: profile.shippingAddress);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasEnoughInfo =
                nameCtrl.text.trim().isNotEmpty &&
                phoneCtrl.text.trim().isNotEmpty &&
                addressCtrl.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thong tin nhan hang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Xac nhan nguoi nhan, so dien thoai va dia chi de nguoi ban co the giao hang dung noi.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGray,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _shippingField(
                        label: 'Nguoi nhan',
                        controller: nameCtrl,
                        icon: Icons.person_outline_rounded,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _shippingField(
                        label: 'So dien thoai',
                        controller: phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _shippingField(
                        label: 'Dia chi nhan hang',
                        controller: addressCtrl,
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: !hasEnoughInfo
                              ? null
                              : () async {
                                  profile
                                    ..name = nameCtrl.text.trim()
                                    ..phone = phoneCtrl.text.trim()
                                    ..shippingAddress =
                                        addressCtrl.text.trim();
                                  await _dataService.updateUserProfile(profile);
                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Xac nhan thong tin'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();

    return result ?? false;
  }

  Widget _shippingField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: maxLines > 1 ? 3 : 1,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF7FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Future<void> _completeOrder(
    CartProvider cart, {
    required Map<String, String> transferNotesBySeller,
    required String status,
    required String paymentMethod,
  }) async {
    setState(() => _processingOrder = true);
    try {
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
    } on StateError {
      if (!mounted) return;
      setState(() => _processingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Khong the dat hang vi san pham da het hoac nguoi ban vua thay doi ton kho.',
          ),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _payWithWallet(CartProvider cart) async {
    final profile = await _dataService.getCurrentUserProfile();
    final balance = profile?.walletBalance ?? 0;
    final totalAmount = cart.items.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );

    if (balance < totalAmount) {
      if (!mounted) return;
      setState(() => _processingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'So du vi khong du. Hien co ${Formatter.price(balance)}, can ${Formatter.price(totalAmount)}.',
          ),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _processingOrder = true);
      await _dataService.createWalletPaidOrdersFromCart(cart.items);
      await cart.clearCart();
      if (!mounted) return;
      setState(() => _processingOrder = false);
      _showOrderSuccess();
    } on StateError {
      if (!mounted) return;
      setState(() => _processingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('So du vi hoac ton kho da thay doi. Vui long thu lai.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
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
                style: const TextStyle(fontSize: 13, color: AppColors.textGray),
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
                icon: Icons.account_balance_wallet_outlined,
                title: 'Thanh toan bang vi EduShare',
                subtitle:
                    'Su dung so du vi de thanh toan ngay. Nap 100k se duoc cong 90k vao vi.',
                accent: AppColors.primary,
                onTap: () => Navigator.pop(sheetContext, 'wallet'),
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
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
