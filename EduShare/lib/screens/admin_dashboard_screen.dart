import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/user_profile.dart';
import '../models/wallet_request.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;

  bool _loading = true;
  bool _processing = false;
  List<UserProfile> _users = const [];
  List<Product> _products = const [];
  List<PurchaseRecord> _orders = const [];
  List<WalletRequest> _walletRequests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _dataService.getAllUsers(),
      _dataService.getAllProducts(),
      _dataService.getAllOrders(),
      _dataService.getAllWalletRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _users = results[0] as List<UserProfile>;
      _products = results[1] as List<Product>;
      _orders = results[2] as List<PurchaseRecord>;
      _walletRequests = results[3] as List<WalletRequest>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingConfirm = _orders
        .where((order) => order.status == 'pending_admin_confirmation')
        .toList();
    final awaitingShipment = _orders
        .where((order) => order.status == 'awaiting_shipment')
        .toList();
    final awaitingRelease = _orders
        .where((order) => order.status == 'delivered_pending_release')
        .toList();
    final pendingDeposits = _walletRequests
        .where(
          (request) => request.type == 'deposit' && request.status == 'pending',
        )
        .toList();
    final pendingWithdrawals = _walletRequests
        .where(
          (request) =>
              request.type == 'withdrawal' && request.status == 'pending',
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Admin dashboard'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _heroCard(
                    pendingDeposits.length,
                    pendingWithdrawals.length,
                    awaitingShipment.length,
                    awaitingRelease.length,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Tong quan'),
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          'Nguoi dung',
                          '${_users.length}',
                          Icons.people_alt_outlined,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricTile(
                          'San pham',
                          '${_products.length}',
                          Icons.inventory_2_outlined,
                          AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          'Nap tien',
                          '${pendingDeposits.length}',
                          Icons.south_west_rounded,
                          AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricTile(
                          'Rut tien',
                          '${pendingWithdrawals.length}',
                          Icons.north_east_rounded,
                          AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Yeu cau nap tien vao vi'),
                  if (pendingDeposits.isEmpty)
                    _emptyTile('Khong co yeu cau nap tien nao dang cho xu ly.')
                  else
                    ...pendingDeposits.map(
                      (request) => _walletRequestCard(
                        request,
                        actionLabel:
                            'Cong ${Formatter.price(request.creditedAmount)} vao vi',
                        actionColor: AppColors.primary,
                        onTap: () => _runAdminAction(
                          () => _dataService.approveWalletDeposit(request.id),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle('Yeu cau rut tien tu vi'),
                  if (pendingWithdrawals.isEmpty)
                    _emptyTile('Khong co yeu cau rut tien nao dang cho xu ly.')
                  else
                    ...pendingWithdrawals.map(
                      (request) => _walletRequestCard(
                        request,
                        actionLabel:
                            'Danh dau da chuyen ${Formatter.price(request.requestedAmount)}',
                        actionColor: AppColors.purple,
                        onTap: () => _runAdminAction(
                          () =>
                              _dataService.completeWalletWithdrawal(request.id),
                        ),
                        showQr: true,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle('Don cho giao hang'),
                  if (awaitingShipment.isEmpty)
                    _emptyTile('Khong co don nao dang cho giao.')
                  else
                    ...awaitingShipment.map(
                      (order) => _orderActionCard(
                        order,
                        actionLabel: 'Danh dau da giao',
                        actionColor: AppColors.blue,
                        onTap: () => _runAdminAction(
                          () => _dataService.markOrderDelivered(order.id),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle('Don cho giai ngan'),
                  if (awaitingRelease.isEmpty)
                    _emptyTile('Khong co don nao dang cho giai ngan.')
                  else
                    ...awaitingRelease.map(
                      (order) => _orderActionCard(
                        order,
                        actionLabel:
                            'Cong vao vi seller ${Formatter.price(order.sellerPayoutAmount)}',
                        actionColor: AppColors.purple,
                        onTap: () => _runAdminAction(
                          () => _dataService.releaseSellerPayout(order.id),
                        ),
                      ),
                    ),
                  if (pendingConfirm.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Don cu cho xac nhan thanh toan'),
                    ...pendingConfirm.map(
                      (order) => _orderActionCard(
                        order,
                        actionLabel: 'Xac nhan da nhan tien',
                        actionColor: AppColors.amber,
                        onTap: () => _runAdminAction(
                          () => _dataService.confirmAdminPayment(order.id),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle('Danh sach nguoi dung'),
                  ..._users.map(_userCard),
                  const SizedBox(height: 16),
                  _sectionTitle('San pham da dang'),
                  ..._products.take(12).map(_productCard),
                  if (_products.length > 12)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Dang hien 12/${_products.length} san pham',
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _heroCard(
    int pendingDeposits,
    int pendingWithdrawals,
    int awaitingShipment,
    int awaitingRelease,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF052F2B), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trung tam quan tri vi EduShare',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin duyet nap tien, xu ly rut tien va cong 95% doanh thu vao vi EduShare cua seller khi don da giao xong.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroBadge('Nap tien', '$pendingDeposits'),
              _heroBadge('Rut tien', '$pendingWithdrawals'),
              _heroBadge('Cho giao', '$awaitingShipment'),
              _heroBadge('Cho cong vi', '$awaitingRelease'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _orderActionCard(
    PurchaseRecord order, {
    required String actionLabel,
    required Color actionColor,
    required Future<void> Function() onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.productTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Don ${order.id} • ${order.productAuthor}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tong: ${Formatter.price(order.totalPrice)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Cong vi seller: ${Formatter.price(order.sellerPayoutAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (order.transferNote.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Noi dung CK: ${order.transferNote}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ],
          if (order.recipientPhone.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Nguoi nhan: ${order.recipientName} - ${order.recipientPhone}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ],
          if (order.shippingAddress.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Dia chi: ${order.shippingAddress}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.isAdmin
                ? AppColors.amber.withValues(alpha: 0.18)
                : AppColors.primaryLight,
            child: Icon(
              user.isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline,
              color: user.isAdmin ? AppColors.amber : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'So du vi: ${Formatter.price(user.walletBalance)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _processing || user.isAdmin
                          ? null
                          : () => _confirmUserBanToggle(user),
                      icon: Icon(
                        user.isBanned
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded,
                        size: 18,
                      ),
                      label: Text(user.isBanned ? 'Mo khoa' : 'Ban'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _processing || user.isAdmin
                          ? null
                          : () => _confirmDeleteUser(user),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Xoa user'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (user.isAdmin)
            const Text(
              'ADMIN',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            )
          else if (user.isBanned)
            const Text(
              'BANNED',
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _productCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${product.author} • ${product.category}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
          const SizedBox(height: 8),
          Text(
            product.isFree ? 'Mien phi' : Formatter.price(product.price),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _processing
                  ? null
                  : () => _confirmDeleteProduct(product),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Xoa san pham'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletRequestCard(
    WalletRequest request, {
    required String actionLabel,
    required Color actionColor,
    required Future<void> Function() onTap,
    bool showQr = false,
  }) {
    final qrUrl = showQr ? _buildWithdrawQrUrl(request) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                request.type == 'deposit' ? 'NAP' : 'RUT',
                style: TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.userEmail,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
          const SizedBox(height: 10),
          Text(
            'So tien: ${Formatter.price(request.requestedAmount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (request.type == 'deposit') ...[
            const SizedBox(height: 4),
            Text(
              'Tien vao vi: ${Formatter.price(request.creditedAmount)} (90%)',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
          if (request.transferNote.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Noi dung GD: ${request.transferNote}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ],
          if (showQr && qrUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        qrUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                size: 64,
                                color: AppColors.primary,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'QR hoan tien ve ${request.bankName} - ${request.bankAccountNumber}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  String _buildWithdrawQrUrl(WalletRequest request) {
    if (request.bankBin.trim().isEmpty ||
        request.bankAccountNumber.trim().isEmpty ||
        request.bankAccountHolder.trim().isEmpty) {
      return '';
    }

    return 'https://img.vietqr.io/image/'
        '${request.bankBin}-${request.bankAccountNumber}-compact2.png'
        '?amount=${request.requestedAmount.round()}'
        '&addInfo=${Uri.encodeComponent(request.transferNote)}'
        '&accountName=${Uri.encodeComponent(request.bankAccountHolder)}';
  }

  Widget _emptyTile(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textGray)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Future<void> _runAdminAction(
    Future<void> Function() action, {
    String successMessage = 'Da cap nhat trang thai don.',
  }) async {
    setState(() => _processing = true);
    await action();
    await _load();
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final confirmed = await _confirmAction(
      title: 'Xoa san pham?',
      message:
          'San pham "${product.title}" se bi xoa khoi he thong. Hanh dong nay khong the hoan tac.',
      confirmLabel: 'Xoa san pham',
    );
    if (!confirmed) return;
    await _runAdminAction(
      () => _dataService.adminDeleteProduct(product.id),
      successMessage: 'Da xoa san pham.',
    );
  }

  Future<void> _confirmUserBanToggle(UserProfile user) async {
    final banning = !user.isBanned;
    final confirmed = await _confirmAction(
      title: banning ? 'Ban nguoi dung?' : 'Mo khoa nguoi dung?',
      message: banning
          ? 'Tai khoan ${user.email} se bi khoa va khong the dang nhap cho den khi duoc mo khoa.'
          : 'Tai khoan ${user.email} se duoc mo khoa de dang nhap lai.',
      confirmLabel: banning ? 'Ban tai khoan' : 'Mo khoa',
    );
    if (!confirmed) return;
    await _runAdminAction(
      () => _dataService.adminSetUserBanStatus(user.id, banning),
      successMessage: banning
          ? 'Da khoa tai khoan nguoi dung.'
          : 'Da mo khoa tai khoan nguoi dung.',
    );
  }

  Future<void> _confirmDeleteUser(UserProfile user) async {
    final confirmed = await _confirmAction(
      title: 'Xoa nguoi dung?',
      message:
          'Se xoa ho so, san pham dang ban, yeu cau vi va thong bao cua ${user.email}. Tai khoan Firebase Auth van con ton tai neu chua xoa tu backend.',
      confirmLabel: 'Xoa user',
    );
    if (!confirmed) return;
    await _runAdminAction(
      () => _dataService.adminDeleteUser(user.id),
      successMessage: 'Da xoa du lieu nguoi dung.',
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
