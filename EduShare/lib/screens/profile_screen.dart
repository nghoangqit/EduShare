import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text(
            'Khong tim thay ho so',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProfile,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection()),
            SliverToBoxAdapter(child: _buildHighlightStrip()),
            SliverToBoxAdapter(child: _buildActionGrid()),
            SliverToBoxAdapter(child: _buildMenuSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final profile = _profile!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF062E2B),
            Color(0xFF0D9488),
            Color(0xFF43C6B6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ho so cua toi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    _glassIconButton(Icons.edit_outlined, _showEditProfile),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: _buildAvatarImage(),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFB8F4ED), width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _heroInfoChip(
                            icon: Icons.alternate_email_rounded,
                            label: profile.email,
                          ),
                          if (profile.university.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _heroInfoChip(
                              icon: Icons.school_outlined,
                              label: profile.university,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: Row(
                                  children: [
                                    ...List.generate(5, (i) {
                                      return Icon(
                                        i < profile.rating.floor()
                                            ? Icons.star_rounded
                                            : (i < profile.rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                        color: const Color(0xFFFFD76A),
                                        size: 16,
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${profile.rating}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
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
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _heroMetric(
                          value: Formatter.joinDate(profile.joinDate),
                          label: 'Thanh vien tu',
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.12)),
                      Expanded(
                        child: _heroMetric(
                          value: profile.phone.trim().isEmpty ? 'Cap nhat' : profile.phone,
                          label: 'Lien he',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _highlightCard(
              title: 'Da mua',
              value: '$_purchaseCount',
              subtitle: 'Don hang cua ban',
              icon: Icons.shopping_bag_outlined,
              accent: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _highlightCard(
              title: 'Dang ban',
              value: '$_sellingCount',
              subtitle: 'San pham dang hien thi',
              icon: Icons.sell_outlined,
              accent: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khong gian giao dich',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Theo doi nhanh cac danh muc ban su dung nhieu nhat.',
              style: TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    icon: Icons.history_rounded,
                    title: 'Lich su mua',
                    subtitle: 'Xem cac giao dich da dat',
                    accent: AppColors.primary,
                    badge: '$_purchaseCount',
                    onTap: _openPurchaseHistory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionTile(
                    icon: Icons.favorite_rounded,
                    title: 'Yeu thich',
                    subtitle: 'Luu cac mon ban quan tam',
                    accent: AppColors.red,
                    badge: '$_favoriteCount',
                    onTap: _openFavoriteProducts,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: [
          _menuGroup(
            'Tai khoan',
            'Quan ly thong tin va bao mat',
            [
              _MenuItem(
                icon: Icons.person_outline_rounded,
                label: 'Thong tin ca nhan',
                subtitle: 'Cap nhat ten, truong va thong tin lien he',
                onTap: _showEditProfile,
              ),
              _MenuItem(
                icon: Icons.phone_iphone_outlined,
                label: 'So dien thoai',
                subtitle: _profile!.phone.trim().isEmpty ? 'Chua cap nhat' : _profile!.phone,
                onTap: _showEditProfile,
              ),
              _MenuItem(
                icon: Icons.account_balance_outlined,
                label: 'Tai khoan ngan hang',
                subtitle: _profile!.hasBankAccount
                    ? '${_profile!.bankName} • ${_profile!.bankAccountNumber}'
                    : 'Them thong tin de nhan thanh toan bang QR',
                onTap: _showEditProfile,
              ),
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'Doi mat khau',
                subtitle: 'Tang bao mat cho tai khoan cua ban',
                onTap: _showChangePasswordSheet,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _menuGroup(
            'Hoat dong',
            'Cac khu vuc du lieu va giao dich',
            [
              _MenuItem(
                icon: Icons.storefront_outlined,
                label: 'San pham dang ban',
                subtitle: 'Quan ly nhung bai dang dang hien thi',
                badge: '$_sellingCount',
                onTap: _openSellingProducts,
              ),
              _MenuItem(
                icon: Icons.favorite_border_rounded,
                label: 'Yeu thich',
                subtitle: 'Danh sach san pham luu lai de xem sau',
                badge: '$_favoriteCount',
                onTap: _openFavoriteProducts,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _menuGroup(
            'Ho tro',
            'Tro giup va thong tin he thong',
            [
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Trung tam ho tro',
                subtitle: 'Cau hoi thuong gap va huong dan',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.info_outline_rounded,
                label: 'Ve EduShare',
                subtitle: 'Nen tang mua ban do dung hoc tap',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Dang xuat',
                subtitle: 'Thoat khoi tai khoan hien tai',
                color: AppColors.red,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuGroup(String title, String subtitle, List<_MenuItem> items) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.4),
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final color = item.color ?? AppColors.primary;
            return Container(
              margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: color.withValues(alpha: 0.08)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: item.onTap,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.18),
                            color.withValues(alpha: 0.07),
                          ],
                        ),
                      ),
                      child: Icon(item.icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: item.color ?? AppColors.textDark,
                            ),
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle!,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray, height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_ios_rounded, size: 15, color: color.withValues(alpha: 0.65)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _heroInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD5FFF9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD4F8F2),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _highlightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
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
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.12),
              accent.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGray, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _profile!.name);
    final phoneCtrl = TextEditingController(text: _profile!.phone);
    final uniCtrl = TextEditingController(text: _profile!.university);
    final bankNameCtrl = TextEditingController(text: _profile!.bankName);
    final bankBinCtrl = TextEditingController(text: _profile!.bankBin);
    final bankNumberCtrl = TextEditingController(text: _profile!.bankAccountNumber);
    final bankHolderCtrl = TextEditingController(text: _profile!.bankAccountHolder);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 14),
                _editField('Ho va ten', nameCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _editField('So dien thoai', phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 12),
                _editField('Truong dai hoc', uniCtrl, Icons.school_outlined),
                const SizedBox(height: 18),
                const Text(
                  'Nhan thanh toan bang QR',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Khai bao thong tin ngan hang de nguoi mua co the tao QR chuyen khoan tu dong.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textGray, height: 1.4),
                ),
                const SizedBox(height: 14),
                _editField('Ten ngan hang', bankNameCtrl, Icons.account_balance_outlined),
                const SizedBox(height: 12),
                _editField('Ma BIN ngan hang', bankBinCtrl, Icons.numbers_outlined, type: TextInputType.number),
                const SizedBox(height: 12),
                _editField('So tai khoan', bankNumberCtrl, Icons.credit_card_outlined, type: TextInputType.number),
                const SizedBox(height: 12),
                _editField('Ten chu tai khoan', bankHolderCtrl, Icons.badge_outlined),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      _profile!.name = nameCtrl.text.trim();
                      _profile!.phone = phoneCtrl.text.trim();
                      _profile!.university = uniCtrl.text.trim();
                      _profile!.bankName = bankNameCtrl.text.trim();
                      _profile!.bankBin = bankBinCtrl.text.trim();
                      _profile!.bankAccountNumber = bankNumberCtrl.text.trim();
                      _profile!.bankAccountHolder = bankHolderCtrl.text.trim();
                      await _dataService.updateUserProfile(_profile!);
                      if (!mounted) return;
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Luu thay doi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(20),
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: auth.loading ? null : () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhap mat khau hien tai de xac thuc, sau do dat mat khau moi cho tai khoan.',
                        style: TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        label: 'Mat khau hien tai',
                        controller: currentPasswordCtrl,
                        obscureText: obscureCurrent,
                        onToggleVisibility: () => setSheetState(() => obscureCurrent = !obscureCurrent),
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
                        onToggleVisibility: () => setSheetState(() => obscureNew = !obscureNew),
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
                        onToggleVisibility: () => setSheetState(() => obscureConfirm = !obscureConfirm),
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
                          style: const TextStyle(color: AppColors.red, fontSize: 12),
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
                                  if (!formKey.currentState!.validate()) return;

                                  final success = await context.read<AuthProvider>().changePassword(
                                    currentPassword: currentPasswordCtrl.text,
                                    newPassword: newPasswordCtrl.text,
                                  );

                                  if (!mounted) return;
                                  if (success) {
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Doi mat khau thanh cong.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: auth.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Cap nhat mat khau', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
          emptySubtitle: 'Nhan vao bieu tuong tim de luu san pham ban quan tam.',
          loader: _dataService.getFavoriteProducts,
        ),
      ),
    );
    _loadProfile();
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
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
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Dang xuat?'),
        content: const Text('Ban co chac muon dang xuat khoi tai khoan hien tai khong?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
            child: const Text('Dang xuat', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.color,
    required this.onTap,
  });
}
