import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(4, (index) => AnimationController(
      duration: Duration(milliseconds: 300 + (index * 50)),
      vsync: this,
    ));
    
    _scaleAnimations = _controllers.map((controller) => 
      Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      )
    ).toList();
    
    _bounceAnimations = _controllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.bounceOut)
      )
    ).toList();
    
    // Start initial animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Home',
        'gradient': AppColors.primaryGradient,
      },
      {
        'icon': Icons.card_giftcard_outlined,
        'activeIcon': Icons.card_giftcard,
        'label': 'Wishlist',
        'gradient': AppColors.pinkGradient,
      },
      {
        'icon': Icons.people_outline,
        'activeIcon': Icons.people,
        'label': 'Friends',
        'gradient': AppColors.indigoGradient,
      },
      {
        'icon': Icons.event_outlined,
        'activeIcon': Icons.event,
        'label': 'Events',
        'gradient': AppColors.tealGradient,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = widget.currentIndex == index;

              return AnimatedBuilder(
                animation: _controllers[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: isActive ? _scaleAnimations[index].value : 1.0,
                    child: _buildNavigationItem(
                      item: item,
                      isActive: isActive,
                      onTap: () {
                        widget.onTap(index);
                        _controllers[index].forward().then((_) {
                          _controllers[index].reverse();
                        });
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required Map<String, dynamic> item,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? item['gradient'] : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isActive ? item['activeIcon'] : item['icon'],
                key: ValueKey(isActive),
                color: isActive ? AppColors.textWhite : AppColors.textLight,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['label'],
              style: AppStyles.caption.copyWith(
                color: isActive ? AppColors.textWhite : AppColors.textLight,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
