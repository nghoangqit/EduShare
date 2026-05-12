import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../screens/chat_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  bool _favoriteLoading = true;
  bool _isFavorite = false;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await _dataService.isFavorite(product.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFavorite;
      _favoriteLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    await _dataService.toggleFavorite(product);
    if (!mounted) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Da them vao yeu thich.' : 'Da xoa khoi yeu thich.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: SizedBox(
            height: 118,
            width: double.infinity,
            child: buildProductImage(
              type: product.type,
              imageUrl: product.imageUrl,
            ),
          ),
        ),
        if (product.discount > 0) _badge('-${product.discount}%', AppColors.red),
        if (product.isFree) _badge('Tang', AppColors.primary),
        if (product.isNew && product.discount == 0 && !product.isFree) _badge('Moi', AppColors.blue),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _favoriteLoading ? null : _toggleFavorite,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _favoriteLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textGray),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: _isFavorite ? AppColors.red : AppColors.textGray,
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${product.condition} • ${product.author}',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 12, color: AppColors.textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  product.university,
                  style: const TextStyle(fontSize: 10, color: AppColors.textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (product.isFree)
            const Text(
              'Mien phi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatter.price(product.price),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
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
          height: 34,
          child: ElevatedButton(
            onPressed: () async {
              await cart.addItem(product);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(inCart ? 'Da cap nhat gio hang.' : 'Da them vao gio hang.'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(milliseconds: 900),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: inCart ? AppColors.primaryLight : AppColors.primary,
              foregroundColor: inCart ? AppColors.primary : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              inCart ? 'Da co trong gio' : 'Them vao gio',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
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
    final canChat = product.sellerUid != null &&
        product.sellerUid!.trim().isNotEmpty &&
        product.sellerUid != currentUserId;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 15, color: AppColors.textGray),
                      const SizedBox(width: 6),
                      Text(product.author, style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.school_outlined, size: 15, color: AppColors.textGray),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.university,
                          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Tinh trang: ${product.condition}',
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (product.description != null && product.description!.trim().isNotEmpty) ...[
                    const Text(
                      'Mo ta',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: const TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.5),
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
                                      final navigator = Navigator.of(context);
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
                                            productImageUrl: product.imageUrl,
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
                                        borderRadius: BorderRadius.circular(12),
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
                                  onPressed: () async {
                                    await cart.addItem(product);
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Them vao gio'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
    );
  }
}
