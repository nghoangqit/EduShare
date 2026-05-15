import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/purchase_record.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'chat_list_screen.dart';
import 'order_detail_screen.dart';

enum _NotificationAction { markAllRead, deleteAll }

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
        actions: [_notificationActions(context)],
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
          return _notificationList(context, notifications);
        },
      ),
    );
  }

  Widget _notificationList(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    final unreadCount = notifications.where((item) => !item.isRead).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _summaryPanel(
          context: context,
          totalCount: notifications.length,
          unreadCount: unreadCount,
        ),
        const SizedBox(height: 16),
        if (notifications.isEmpty)
          const _EmptyNotifications()
        else ...[
          Row(
            children: [
              const Text(
                'Gan day',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$unreadCount chua doc',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final notification in notifications) ...[
            _notificationCard(context, notification),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _summaryPanel({
    required BuildContext context,
    required int totalCount,
    required int unreadCount,
  }) {
    final hasNotifications = totalCount > 0;
    final hasUnread = unreadCount > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hop thu thong bao',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      totalCount == 0
                          ? 'Ban da xu ly het thong bao.'
                          : '$totalCount thong bao, $unreadCount chua doc',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryActionButton(
                icon: Icons.done_all_rounded,
                label: 'Da doc tat ca',
                enabled: hasUnread,
                onPressed: () => _markAllRead(context),
              ),
              _summaryActionButton(
                icon: Icons.delete_sweep_outlined,
                label: 'Xoa tat ca',
                enabled: hasNotifications,
                isDanger: true,
                onPressed: () => _deleteAll(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    final foreground = isDanger ? AppColors.red : AppColors.primary;

    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.18),
        foregroundColor: foreground,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
    );
  }

  Widget _notificationActions(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: _dataService.watchNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AppNotification>[];
        final hasNotifications = notifications.isNotEmpty;
        final hasUnread = notifications.any((item) => !item.isRead);

        return PopupMenuButton<_NotificationAction>(
          tooltip: 'Tuy chon thong bao',
          onSelected: (action) => _handleNotificationAction(context, action),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _NotificationAction.markAllRead,
              enabled: hasUnread,
              child: const Row(
                children: [
                  Icon(Icons.done_all_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Danh dau da doc tat ca'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _NotificationAction.deleteAll,
              enabled: hasNotifications,
              child: const Row(
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Xoa tat ca thong bao'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification item) {
    return InkWell(
      onTap: () => _openOrder(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: item.isRead
                                ? FontWeight.w700
                                : FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!item.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Moi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _typeLabel(item.type),
                      const Spacer(),
                      Text(
                        Formatter.joinDate(item.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textGray,
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

  Widget _typeLabel(String type) {
    final label = switch (type) {
      'seller_payout_released' => 'Vi tien',
      'order_delivered' => 'Van chuyen',
      'order_payment_confirmed' => 'Thanh toan',
      'chat_message' => 'Tin nhan',
      _ => 'He thong',
    };
    final color = switch (type) {
      'seller_payout_released' => AppColors.purple,
      'order_delivered' => AppColors.blue,
      'order_payment_confirmed' => AppColors.amber,
      'chat_message' => AppColors.primary,
      _ => AppColors.textGray,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _handleNotificationAction(
    BuildContext context,
    _NotificationAction action,
  ) async {
    switch (action) {
      case _NotificationAction.markAllRead:
        await _markAllRead(context);
      case _NotificationAction.deleteAll:
        await _deleteAll(context);
    }
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await _dataService.markAllNotificationsRead();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da danh dau tat ca thong bao la da doc.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong the cap nhat thong bao. Vui long thu lai.'),
        ),
      );
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoa tat ca thong bao?'),
        content: const Text(
          'Tat ca thong bao hien tai se bi xoa khoi hop thu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoa tat ca'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _dataService.deleteAllNotifications();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Da xoa tat ca thong bao.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong the xoa thong bao. Vui long thu lai.'),
        ),
      );
    }
  }

  Future<void> _openOrder(BuildContext context, AppNotification item) async {
    await _dataService.markNotificationRead(item.id);
    if (item.type == 'chat_message') {
      if (!context.mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ChatListScreen()));
      return;
    }
    if (item.orderId.trim().isEmpty) return;
    final PurchaseRecord? order = await _dataService.getOrderById(item.orderId);
    if (!context.mounted || order == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
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

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chua co thong bao nao',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cac cap nhat ve don hang, vi tien va tin nhan se xuat hien tai day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
