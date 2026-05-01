import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
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
          'Giỏ hàng (${cart.totalCount})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (_, cart, __) => cart.items.isEmpty
              ? const SizedBox()
              : TextButton(
                  onPressed: () => _confirmClearCart(context, cart),
                  child: const Text('Xóa tất cả', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 120, height: 120, child: Image.asset('assets/images/tool.png')),
          const SizedBox(height: 16),
          const Text('Giỏ hàng trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Thêm sản phẩm để bắt đầu mua sắm', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Khám phá sản phẩm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
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
              color: Colors.black.withOpacity(0.05),
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
                        item.product.isFree ? 'Miễn phí' : Formatter.price(item.product.price),
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
            color: Colors.black.withOpacity(0.08),
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
              Text('${cart.totalCount} sản phẩm', style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
              Text(
                hasFreeOnly ? 'Miễn phí' : Formatter.price(totalPrice),
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
                      hasFreeOnly ? 'Nhận hàng miễn phí' : 'Thanh toán • ${Formatter.price(totalPrice)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(CartProvider cart) async {
    setState(() => _processingOrder = true);
    await Future.delayed(const Duration(seconds: 2));
    await cart.clearCart();
    if (!mounted) return;
    setState(() => _processingOrder = false);
    _showOrderSuccess();
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
            const Text('Đặt hàng thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Người bán sẽ liên hệ bạn sớm.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tuyệt vời!'),
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
        title: const Text('Xóa giỏ hàng?'),
        content: const Text('Tất cả sản phẩm trong giỏ sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await cart.clearCart();
  }
}
