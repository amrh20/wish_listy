import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/user.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class StatsCards extends StatefulWidget {
  final User user;

  const StatsCards({
    super.key,
    required this.user,
  });

  @override
  State<StatsCards> createState() => _StatsCardsState();
}

class _StatsCardsState extends State<StatsCards>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotateAnimations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(4, (index) => AnimationController(
      duration: Duration(milliseconds: 600 + (index * 100)),
      vsync: this,
    ));
    
    _scaleAnimations = _controllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut)
      )
    ).toList();
    
    _rotateAnimations = _controllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      )
    ).toList();
    
    // Start animations with delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
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
    final stats = [
      {
        'title': 'My Wishes',
        'count': widget.user.wishCount,
        'icon': Icons.card_giftcard,
        'gradient': AppColors.primaryGradient,
        'iconGradient': AppColors.pinkGradient,
        'emoji': '🎁',
      },
      {
        'title': 'Reserved',
        'count': widget.user.reservedCount,
        'icon': Icons.check_circle,
        'gradient': AppColors.successGradient,
        'iconGradient': AppColors.tealGradient,
        'emoji': '✅',
      },
      {
        'title': 'Friends',
        'count': widget.user.friendsCount,
        'icon': Icons.people,
        'gradient': AppColors.warningGradient,
        'iconGradient': AppColors.indigoGradient,
        'emoji': '👥',
      },
      {
        'title': 'Events',
        'count': widget.user.eventsCount,
        'icon': Icons.event,
        'gradient': AppColors.infoGradient,
        'iconGradient': AppColors.accentGradient,
        'emoji': '📅',
      },
    ];

    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimations[index].value,
                  child: Transform.rotate(
                    angle: _rotateAnimations[index].value,
                    child: _buildStatCard(stat, index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, int index) {
    return Container(
      decoration: AppStyles.cardDecoration.copyWith(
        gradient: stat['gradient'],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat['title'],
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: stat['iconGradient'],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        stat['emoji'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['count'].toString(),
                      style: AppStyles.heading2.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'items',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textWhite.withOpacity(0.8),
                        fontSize: 12,
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
}
