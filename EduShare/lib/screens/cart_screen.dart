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

  const CartScreen({
    super.key,
    this.onExploreProducts,
  });

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
      appBar: _buildAppBar(context),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (cart.items.isEmpty) {
            return _buildEmpty();
          }
          return Column(
            children: [
              Expanded(child: _buildItemList(cart)),
              _buildCheckoutBar(cart),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Consumer<CartProvider>(
        builder: (_, cart, __) => Text(
          'Gio hang (${cart.totalCount})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (_, cart, __) => cart.items.isEmpty
              ? const SizedBox()
              : TextButton(
                  onPressed: () => _confirmClearCart(context, cart),
                  child: const Text('Xoa tat ca', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withValues(alpha: 0.45),
                  ),
                ),
                Container(
                  width: 78,
                  height: 78,
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
                Positioned(
                  top: 14,
                  right: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.amber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Gio hang trong',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Them san pham ban quan tam de bat dau mua sam va theo doi don hang de dang hon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 13.5, height: 1.45),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (_, i) => _buildCartItem(cart.items[i], cart),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => cart.removeItem(item.product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 74,
                height: 74,
                child: Image.asset(imageForProductType(item.product.type), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(item.product.author, style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.product.isFree ? 'Mien phi' : Formatter.price(item.product.price),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      if (!item.product.isFree)
                        Row(
                          children: [
                            _qtyButton(Icons.remove, () => cart.updateQuantity(item.product.id, item.quantity - 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                              ),
                            ),
                            _qtyButton(Icons.add, () => cart.updateQuantity(item.product.id, item.quantity + 1)),
                          ],
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildCheckoutBar(CartProvider cart) {
    final hasFreeOnly = cart.items.every((i) => i.product.isFree);
    final totalPrice = cart.totalPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cart.totalCount} san pham', style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
              Text(
                hasFreeOnly ? 'Mien phi' : Formatter.price(totalPrice),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _processingOrder ? null : () => _checkout(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _processingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      hasFreeOnly ? 'Nhan hang mien phi' : 'Thanh toan • ${Formatter.price(totalPrice)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(CartProvider cart) async {
    final payableItems = cart.items.where((item) => !item.product.isFree).toList();
    if (payableItems.isEmpty) {
      await _completeOrder(cart, transferNotesBySeller: const {});
      return;
    }

    final groups = await _buildSellerGroups(cart.items);
    if (!mounted) return;

    setState(() => _processingOrder = false);
    final transferNotesBySeller = await _showTransferSheet(groups);
    if (transferNotesBySeller == null) return;
    await _completeOrder(cart, transferNotesBySeller: transferNotesBySeller);
  }

  Future<void> _completeOrder(
    CartProvider cart, {
    required Map<String, String> transferNotesBySeller,
  }) async {
    setState(() => _processingOrder = true);
    await _dataService.createOrdersFromCart(
      cart.items,
      transferNotesBySeller: transferNotesBySeller,
    );
    await cart.clearCart();
    if (!mounted) return;
    setState(() => _processingOrder = false);
    _showOrderSuccess();
  }

  Future<List<_SellerPaymentGroup>> _buildSellerGroups(List<CartItem> items) async {
    final grouped = <String, List<CartItem>>{};
    for (final item in items.where((entry) => !entry.product.isFree)) {
      final sellerUid = item.product.sellerUid ?? 'unknown';
      grouped.putIfAbsent(sellerUid, () => []).add(item);
    }

    final groups = <_SellerPaymentGroup>[];
    for (final entry in grouped.entries) {
      final sellerProfile = await _dataService.getUserProfileById(entry.key);
      final totalAmount = entry.value.fold<double>(0, (sum, item) => sum + item.totalPrice);
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
    final sellerPart = sellerUid.length > 6 ? sellerUid.substring(0, 6) : sellerUid;
    final buyerPart = buyerUid.length > 6 ? buyerUid.substring(0, 6) : buyerUid;
    return 'EDUSHARE-$buyerPart-$sellerPart';
  }

  Future<Map<String, String>?> _showTransferSheet(List<_SellerPaymentGroup> groups) {
    final confirmed = {for (final group in groups) group.sellerUid: false};
    final validGroups = groups.where((group) => group.sellerProfile?.hasBankAccount == true).length;

    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allReady = groups.isNotEmpty &&
                groups.every((group) => group.sellerProfile?.hasBankAccount == true && confirmed[group.sellerUid] == true);

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
                          'Chuyen khoan va quet QR',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          validGroups == groups.length
                              ? 'Moi nguoi ban co mot QR rieng theo so tien ban can thanh toan. Sau khi chuyen xong, danh dau da thanh toan de hoan tat don.'
                              : 'Can nguoi ban cap nhat tai khoan ngan hang truoc khi thanh toan. Cac muc thieu thong tin se khong tao duoc QR.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.45),
                        ),
                        const SizedBox(height: 18),
                        ...groups.map((group) {
                          final profile = group.sellerProfile;
                          final hasBank = profile?.hasBankAccount == true;
                          final qrUrl = hasBank
                              ? 'https://img.vietqr.io/image/${profile!.bankBin}-${profile.bankAccountNumber}-compact2.png?amount=${group.totalAmount.toInt()}&addInfo=${Uri.encodeComponent(group.transferNote)}&accountName=${Uri.encodeComponent(profile.bankAccountHolder)}'
                              : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
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
                                      child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.sellerName,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${group.items.length} san pham • ${Formatter.price(group.totalAmount)}',
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
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
                                      'Nguoi ban chua cap nhat thong tin ngan hang. Ban chua the tao QR cho don nay.',
                                      style: TextStyle(color: AppColors.red, fontSize: 12.5, height: 1.35),
                                    ),
                                  )
                                else ...[
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        qrUrl!,
                                        width: 220,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Khong tai duoc QR',
                                              style: TextStyle(color: AppColors.textGray),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _paymentInfoRow('Ngan hang', '${profile.bankName} • BIN ${profile.bankBin}'),
                                  _paymentInfoRow('So tai khoan', profile.bankAccountNumber, copyValue: profile.bankAccountNumber),
                                  _paymentInfoRow('Chu tai khoan', profile.bankAccountHolder),
                                  _paymentInfoRow('Noi dung CK', group.transferNote, copyValue: group.transferNote),
                                  _paymentInfoRow('So tien', Formatter.price(group.totalAmount)),
                                  const SizedBox(height: 12),
                                  CheckboxListTile(
                                    value: confirmed[group.sellerUid] ?? false,
                                    onChanged: (value) => setSheetState(() {
                                      confirmed[group.sellerUid] = value ?? false;
                                    }),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: AppColors.primary,
                                    title: const Text(
                                      'Toi da chuyen khoan thanh cong',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: const Text(
                                      'Danh dau sau khi ban da thanh toan dung nguoi ban va dung so tien.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textGray),
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
                            onPressed: allReady
                                ? () {
                                    Navigator.pop(
                                      sheetContext,
                                      {
                                        for (final group in groups) group.sellerUid: group.transferNote,
                                      },
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Xac nhan da chuyen khoan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
              style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700, color: AppColors.textDark),
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
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 90, height: 90, child: Image.asset('assets/images/logo.png')),
            const SizedBox(height: 12),
            const Text(
              'Dat hang thanh cong!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thong tin thanh toan da duoc xac nhan va don hang cua ban da duoc ghi nhan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tuyet voi!'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context, CartProvider cart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoa gio hang?'),
        content: const Text('Tat ca san pham trong gio se bi xoa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
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
