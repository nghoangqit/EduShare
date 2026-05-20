import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../models/wallet_request.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'admin_dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'chat_screen.dart';
import 'product_collection_screen.dart';
import 'purchase_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _profile;
  int _purchaseCount = 0;
  int _sellingCount = 0;
  int _favoriteCount = 0;
  bool _loading = true;
  bool _pickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        _dataService.getCurrentUserProfile(),
        _dataService.getPurchaseCount(),
        _dataService.getSellingCount(),
        _dataService.getFavoriteCount(),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile?;
        _purchaseCount = results[1] as int;
        _sellingCount = results[2] as int;
        _favoriteCount = results[3] as int;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Ho so'),
        ),
        body: const Center(
          child: Text(
            'Khong tim thay ho so',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Ho so'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ChatListScreen()));
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            onPressed: _showEditProfile,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeroCard(profile),
            const SizedBox(height: 16),
            _buildQuickActions(profile),
            const SizedBox(height: 16),
            _walletCard(profile),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: 'Da mua',
                    value: '$_purchaseCount',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Dang ban',
                    value: '$_sellingCount',
                    icon: Icons.sell_outlined,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Yeu thich',
                    value: '$_favoriteCount',
                    icon: Icons.favorite_outline_rounded,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Thong tin tai khoan',
              subtitle: 'Ho so ca nhan va cach lien he voi ban.',
              child: Column(
                children: [
                  _infoRow('Ho va ten', profile.name),
                  _infoRow('Email', profile.email, copyValue: profile.email),
                  _infoRow(
                    'So du vi',
                    Formatter.price(profile.walletBalance),
                    copyValue: profile.walletBalance.toStringAsFixed(0),
                  ),
                  _infoRow(
                    'So dien thoai',
                    profile.phone.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.phone,
                    copyValue: profile.phone.trim().isEmpty
                        ? null
                        : profile.phone,
                  ),
                  _infoRow(
                    'Truong',
                    profile.university.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.university,
                  ),
                  _infoRow(
                    'Dia chi nhan hang',
                    profile.shippingAddress.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.shippingAddress,
                    copyValue: profile.shippingAddress.trim().isEmpty
                        ? null
                        : profile.shippingAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Tai khoan rut tien',
              subtitle:
                  'Thong tin ngan hang nay duoc admin dung de chuyen tien cho ban khi ban tao yeu cau rut tu vi EduShare.',
              child: Column(
                children: [
                  _bankHighlight(profile),
                  const SizedBox(height: 14),
                  _infoRow(
                    'Ngan hang',
                    profile.bankName.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.bankName,
                  ),
                  _infoRow(
                    'Ma BIN',
                    profile.bankBin.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.bankBin,
                  ),
                  _infoRow(
                    'So tai khoan',
                    profile.bankAccountNumber.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.bankAccountNumber,
                    copyValue: profile.bankAccountNumber.trim().isEmpty
                        ? null
                        : profile.bankAccountNumber,
                  ),
                  _infoRow(
                    'Chu tai khoan',
                    profile.bankAccountHolder.trim().isEmpty
                        ? 'Chua cap nhat'
                        : profile.bankAccountHolder,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showEditProfile,
                      icon: const Icon(Icons.account_balance_outlined),
                      label: Text(
                        profile.hasBankAccount
                            ? 'Chinh sua tai khoan rut tien'
                            : 'Them thong tin ngan hang',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Bao mat',
              subtitle: 'Quan ly mat khau va phien dang nhap cua ban.',
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showChangePasswordSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Doi mat khau'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Dang xuat'),
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

  Widget _buildHeroCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF062E2B), Color(0xFF0D9488), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -38,
            left: -26,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Khong gian cua ban',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _statusChip(
                    label: profile.hasBankAccount
                        ? 'RUT SAN SANG'
                        : 'CAN CAP NHAT',
                    color: profile.hasBankAccount
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFFE6B5),
                    textColor: profile.hasBankAccount
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _buildAvatarImage(),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC9F7F0),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.university.trim().isEmpty
                              ? 'Chua cap nhat truong hoc'
                              : profile.university,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _heroMiniInfo(
                                icon: Icons.calendar_month_outlined,
                                label: 'Tham gia tu',
                                value: Formatter.joinDate(profile.joinDate),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _heroMiniInfo(
                                icon: Icons.phone_outlined,
                                label: 'Lien he',
                                value: profile.phone.trim().isEmpty
                                    ? 'Cap nhat'
                                    : profile.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(UserProfile profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _shortcutTile(
                icon: Icons.history_rounded,
                title: 'Lich su',
                subtitle: 'Don mua',
                color: AppColors.primary,
                onTap: _openPurchaseHistory,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shortcutTile(
                icon: Icons.storefront_outlined,
                title: 'Dang ban',
                subtitle: 'San pham',
                color: AppColors.blue,
                onTap: _openSellingProducts,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shortcutTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Da luu',
                subtitle: 'Yeu thich',
                color: AppColors.red,
                onTap: _openFavoriteProducts,
              ),
            ),
          ],
        ),
        if (!profile.isAdmin) ...[
          const SizedBox(height: 12),
          _shortcutTile(
            icon: Icons.support_agent_rounded,
            title: 'Chat admin',
            subtitle: 'Ho tro tai khoan, vi va don hang',
            color: AppColors.primaryDark,
            onTap: _openAdminSupportChat,
            expanded: false,
          ),
        ],
        if (profile.isAdmin) ...[
          const SizedBox(height: 12),
          _shortcutTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Quan tri',
            subtitle: 'User, san pham, vi va don hang',
            color: AppColors.amber,
            onTap: _openAdminDashboard,
            expanded: false,
          ),
        ],
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _walletCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vi EduShare',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nap 100k vao vi se duoc cong 90k de su dung trong he thong.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            Formatter.price(profile.walletBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'So du hien tai co the dung de thanh toan hoac tao yeu cau rut tien.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showWalletDepositSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Nap tien'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showWalletWithdrawSheet,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.north_east_rounded),
                  label: const Text('Rut tien'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textGray,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _shortcutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool expanded = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankHighlight(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: profile.hasBankAccount
              ? [const Color(0xFFE8FFF9), const Color(0xFFF5FFFC)]
              : [const Color(0xFFFFF8E7), const Color(0xFFFFFCF3)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profile.hasBankAccount
              ? const Color(0xFFBDEBDD)
              : const Color(0xFFF5D58B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: profile.hasBankAccount
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFFE7B3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              profile.hasBankAccount
                  ? Icons.qr_code_2_rounded
                  : Icons.info_outline_rounded,
              color: profile.hasBankAccount
                  ? const Color(0xFF047857)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.hasBankAccount
                      ? 'San sang nhan tien rut'
                      : 'Chua du thong tin rut tien',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.hasBankAccount
                      ? 'Admin se dung thong tin nay de chuyen tien khi ban gui yeu cau rut tu vi EduShare.'
                      : 'Cap nhat day du ngan hang, BIN, so tai khoan va ten chu tai khoan de co the rut tien.',
                  style: const TextStyle(
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

  Widget _heroMiniInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD9FFF8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {String? copyValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (copyValue != null)
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Da sao chep thong tin.'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
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

  void _showEditProfile() {
    if (_profile == null) return;

    final nameCtrl = TextEditingController(text: _profile!.name);
    final phoneCtrl = TextEditingController(text: _profile!.phone);
    final uniCtrl = TextEditingController(text: _profile!.university);
    final shippingAddressCtrl = TextEditingController(
      text: _profile!.shippingAddress,
    );
    final bankNameCtrl = TextEditingController(text: _profile!.bankName);
    final bankBinCtrl = TextEditingController(text: _profile!.bankBin);
    final bankNumberCtrl = TextEditingController(
      text: _profile!.bankAccountNumber,
    );
    final bankHolderCtrl = TextEditingController(
      text: _profile!.bankAccountHolder,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chinh sua ho so',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _editField('Ho va ten', nameCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _editField(
                  'So dien thoai',
                  phoneCtrl,
                  Icons.phone_outlined,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _editField('Truong dai hoc', uniCtrl, Icons.school_outlined),
                const SizedBox(height: 12),
                _editField(
                  'Dia chi nhan hang',
                  shippingAddressCtrl,
                  Icons.location_on_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tai khoan nhan rut tien',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhap day du ten ngan hang, ma BIN, so tai khoan va ten chu tai khoan de admin co the chuyen tien cho ban khi xu ly yeu cau rut tu vi EduShare.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _editField(
                  'Ten ngan hang',
                  bankNameCtrl,
                  Icons.account_balance_outlined,
                ),
                const SizedBox(height: 12),
                _editField(
                  'Ma BIN ngan hang',
                  bankBinCtrl,
                  Icons.numbers_outlined,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _editField(
                  'So tai khoan',
                  bankNumberCtrl,
                  Icons.credit_card_outlined,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _editField(
                  'Ten chu tai khoan',
                  bankHolderCtrl,
                  Icons.badge_outlined,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      _profile!
                        ..name = nameCtrl.text.trim()
                        ..phone = phoneCtrl.text.trim()
                        ..university = uniCtrl.text.trim()
                        ..shippingAddress = shippingAddressCtrl.text.trim()
                        ..bankName = bankNameCtrl.text.trim()
                        ..bankBin = bankBinCtrl.text.trim()
                        ..bankAccountNumber = bankNumberCtrl.text.trim()
                        ..bankAccountHolder = bankHolderCtrl.text.trim();

                      await _dataService.updateUserProfile(_profile!);
                      if (!mounted) return;
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Da cap nhat ho so.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Luu thay doi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final auth = context.watch<AuthProvider>();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Doi mat khau',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: auth.loading
                                ? null
                                : () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhap mat khau hien tai va dat mat khau moi cho tai khoan cua ban.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        label: 'Mat khau hien tai',
                        controller: currentPasswordCtrl,
                        obscureText: obscureCurrent,
                        onToggleVisibility: () => setSheetState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Vui long nhap mat khau hien tai.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        label: 'Mat khau moi',
                        controller: newPasswordCtrl,
                        obscureText: obscureNew,
                        onToggleVisibility: () =>
                            setSheetState(() => obscureNew = !obscureNew),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.trim().isEmpty) {
                            return 'Vui long nhap mat khau moi.';
                          }
                          if (password.length < 6) {
                            return 'Mat khau moi phai co it nhat 6 ky tu.';
                          }
                          if (password == currentPasswordCtrl.text) {
                            return 'Mat khau moi phai khac mat khau hien tai.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        label: 'Xac nhan mat khau moi',
                        controller: confirmPasswordCtrl,
                        obscureText: obscureConfirm,
                        onToggleVisibility: () => setSheetState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Vui long xac nhan mat khau moi.';
                          }
                          if (value != newPasswordCtrl.text) {
                            return 'Mat khau xac nhan khong khop.';
                          }
                          return null;
                        },
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.loading
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final sheetNavigator = Navigator.of(
                                    sheetContext,
                                  );
                                  final rootMessenger = ScaffoldMessenger.of(
                                    this.context,
                                  );
                                  final success = await context
                                      .read<AuthProvider>()
                                      .changePassword(
                                        currentPassword:
                                            currentPasswordCtrl.text,
                                        newPassword: newPasswordCtrl.text,
                                      );

                                  if (!mounted) return;
                                  if (success) {
                                    sheetNavigator.pop();
                                    rootMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Doi mat khau thanh cong.',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: auth.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Cap nhat mat khau'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      currentPasswordCtrl.dispose();
      newPasswordCtrl.dispose();
      confirmPasswordCtrl.dispose();
    });
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? type,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: onChanged,
      minLines: maxLines > 1 ? 3 : 1,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textGray,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_profile?.hasCustomAvatar == true) {
      return Image.memory(
        base64Decode(_profile!.avatarBase64!),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    return Image.asset(
      'assets/images/avatar.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }

  Future<void> _pickAvatar() async {
    if (_profile == null || _pickingAvatar) return;

    _pickingAvatar = true;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 35,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final encoded = base64Encode(await picked.readAsBytes());
      if (encoded.length > 800000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anh qua lon, vui long chon anh nho hon.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }

      _profile!.avatarBase64 = encoded;
      await _dataService.updateUserProfile(_profile!);
      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (error.code == 'already_active') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trinh chon anh dang mo, vui long cho mot chut.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      _pickingAvatar = false;
    }
  }

  Future<void> _openPurchaseHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PurchaseHistoryScreen()),
    );
    _loadProfile();
  }

  Future<void> _openSellingProducts() async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductCollectionScreen(
          title: 'San pham dang ban',
          emptyTitle: 'Ban chua dang san pham nao',
          emptySubtitle: 'Nhung san pham ban dang se hien thi tai day.',
          loader: () => _dataService.getProductsBySeller(userId),
        ),
      ),
    );
    _loadProfile();
  }

  Future<void> _openFavoriteProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductCollectionScreen(
          title: 'Yeu thich',
          emptyTitle: 'Danh sach yeu thich dang trong',
          emptySubtitle:
              'Nhan vao bieu tuong tim de luu san pham ban quan tam.',
          loader: _dataService.getFavoriteProducts,
        ),
      ),
    );
    _loadProfile();
  }

  Future<void> _openAdminDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
    _loadProfile();
  }

  Future<void> _openAdminSupportChat() async {
    final admin = await _dataService.getPrimaryAdminProfile();
    if (!mounted) return;
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chua tim thay admin de ho tro luc nay.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    if (_dataService.currentUserId == admin.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ban dang su dung tai khoan admin.'),
          backgroundColor: AppColors.amber,
        ),
      );
      return;
    }

    final conversationId = await _dataService.ensureAdminConversation();
    if (!mounted) return;
    if (conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong the khoi tao doan chat voi admin luc nay.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          sellerUid: admin.id,
          sellerName: admin.name,
          productId: 'support_admin',
          productTitle: 'Ho tro EduShare',
          productType: 'dung_cu',
          conversationId: conversationId,
        ),
      ),
    );
  }

  void _showWalletDepositSheet() {
    final amountCtrl = TextEditingController();
    const quickAmounts = <double>[50000, 100000, 200000, 500000, 1000000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        double? selectedAmount;

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nap tien vao vi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chon nhanh so tien ban muon nap hoac nhap so khac. He thong se tao ma PayOS va tu dong cong 90% vao vi sau khi thanh toan thanh cong.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: quickAmounts.map((amount) {
                      final isSelected = selectedAmount == amount;
                      return ChoiceChip(
                        label: Text(Formatter.price(amount)),
                        selected: isSelected,
                        onSelected: (_) {
                          setSheetState(() {
                            selectedAmount = amount;
                            amountCtrl.text = amount.toStringAsFixed(0);
                          });
                        },
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _editField(
                    'So tien muon nap',
                    amountCtrl,
                    Icons.payments_outlined,
                    type: TextInputType.number,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Ban nap ${Formatter.price(_parseCurrencyInput(amountCtrl.text))} -> vi nhan ${Formatter.price(_parseCurrencyInput(amountCtrl.text) * AdminConfig.walletTopupCreditRate)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = _parseCurrencyInput(amountCtrl.text);
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui long nhap so tien hop le.'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                          return;
                        }

                        final sheetNavigator = Navigator.of(sheetContext);
                        final rootNavigator = Navigator.of(this.context);
                        final rootMessenger = ScaffoldMessenger.of(
                          this.context,
                        );
                        final request = await _dataService.requestWalletDeposit(
                          amount,
                        );
                        if (!mounted) return;
                        sheetNavigator.pop();
                        if (request == null) {
                          rootMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Khong the tao yeu cau nap tien luc nay.',
                              ),
                              backgroundColor: AppColors.red,
                            ),
                          );
                          return;
                        }

                        await rootNavigator.push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _WalletTopupScreen(request: request),
                          ),
                        );
                        _loadProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Tao QR nap tien'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(amountCtrl.dispose);
  }

  void _showWalletWithdrawSheet() {
    final profile = _profile;
    if (profile == null) return;

    if (!profile.hasBankAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Can cap nhat tai khoan ngan hang truoc khi rut tien.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController(
      text: profile.walletBalance > 0
          ? profile.walletBalance.toStringAsFixed(0)
          : '',
    );
    final quickAmounts = _withdrawQuickAmounts(profile.walletBalance);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        double? selectedAmount = _parseCurrencyInput(amountCtrl.text);

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rut tien tu vi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'So du kha dung: ${Formatter.price(profile.walletBalance)}. Chon nhanh so tien muon rut hoac nhap so khac.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
                  ),
                  if (quickAmounts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: quickAmounts.map((amount) {
                        final isSelected = selectedAmount == amount;
                        return ChoiceChip(
                          label: Text(Formatter.price(amount)),
                          selected: isSelected,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedAmount = amount;
                              amountCtrl.text = amount.toStringAsFixed(0);
                            });
                          },
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _editField(
                    'So tien muon rut',
                    amountCtrl,
                    Icons.account_balance_wallet_outlined,
                    type: TextInputType.number,
                    onChanged: (_) {
                      setSheetState(() {
                        selectedAmount = _parseCurrencyInput(amountCtrl.text);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Sau khi gui yeu cau, ${Formatter.price(_parseCurrencyInput(amountCtrl.text))} se duoc tru khoi vi de admin xu ly.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = _parseCurrencyInput(amountCtrl.text);
                        if (amount <= 0 || amount > profile.walletBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('So tien rut khong hop le.'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                          return;
                        }

                        final sheetNavigator = Navigator.of(sheetContext);
                        final rootMessenger = ScaffoldMessenger.of(context);
                        final request = await _dataService
                            .requestWalletWithdrawal(amount);
                        if (!mounted) return;
                        sheetNavigator.pop();
                        if (request == null) {
                          rootMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Khong the tao yeu cau rut tien luc nay.',
                              ),
                              backgroundColor: AppColors.red,
                            ),
                          );
                          return;
                        }
                        rootMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Da tao yeu cau rut ${Formatter.price(amount)}. Admin se xu ly som.',
                            ),
                          ),
                        );
                        _loadProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Gui yeu cau rut tien'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(amountCtrl.dispose);
  }

  List<double> _withdrawQuickAmounts(double balance) {
    if (balance <= 0) return const [];
    final presets = <double>[50000, 100000, 200000, 500000, 1000000];
    final amounts = presets.where((amount) => amount <= balance).toList();
    final roundedBalance = balance.floorToDouble();
    if (roundedBalance > 0 && !amounts.contains(roundedBalance)) {
      amounts.add(roundedBalance);
    }
    amounts.sort();
    return amounts;
  }

  double _parseCurrencyInput(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dang xuat?'),
        content: const Text(
          'Ban co chac muon dang xuat khoi tai khoan hien tai khong?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
            child: const Text(
              'Dang xuat',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTopupScreen extends StatefulWidget {
  final WalletRequest request;

  const _WalletTopupScreen({required this.request});

  @override
  State<_WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<_WalletTopupScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  Timer? _autoCheckTimer;
  bool _checkingBank = false;
  bool _confirmed = false;

  WalletRequest get request => widget.request;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBankPayment());
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _checkBankPayment(silent: true),
    );
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPayosQr = request.payosQrCode.trim().isNotEmpty;
    final hasPayosLink = request.payosCheckoutUrl.trim().isNotEmpty;
    final qrUrl = hasPayosQr
        ? 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(request.payosQrCode)}'
        : 'https://img.vietqr.io/image/'
              '${AdminConfig.bankBin}-${AdminConfig.bankAccountNumber}-compact2.png'
              '?amount=${request.requestedAmount.round()}'
              '&addInfo=${Uri.encodeComponent(request.transferNote)}'
              '&accountName=${Uri.encodeComponent(AdminConfig.bankAccountHolder)}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('QR nap tien vao vi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    qrUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 220,
                      height: 220,
                      color: const Color(0xFFF8FAFC),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 88,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  hasPayosQr
                      ? 'Quet QR PayOS de nap tien vao vi'
                      : 'Quet QR de nap tien vao vi EduShare',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasPayosQr
                      ? 'Sau khi PayOS bao thanh toan thanh cong, he thong se tu xac nhan va cong ${Formatter.price(request.creditedAmount)} vao vi.'
                      : 'Sau khi chuyen dung so tien va noi dung giao dich, he thong se tu xac nhan va cong ${Formatter.price(request.creditedAmount)} vao vi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGray,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_confirmed ? AppColors.primary : AppColors.amber)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (_checkingBank && !_confirmed)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.amber,
                          ),
                        )
                      else
                        Icon(
                          _confirmed
                              ? Icons.verified_rounded
                              : Icons.manage_search_rounded,
                          size: 20,
                          color: _confirmed
                              ? AppColors.primary
                              : AppColors.amber,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _confirmed
                              ? 'Da tim thay giao dich va cong tien vao vi.'
                              : hasPayosQr
                              ? 'Dang tu dong kiem tra trang thai PayOS...'
                              : 'Dang tu dong doi soat giao dich ngan hang...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _confirmed
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _walletInfoRow(context, 'Ngan hang', AdminConfig.bankName),
                _walletInfoRow(context, 'Ma BIN', AdminConfig.bankBin),
                _walletInfoRow(
                  context,
                  'So tai khoan',
                  AdminConfig.bankAccountNumber,
                  copyValue: AdminConfig.bankAccountNumber,
                ),
                _walletInfoRow(
                  context,
                  'Chu tai khoan',
                  AdminConfig.bankAccountHolder,
                ),
                _walletInfoRow(
                  context,
                  'Noi dung GD',
                  request.transferNote,
                  copyValue: request.transferNote,
                ),
                _walletInfoRow(
                  context,
                  'So tien chuyen',
                  Formatter.price(request.requestedAmount),
                ),
                _walletInfoRow(
                  context,
                  'Tien vao vi',
                  Formatter.price(request.creditedAmount),
                ),
                if (hasPayosLink)
                  _walletInfoRow(
                    context,
                    'Link PayOS',
                    request.payosCheckoutUrl,
                    copyValue: request.payosCheckoutUrl,
                  ),
                if (request.payosOrderCode != null)
                  _walletInfoRow(
                    context,
                    'Ma PayOS',
                    request.payosOrderCode.toString(),
                    copyValue: request.payosOrderCode.toString(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final admin = await _dataService.getPrimaryAdminProfile();
                if (!context.mounted) return;
                if (admin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chua tim thay admin de ho tro luc nay.'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                if (_dataService.currentUserId == admin.id) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ban dang su dung tai khoan admin.'),
                      backgroundColor: AppColors.amber,
                    ),
                  );
                  return;
                }

                final conversationId = await _dataService
                    .ensureAdminConversation(
                      topic: 'Ho tro nap tien vi EduShare',
                    );
                if (!context.mounted) return;
                if (conversationId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Khong the khoi tao doan chat voi admin luc nay.',
                      ),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      sellerUid: admin.id,
                      sellerName: admin.name,
                      productId: 'support_admin',
                      productTitle: 'Ho tro nap tien vi EduShare',
                      productType: 'dung_cu',
                      conversationId: conversationId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Can ho tro? Chat voi admin'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final shouldCancel = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Huy yeu cau nap tien?'),
                        content: const Text(
                          'Yeu cau nap tien nay se bi huy va admin se khong xu ly nua.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Khong'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Huy yeu cau',
                              style: TextStyle(color: AppColors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldCancel != true) return;
                    await _dataService.cancelWalletRequest(request.id);
                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Da huy yeu cau nap tien.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Huy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _checkingBank
                      ? null
                      : _confirmed
                      ? () => Navigator.pop(context)
                      : () => _checkBankPayment(silent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(_confirmed ? 'Hoan tat' : 'Kiem tra giao dich'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _checkBankPayment({bool silent = false}) async {
    if (_checkingBank || _confirmed) return;
    setState(() => _checkingBank = true);
    final confirmed = await _dataService
        .autoConfirmWalletDepositFromBankTransaction(request.id);
    if (!mounted) return;
    setState(() {
      _checkingBank = false;
      _confirmed = confirmed;
    });

    if (confirmed) {
      _autoCheckTimer?.cancel();
      await _showPaymentSuccessEffect(
        amount: request.creditedAmount,
        paymentCode: request.payosOrderCode?.toString() ?? request.transferNote,
      );
      return;
    }

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            request.payosQrCode.trim().isNotEmpty
                ? 'PayOS chua bao thanh toan thanh cong. He thong van tiep tuc tu kiem tra.'
                : 'Chua tim thay giao dich khop so tien va noi dung. He thong van tiep tuc tu kiem tra.',
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    }
  }

  Widget _walletInfoRow(
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
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (copyValue != null)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copyValue));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Da sao chep thong tin.'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
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

  Future<void> _showPaymentSuccessEffect({
    required double amount,
    required String paymentCode,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Thanh toan thanh cong',
      barrierColor: Colors.black.withValues(alpha: 0.76),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => _WalletPaymentSuccessOverlay(
        amount: amount,
        paymentCode: paymentCode,
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}

class _WalletPaymentSuccessOverlay extends StatefulWidget {
  final double amount;
  final String paymentCode;

  const _WalletPaymentSuccessOverlay({
    required this.amount,
    required this.paymentCode,
  });

  @override
  State<_WalletPaymentSuccessOverlay> createState() =>
      _WalletPaymentSuccessOverlayState();
}

class _WalletPaymentSuccessOverlayState
    extends State<_WalletPaymentSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = Curves.easeOutCubic.transform(
              _controller.value.clamp(0.0, 1.0).toDouble(),
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 310,
                  height: 310,
                  child: CustomPaint(
                    painter: _SuccessBurstPainter(progress: progress),
                  ),
                ),
                Transform.scale(
                  scale: 0.82 + (0.18 * Curves.elasticOut.transform(progress)),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF052F2B),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFF67E8F9).withValues(alpha: 0.42),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.42),
                          blurRadius: 34,
                          spreadRadius: 4,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SuccessCore(progress: progress),
                        const SizedBox(height: 18),
                        const Text(
                          'Thanh toan thanh cong',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+${Formatter.price(widget.amount)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF99F6E4),
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vi EduShare da duoc nap tien.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Ma GD: ${widget.paymentCode}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFCCFBF1),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DD4BF),
                              foregroundColor: const Color(0xFF042F2E),
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Tuyet, ve vi cua toi',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuccessCore extends StatelessWidget {
  final double progress;

  const _SuccessCore({required this.progress});

  @override
  Widget build(BuildContext context) {
    final ring = 82 + (34 * progress);
    final ringOpacity = (1 - progress).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5EEAD4).withValues(
                  alpha: ringOpacity,
                ),
                width: 3,
              ),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2DD4BF), Color(0xFF22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.38),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 14,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF052F2B), width: 3),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBurstPainter extends CustomPainter {
  final double progress;

  const _SuccessBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..strokeCap = StrokeCap.round;
    final colors = [
      const Color(0xFF2DD4BF),
      const Color(0xFFF59E0B),
      const Color(0xFF60A5FA),
      const Color(0xFFA7F3D0),
    ];

    for (var i = 0; i < 28; i++) {
      final angle = (math.pi * 2 / 28) * i;
      final stagger = ((progress - (i % 7) * 0.035) / 0.86)
          .clamp(0.0, 1.0)
          .toDouble();
      if (stagger <= 0) continue;

      final distance = 54 + (112 * Curves.easeOutCubic.transform(stagger));
      final start = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final length = (8 + (i % 4) * 4).toDouble();
      final end =
          start + Offset(math.cos(angle), math.sin(angle)) * length * stagger;
      paint
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - stagger).clamp(0.16, 0.94).toDouble(),
        )
        ..strokeWidth = 2.4 + (i % 3);
      canvas.drawLine(start, end, paint);
    }

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF99F6E4).withValues(
        alpha: (1 - progress).clamp(0.0, 0.38).toDouble(),
      );
    canvas.drawCircle(center, 74 + progress * 82, paint);
  }

  @override
  bool shouldRepaint(covariant _SuccessBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
