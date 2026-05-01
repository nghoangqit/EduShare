import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  List<Product> _results = [];
  bool _searched = false;
  bool _loading = false;

  final List<String> _suggestions = [
    'Giải tích',
    'Máy tính Casio',
    'Từ điển',
    'Kinh tế',
    'Laptop',
    'Dụng cụ vẽ',
  ];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    final results = await _dataService.searchProducts(query.trim());
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: false,
            onSubmitted: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm sách, máy tính, dụng cụ...',
              hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textGray, size: 20),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _searched = false;
                          _results = [];
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_ctrl.text),
            child: const Text('Tìm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : !_searched
              ? _buildSuggestions()
              : _results.isEmpty
                  ? _buildNoResult()
                  : _buildResults(),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  _ctrl.text = s;
                  _search(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset('assets/images/book.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy "${_ctrl.text}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text('Thử tìm với từ khóa khác', style: TextStyle(color: AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${_results.length} kết quả cho "${_ctrl.text}"',
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _results.length,
              itemBuilder: (_, i) => ProductCard(product: _results[i]),
            ),
          ),
        ),
      ],
    );
  }
}
