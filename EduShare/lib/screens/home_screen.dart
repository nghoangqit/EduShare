import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';
import 'notification_center_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;

  List<Product> _allProducts = [];
  List<Product> _featuredProducts = [];
  List<Product> _recentProducts = [];
  List<Product> _recommendedProducts = [];
  List<String> _recommendedKeywords = [];
  UserProfile? _profile;
  bool _loading = true;
  String? _selectedCategory;

  static const List<Map<String, dynamic>> _categorySeeds = [
    {'id': 'all', 'name': 'Tat ca', 'icon': Icons.grid_view_rounded, 'color': AppColors.primary},
    {'id': 'Toán - Tin', 'name': 'Toan - Tin', 'icon': Icons.menu_book_rounded, 'color': AppColors.primary},
    {'id': 'Văn học', 'name': 'Van hoc', 'icon': Icons.auto_stories_rounded, 'color': AppColors.blue},
    {'id': 'Khoa học', 'name': 'Khoa hoc', 'icon': Icons.science_rounded, 'color': AppColors.amber},
    {'id': 'Kinh tế', 'name': 'Kinh te', 'icon': Icons.insert_chart_outlined_rounded, 'color': AppColors.primaryDark},
    {'id': 'Ngoại ngữ', 'name': 'Ngoai ngu', 'icon': Icons.language_rounded, 'color': AppColors.purple},
    {'id': 'Vẽ - Mỹ thuật', 'name': 'Ve - My thuat', 'icon': Icons.palette_outlined, 'color': AppColors.amber},
    {'id': 'Máy tính', 'name': 'May tinh', 'icon': Icons.calculate_rounded, 'color': AppColors.blue},
    {'id': 'Dụng cụ', 'name': 'Dung cu', 'icon': Icons.content_cut_rounded, 'color': AppColors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await _dataService.getAllProducts();
    final featured = await _dataService.getFeaturedProducts();
    final recent = await _dataService.getRecentProducts();
    final recommended = await _dataService.getRecommendedProducts(limit: 6);
    final keywords = await _dataService.getRecommendedSearchKeywords(limit: 5);
    final profile = await _dataService.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      _allProducts = all;
      _featuredProducts = featured;
      _recentProducts = recent;
      _recommendedProducts = recommended;
      _recommendedKeywords = keywords;
      _profile = profile;
      _loading = false;
    });
  }

  List<Category> get _categories {
    final counts = <String, int>{};
    for (final product in _allProducts) {
      counts.update(product.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return _categorySeeds.map((seed) {
      final id = seed['id'] as String;
      return Category(
        id: id,
        name: seed['name'] as String,
        icon: seed['icon'] as IconData,
        count: id == 'all' ? _allProducts.length : (counts[id] ?? 0),
        color: seed['color'] as Color,
      );
    }).toList();
  }

  List<Product> _filterProducts(List<Product> source) {
    if (_selectedCategory == null || _selectedCategory == 'all') {
      return source;
    }
    return source.where((product) => product.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFeatured = _filterProducts(_featuredProducts);
    final filteredRecent = _filterProducts(_recentProducts);
    final selectedCategoryId = _selectedCategory ?? 'all';
    final selectedCategory = _categories.firstWhere(
      (category) => category.id == selectedCategoryId,
      orElse: () => _categories.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeroSection()),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildPromoStrip()),
                    SliverToBoxAdapter(child: _buildCategories()),
                    if (_recommendedProducts.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _sectionHeader(
                          'Danh cho ban',
                          _recommendedSubtitle(),
                        ),
                      ),
                      SliverToBoxAdapter(child: _productGrid(_recommendedProducts)),
                    ],
                    if (_selectedCategory != null && _selectedCategory != 'all')
                      SliverToBoxAdapter(child: _buildFilterBanner(selectedCategory.name)),
                    if (filteredFeatured.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _sectionHeader(
                          'Noi bat hom nay',
                          'Nhung mon do duoc quan tam nhieu trong cong dong.',
                        ),
                      ),
                      SliverToBoxAdapter(child: _productGrid(filteredFeatured)),
                    ],
                    if (filteredRecent.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _sectionHeader(
                          'Moi dang gan day',
                          'Cap nhat nhanh cac san pham vua xuat hien.',
                        ),
                      ),
                      SliverToBoxAdapter(child: _productGrid(filteredRecent)),
                    ],
                    if (filteredFeatured.isEmpty && filteredRecent.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyCategoryState()),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final name = _profile?.name.trim().isNotEmpty == true ? _profile!.name : 'Ban';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061F2A),
            Color(0xFF0D9488),
            Color(0xFF6DD3C5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -12,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -45,
            left: -18,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EduShare',
                            style: TextStyle(
                              color: Color(0xFFCFFFF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Xin chao, $name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _notificationButton(),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                        await _loadData();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildHeaderAvatar(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tim sach, may tinh va dung cu hoc tap da qua su dung voi giao dien mua sam gon gang va dang tin cay.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFE0FFFB),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _heroChip(
                        icon: Icons.workspace_premium_outlined,
                        label: 'San pham duoc duyet ky',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _heroChip(
                        icon: Icons.eco_outlined,
                        label: 'Tiet kiem va tai su dung',
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

  Widget _notificationButton() {
    return StreamBuilder<List<AppNotification>>(
      stream: _dataService.watchNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AppNotification>[];
        final unreadCount = notifications.where((item) => !item.isRead).length;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NotificationCenterScreen()),
            );
          },
          child: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD76A),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD9FFF9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar() {
    if (_profile?.hasCustomAvatar == true) {
      return Image.memory(
        base64Decode(_profile!.avatarBase64!),
        fit: BoxFit.cover,
      );
    }
    return Image.asset('assets/images/avatar.png', fit: BoxFit.cover);
  }

  Widget _buildSearchBar() {
    final hintKeywords = _recommendedKeywords.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.search_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tim kiem thong minh',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hintKeywords.isEmpty
                              ? 'Sach, may tinh, dung cu va nhieu hon nua'
                              : 'Goi y: ${hintKeywords.join(' • ')}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Goi y',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_recommendedKeywords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recommendedKeywords
                        .take(4)
                        .map(
                          (keyword) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              keyword,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E8),
              Color(0xFFF6FBF9),
            ],
          ),
          border: Border.all(color: const Color(0xFFE8F0EE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Goi y cho hoc ky moi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kham pha cac mon do hoc tap noi bat va duoc dang moi de san sang cho ky hoc tiep theo.',
                    style: TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Giao dien moi • de nhin • de mua',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = _categories;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh muc',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lua chon nhanh theo nhom san pham ban can.',
                        style: TextStyle(fontSize: 13, color: AppColors.textGray),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedCategory = 'all'),
                  child: const Text('Lam moi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 124,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (_, i) => _buildCategoryItem(categories[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Category cat) {
    final isSelected = (_selectedCategory ?? 'all') == cat.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? cat.color.withValues(alpha: 0.22) : const Color(0xFFE6ECEE),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cat.color.withValues(alpha: isSelected ? 0.22 : 0.14),
                    cat.color.withValues(alpha: isSelected ? 0.12 : 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Icon(cat.icon, size: 24, color: cat.color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected ? cat.color : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${cat.count} sp',
              style: const TextStyle(fontSize: 9.5, color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBanner(String categoryName) {
    final count = _filterProducts(_allProducts).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dang loc theo "$categoryName" • $count san pham',
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedCategory = 'all'),
              child: const Text('Bo loc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
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
        ],
      ),
    );
  }

  String _recommendedSubtitle() {
    final university = _profile?.university.trim() ?? '';
    if (university.isNotEmpty) {
      return 'Goi y dua tren truong $university, lich su mua sam va san pham ban da quan tam.';
    }
    return 'Goi y dua tren hanh vi tim kiem, san pham quan tam va xu huong hien tai.';
  }

  Widget _buildEmptyCategoryState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 34, color: AppColors.textGray),
            SizedBox(height: 12),
            Text(
              'Danh muc nay chua co san pham phu hop.',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            SizedBox(height: 6),
            Text(
              'Thu chuyen sang nhom khac hoac dang them san pham moi de lam noi dung phong phu hon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      ),
    );
  }
}
