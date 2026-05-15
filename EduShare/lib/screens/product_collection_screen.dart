import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';

class ProductCollectionScreen extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<List<Product>> Function() loader;

  const ProductCollectionScreen({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.loader,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: FutureBuilder<List<Product>>(
        future: loader(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              title: 'Khong tai duoc du lieu',
              subtitle: 'Vui long thu lai sau.',
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return _buildEmptyState(
              title: emptyTitle,
              subtitle: emptySubtitle,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.56,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (_, index) => ProductCard(product: products[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 72, color: AppColors.textGray),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
