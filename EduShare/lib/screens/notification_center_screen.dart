import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/purchase_record.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'chat_list_screen.dart';
import 'order_detail_screen.dart';

class NotificationCenterScreen extends StatelessWidget {
  NotificationCenterScreen({super.key});

  final FirebaseDataService _dataService = FirebaseDataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Thong bao'),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _dataService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Chua co thong bao nao.',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _notificationCard(
              context,
              notifications[index],
            ),
          );
        },
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification item) {
    return InkWell(
      onTap: () => _openOrder(context, item),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE2E8F0)
                : AppColors.primary.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.isRead
                    ? const Color(0xFFF1F5F9)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(item.type),
                color: item.isRead ? AppColors.textGray : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    Formatter.joinDate(item.createdAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOrder(BuildContext context, AppNotification item) async {
    await _dataService.markNotificationRead(item.id);
    if (item.type == 'chat_message') {
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatListScreen()),
      );
      return;
    }
    if (item.orderId.trim().isEmpty) return;
    final PurchaseRecord? order = await _dataService.getOrderById(item.orderId);
    if (!context.mounted || order == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'seller_payout_released' => Icons.account_balance_wallet_outlined,
      'order_delivered' => Icons.local_shipping_outlined,
      'order_payment_confirmed' => Icons.verified_outlined,
      'chat_message' => Icons.chat_bubble_outline_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }
}
