import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/notification_system_service.dart';
import '../utils/constants.dart';
import '../widgets/glass_surface.dart';
import 'add_product_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationSystemService.instance.startForCurrentUser();
  }

  @override
  void dispose() {
    NotificationSystemService.instance.stopForCurrentUser();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      CartScreen(onExploreProducts: () => _selectTab(0)),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _buildAnimatedTabBody(screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          if (result == true && mounted) {
            _selectTab(0);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  Widget _buildAnimatedTabBody(List<Widget> screens) {
    final forward = _selectedIndex >= _previousIndex;
    return Stack(
      children: List.generate(screens.length, (index) {
        final selected = index == _selectedIndex;
        final horizontalOffset = selected
            ? 0.0
            : index < _selectedIndex
            ? -0.08
            : 0.08;

        return IgnorePointer(
          ignoring: !selected,
          child: AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: Offset(horizontalOffset, selected ? 0 : 0.015),
              duration: Duration(milliseconds: selected ? 360 : 240),
              curve: forward ? Curves.easeOutBack : Curves.easeOutCubic,
              child: AnimatedScale(
                scale: selected ? 1 : 0.985,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: TickerMode(
                  enabled: selected,
                  child: KeyedSubtree(
                    key: PageStorageKey<String>('tab-$index'),
                    child: screens[index],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SizedBox(
          height: 74,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(26),
            opacity: 0.76,
            blur: 20,
            borderColor: Colors.white.withValues(alpha: 0.62),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
            child: Row(
              children: [
                Expanded(
                  child: _navItem(
                    index: 0,
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Trang chu',
                  ),
                ),
                Expanded(
                  child: _navItem(
                    index: 1,
                    activeIcon: Icons.search_rounded,
                    inactiveIcon: Icons.search_outlined,
                    label: 'Tim kiem',
                  ),
                ),
                const SizedBox(width: 64),
                Expanded(child: _navCartItem()),
                Expanded(
                  child: _navItem(
                    index: 3,
                    activeIcon: Icons.person_rounded,
                    inactiveIcon: Icons.person_outline_rounded,
                    label: 'Ho so',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final selected = _selectedIndex == index;
    return InkWell(
      onTap: () => _selectTab(index),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1.04 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: selected
                ? BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? activeIcon : inactiveIcon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navCartItem() {
    return InkWell(
      onTap: () => _selectTab(2),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            final selected = _selectedIndex == 2;
            return AnimatedScale(
              scale: selected ? 1.04 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: selected
                    ? BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          selected
                              ? Icons.shopping_cart_rounded
                              : Icons.shopping_cart_outlined,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        if (cart.totalCount > 0)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cart.totalCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gio hang',
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
