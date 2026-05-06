import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/purchase_record.dart';
import '../models/user_profile.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class OrderDetailScreen extends StatelessWidget {
  final PurchaseRecord order;
  static final FirebaseDataService _dataService = FirebaseDataService.instance;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Chi tiet don hang'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusHero(),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'San pham',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child: (order.productImageUrl != null &&
                            order.productImageUrl!.trim().isNotEmpty)
                        ? Image.network(
                            order.productImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              imageForProductType(order.productType),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            imageForProductType(order.productType),
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
                          typeLabel(order.productType),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.productAuthor,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.productUniversity,
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
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Thanh toan',
            child: Column(
              children: [
                    _infoRow(
                      context,
                      'Ma don',
                      order.id,
                      copyValue: order.id,
                    ),
                _infoRow(context, 'Phuong thuc', _paymentMethodLabel(order.paymentMethod)),
                _infoRow(context, 'Trang thai', _statusLabel(order.status)),
                _infoRow(context, 'So luong', '${order.quantity}'),
                _infoRow(context, 'Don gia', Formatter.price(order.productPrice)),
                _infoRow(context, 'Tong tien', Formatter.price(order.totalPrice)),
                if (order.transferNote.trim().isNotEmpty)
                  _infoRow(
                    context,
                    'Noi dung GD',
                    order.transferNote,
                    copyValue: order.transferNote,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Nguoi ban',
            child: FutureBuilder<UserProfile?>(
              future: _dataService.getUserProfileById(order.sellerUid),
              builder: (context, snapshot) {
                final seller = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      color: AppColors.primary,
                      minHeight: 3,
                    ),
                  );
                }

                if (seller == null) {
                    return Column(
                      children: [
                      _infoRow(context, 'Ten hien thi', order.productAuthor),
                      _infoRow(context, 'Ma nguoi ban', order.sellerUid),
                    ],
                  );
                }

                return Column(
                  children: [
                    _infoRow(context, 'Ten hien thi', seller.name),
                    if (seller.phone.trim().isNotEmpty)
                      _infoRow(
                        context,
                        'So dien thoai',
                        seller.phone,
                        copyValue: seller.phone,
                      ),
                    if (seller.email.trim().isNotEmpty)
                      _infoRow(
                        context,
                        'Email',
                        seller.email,
                        copyValue: seller.email,
                      ),
                    if (seller.university.trim().isNotEmpty)
                      _infoRow(context, 'Truong', seller.university),
                    if (seller.hasBankAccount) ...[
                      _infoRow(
                        context,
                        'Ngan hang',
                        seller.bankName,
                      ),
                      _infoRow(context, 'Ma BIN', seller.bankBin),
                      _infoRow(
                        context,
                        'So tai khoan',
                        seller.bankAccountNumber,
                        copyValue: seller.bankAccountNumber,
                      ),
                      _infoRow(
                        context,
                        'Chu tai khoan',
                        seller.bankAccountHolder,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Tien trinh',
            child: Column(
              children: [
                _timelineTile(
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  title: 'Don da duoc tao',
                  subtitle: repairVietnamese(
                    'Vao ${Formatter.joinDate(order.createdAt)}',
                  ),
                ),
                _timelineTile(
                  icon: order.status == 'paid'
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  color: _statusColor(order.status),
                  title: _statusLabel(order.status),
                  subtitle: order.status == 'pending_payment'
                      ? 'Don dang cho backend xac nhan thanh toan chuyen khoan ngan hang.'
                      : order.status == 'pending_cod'
                          ? 'Don se duoc thanh toan khi nhan hang.'
                          : 'Giao dich da duoc ghi nhan thanh cong.',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHero() {
    final color = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _statusIcon(order.status),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(order.status),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _paymentMethodLabel(order.paymentMethod),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(order.status),
                            size: 13,
                            color: color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusShort(order.status),
                            style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
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
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              repairVietnamese(value),
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (copyValue != null)
            IconButton(
              onPressed: () => _copyValue(context, copyValue),
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

  void _copyValue(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Da sao chep thong tin.'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  Widget _timelineTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repairVietnamese(title),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  repairVietnamese(subtitle),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGray,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _paymentMethodLabel(String paymentMethod) {
    return switch (paymentMethod) {
      'cod' => 'Thanh toan khi nhan hang',
      'free' => 'Don mien phi',
      'online' => 'Thanh toan QR ngan hang',
      _ => 'Thanh toan',
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'paid' => 'Da thanh toan',
      'pending_cod' => 'Dang cho giao COD',
      'pending_payment' => 'Cho xac nhan thanh toan',
      _ => repairVietnamese(status),
    };
  }

  String _statusShort(String status) {
    return switch (status) {
      'paid' => 'PAID',
      'pending_cod' => 'COD',
      'pending_payment' => 'PENDING',
      _ => status.toUpperCase(),
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'paid' => Icons.check_circle_rounded,
      'pending_cod' => Icons.local_shipping_rounded,
      'pending_payment' => Icons.schedule_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'paid' => Colors.green,
      'pending_cod' => AppColors.blue,
      'pending_payment' => AppColors.amber,
      _ => AppColors.textGray,
    };
  }
}
