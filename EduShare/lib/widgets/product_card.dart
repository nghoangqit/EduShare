import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../screens/chat_screen.dart';
import 'glass_surface.dart';
import 'motion.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  bool _favoriteLoading = true;
  bool _favoriteUpdating = false;
  bool _isFavorite = false;
  bool _pressed = false;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    bool isFavorite = false;
    try {
      isFavorite = await _dataService
          .isFavorite(product.id)
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {
      isFavorite = false;
    }
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
      _favoriteLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteUpdating) return;
    final nextValue = !_isFavorite;
    setState(() {
      _favoriteUpdating = true;
      _isFavorite = nextValue;
    });

    FavoriteToggleResult result;
    try {
      result = await _dataService.toggleFavorite(product);
    } catch (_) {
      result = FavoriteToggleResult.networkError;
    }
    if (!mounted) return;

    if (result != FavoriteToggleResult.success) {
      setState(() {
        _favoriteUpdating = false;
        _isFavorite = !nextValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_favoriteErrorMessage(result)),
          backgroundColor: AppColors.red,
          duration: const Duration(milliseconds: 1300),
        ),
      );
      return;
    }

    setState(() => _favoriteUpdating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Da them vao yeu thich.' : 'Da xoa khoi yeu thich.',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  String _favoriteErrorMessage(FavoriteToggleResult result) {
    switch (result) {
      case FavoriteToggleResult.unauthenticated:
        return 'Ban can dang nhap de dung yeu thich.';
      case FavoriteToggleResult.permissionDenied:
        return 'Firebase dang chan quyen ghi yeu thich.';
      case FavoriteToggleResult.networkError:
        return 'Khong ket noi on dinh voi Firebase. Thu lai sau.';
      case FavoriteToggleResult.timeout:
        return 'Firebase phan hoi qua lau. Thu lai sau.';
      case FavoriteToggleResult.success:
        return 'Da cap nhat yeu thich.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetail(context),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppTheme.fastMotion,
        curve: AppTheme.motionCurve,
        child: AnimatedContainer(
          duration: AppTheme.fastMotion,
          curve: AppTheme.motionCurve,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.035 : 0.055),
                blurRadius: _pressed ? 10 : 18,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              Expanded(child: _buildInfo(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: SizedBox(
            height: 124,
            width: double.infinity,
            child: buildProductImage(
              type: product.type,
              imageUrl: product.imageUrl,
            ),
          ),
        ),
        if (product.discount > 0)
          _badge('-${product.discount}%', AppColors.red),
        if (product.isFree) _badge('Tang', AppColors.primary),
        if (product.isNew && product.discount == 0 && !product.isFree)
          _badge('Moi', AppColors.blue),
        if (product.isOutOfStock) _badge('Het hang', AppColors.red),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: (_favoriteLoading || _favoriteUpdating)
                ? null
                : _toggleFavorite,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: _favoriteLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textGray,
                      ),
                    )
                  : AnimatedScale(
                      scale: _favoriteUpdating ? 0.92 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: _isFavorite ? AppColors.red : AppColors.textGray,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor(product.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              typeLabel(product.type),
              style: TextStyle(
                fontSize: 10,
                color: categoryColor(product.type),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${product.condition} - ${product.author}',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 12,
                color: AppColors.textGray,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  product.university,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.isOutOfStock
                ? 'Hang da het, cho nguoi ban bo sung'
                : 'Con ${product.stockQuantity} san pham',
            style: TextStyle(
              fontSize: 10.5,
              color: product.isOutOfStock ? AppColors.red : AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (product.isFree)
            const Text(
              'Mien phi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatter.price(product.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (product.originalPrice != null)
                  Text(
                    Formatter.price(product.originalPrice!),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textGray,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          _buildAddToCartButton(context),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final inCart = cart.contains(product.id);
        return SizedBox(
          width: double.infinity,
          height: 36,
          child: AnimatedSwitcher(
            duration: AppTheme.fastMotion,
            child: ElevatedButton(
              key: ValueKey('${product.id}-$inCart-${product.isOutOfStock}'),
              onPressed: product.isOutOfStock
                  ? null
                  : () async {
                      final added = await cart.addItem(product);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? (inCart
                                        ? 'Da cap nhat gio hang.'
                                        : 'Da them vao gio hang.')
                                  : 'San pham da het hoac da dat toi da so luong ton.',
                            ),
                            backgroundColor: added
                                ? AppColors.primary
                                : AppColors.red,
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: product.isOutOfStock
                    ? const Color(0xFFE5E7EB)
                    : (inCart ? AppColors.primarySoft : AppColors.primary),
                foregroundColor: product.isOutOfStock
                    ? AppColors.textGray
                    : (inCart ? AppColors.primary : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                product.isOutOfStock
                    ? 'Het hang'
                    : (inCart ? 'Da co trong gio' : 'Them vao gio'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProductDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }
}

class _ProductDetailSheet extends StatelessWidget {
  final Product product;

  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canChat =
        product.sellerUid != null &&
        product.sellerUid!.trim().isNotEmpty &&
        product.sellerUid != currentUserId;

    return Reveal(
      child: GlassSurface(
        height: MediaQuery.of(context).size.height * 0.78,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        opacity: 0.90,
        blur: 18,
        borderColor: Colors.white.withValues(alpha: 0.64),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: buildProductImage(
                          type: product.type,
                          imageUrl: product.imageUrl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 15,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.author,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.school_outlined,
                          size: 15,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.university,
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? AppColors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        product.isOutOfStock
                            ? 'Tinh trang: Het hang'
                            : 'Tinh trang: ${product.condition}',
                        style: TextStyle(
                          color: product.isOutOfStock
                              ? AppColors.red
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.isOutOfStock
                          ? 'San pham tam het, khong the mua cho den khi nguoi ban bo sung them so luong.'
                          : 'Con lai ${product.stockQuantity} san pham co the dat mua.',
                      style: TextStyle(
                        color: product.isOutOfStock
                            ? AppColors.red
                            : AppColors.textGray,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (product.description != null &&
                        product.description!.trim().isNotEmpty) ...[
                      const Text(
                        'Mo ta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.isFree
                                    ? 'Mien phi'
                                    : Formatter.price(product.price),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (product.originalPrice != null)
                                Text(
                                  Formatter.price(product.originalPrice!),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGray,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: canChat ? 2 : 1,
                          child: Consumer<CartProvider>(
                            builder: (context, cart, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  if (canChat) ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final navigator = Navigator.of(
                                            context,
                                          );
                                          navigator.pop();
                                          navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                product: product,
                                                sellerUid: product.sellerUid!,
                                                sellerName: product.author,
                                                productId: product.id,
                                                productTitle: product.title,
                                                productType: product.type,
                                                productImageUrl:
                                                    product.imageUrl,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Chat'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: product.isOutOfStock
                                          ? null
                                          : () async {
                                              final added = await cart.addItem(
                                                product,
                                              );
                                              if (context.mounted && !added) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'San pham da het hoac da dat toi da so luong ton.',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.red,
                                                  ),
                                                );
                                                return;
                                              }
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                              }
                                            },
                                      icon: const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        product.isOutOfStock
                                            ? 'Het hang'
                                            : 'Them vao gio',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: product.isOutOfStock
                                            ? const Color(0xFFE5E7EB)
                                            : AppColors.primary,
                                        foregroundColor: product.isOutOfStock
                                            ? AppColors.textGray
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
