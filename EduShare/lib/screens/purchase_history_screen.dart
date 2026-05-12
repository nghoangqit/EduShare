import 'package:flutter/material.dart';
import 'order_detail_screen.dart';
import '../models/purchase_record.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  PurchaseHistoryScreen({super.key});

  final FirebaseDataService _dataService = FirebaseDataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Lich su mua hang'),
      ),
      body: FutureBuilder<List<PurchaseRecord>>(
        future: _dataService.getPurchaseHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              title: 'Khong tai duoc lich su',
              subtitle: 'Vui long thu lai sau.',
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return _buildEmptyState(
              title: 'Chua co don mua nao',
              subtitle: 'Nhung san pham ban thanh toan se hien thi tai day.',
            );
          }

          final pendingOrders = orders
              .where(
                (order) =>
                    order.status == 'awaiting_shipment' ||
                    order.status == 'delivered_pending_release' ||
                    order.status == 'pending_admin_confirmation' ||
                    order.status == 'pending_cod',
              )
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingOrders > 0) ...[
                _pendingBanner(pendingOrders),
                const SizedBox(height: 12),
              ],
              ...List.generate(orders.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == orders.length - 1 ? 0 : 12,
                  ),
                  child: _buildOrderCard(context, orders[index]),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _pendingBanner(int pendingOrders) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF6D38B)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9B5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pendingOrders don dang trong quy trinh trung gian',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Don dang duoc xu ly boi admin. Sau khi giao xong, 95% gia tri don se duoc cong vao vi EduShare cua nguoi ban.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGray,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, PurchaseRecord order) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      typeLabel(order.productType),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(order),
                  const Spacer(),
                  Text(
                    Formatter.joinDate(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.productTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${order.productAuthor} • ${order.productUniversity}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metaTile(
                      icon: Icons.shopping_bag_outlined,
                      label: 'So luong',
                      value: '${order.quantity}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metaTile(
                      icon: Icons.payments_outlined,
                      label: _paymentMethodLabel(order.paymentMethod),
                      value: Formatter.price(order.totalPrice),
                    ),
                  ),
                ],
              ),
              if (order.transferNote.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Noi dung GD: ${order.transferNote}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Row(
                children: [
                  Spacer(),
                  Text(
                    'Xem chi tiet',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(PurchaseRecord order) {
    final color = switch (order.status) {
      'paid' => Colors.green,
      'completed' => Colors.green,
      'pending_cod' => AppColors.blue,
      'pending_admin_confirmation' => AppColors.amber,
      'awaiting_shipment' => AppColors.blue,
      'delivered_pending_release' => AppColors.purple,
      _ => AppColors.textGray,
    };

    final label = switch (order.status) {
      'paid' => 'Da thanh toan',
      'completed' => 'Hoan tat',
      'pending_cod' => 'COD',
      'pending_admin_confirmation' => 'Cho admin xac nhan',
      'awaiting_shipment' => 'Cho giao hang',
      'delivered_pending_release' => 'Cho cong vi',
      _ => order.status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _paymentMethodLabel(String paymentMethod) {
    return switch (paymentMethod) {
      'cod' => 'Thanh toan COD',
      'free' => 'Don mien phi',
      'admin_escrow' => 'Ky quy qua admin',
      'wallet' => 'Vi EduShare',
      'online' => 'Thanh toan QR ngan hang',
      _ => 'Thanh toan',
    };
  }

  Widget _metaTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            const Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.textGray,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
