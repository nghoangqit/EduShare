import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/firebase_data_service.dart';
import 'profile_screen.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';

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
  UserProfile? _profile;
  bool _loading = true;
  String? _selectedCategory;

  static const List<Map<String, dynamic>> _categorySeeds = [
    {'id': 'all', 'name': 'Tất cả', 'emoji': '🛍️', 'color': AppColors.primary},
    {'id': 'Toán - Tin', 'name': 'Toán - Tin', 'emoji': '📚', 'color': AppColors.primary},
    {'id': 'Văn học', 'name': 'Văn học', 'emoji': '📖', 'color': AppColors.blue},
    {'id': 'Khoa học', 'name': 'Khoa học', 'emoji': '🔬', 'color': AppColors.amber},
    {'id': 'Kinh tế', 'name': 'Kinh tế', 'emoji': '📈', 'color': AppColors.primaryDark},
    {'id': 'Ngoại ngữ', 'name': 'Ngoại ngữ', 'emoji': '🌐', 'color': AppColors.purple},
    {'id': 'Vẽ - Mỹ thuật', 'name': 'Vẽ - Mỹ thuật', 'emoji': '🎨', 'color': AppColors.amber},
    {'id': 'Máy tính', 'name': 'Máy tính', 'emoji': '🧮', 'color': AppColors.blue},
    {'id': 'Dụng cụ', 'name': 'Dụng cụ', 'emoji': '✂️', 'color': AppColors.purple},
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
    final profile = await _dataService.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      _allProducts = all;
      _featuredProducts = featured;
      _recentProducts = recent;
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
        emoji: seed['emoji'] as String,
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildSearchBar(),
                      _buildCategories(),
                      if (_selectedCategory != null && _selectedCategory != 'all') _buildFilterBanner(selectedCategory.name),
                      _buildFeaturedProducts(filteredFeatured),
                      _buildRecentProducts(filteredRecent),
                      if (filteredFeatured.isEmpty && filteredRecent.isEmpty) _buildEmptyCategoryState(),
                      const SizedBox(height: 84),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tìm sách và dụng cụ học tập tái sử dụng',
                  style: TextStyle(fontSize: 13, color: AppColors.primaryLight),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Tiết kiệm chi phí, lan tỏa học liệu',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
              await _loadData();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildHeaderAvatar(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.bg],
        ),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(width: 12),
            Icon(Icons.search, color: AppColors.textGray, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tìm sách, máy tính, dụng cụ...',
                style: TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text('Lọc', style: TextStyle(color: Colors.white, fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh mục',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedCategory = 'all'),
                  child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 102,
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
        width: 84,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? cat.color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: cat.color.withOpacity(0.35)) : null,
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(isSelected ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(cat.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected ? cat.color : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text('${cat.count} sp', style: const TextStyle(fontSize: 9.5, color: AppColors.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBanner(String categoryName) {
    final count = _filterProducts(_allProducts).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đang lọc theo "$categoryName" • $count sản phẩm',
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedCategory = 'all'),
              child: const Text('Bỏ lọc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(List<Product> products) {
    if (products.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          _sectionHeader('Sản phẩm nổi bật'),
          _productGrid(products),
        ],
      ),
    );
  }

  Widget _buildRecentProducts(List<Product> products) {
    if (products.isEmpty) return const SizedBox();
    return Column(
      children: [
        _sectionHeader('Mới đăng gần đây'),
        _productGrid(products),
      ],
    );
  }

  Widget _buildEmptyCategoryState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 28, color: AppColors.textGray),
            SizedBox(height: 10),
            Text(
              'Danh mục này chưa có sản phẩm phù hợp.',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            SizedBox(height: 4),
            Text(
              'Hãy chọn danh mục khác hoặc thêm sản phẩm mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary)),
          ),
        ],
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
