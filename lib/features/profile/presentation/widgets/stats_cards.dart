import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/auth/data/models/user_model.dart';

class StatsCards extends StatefulWidget {
  final User user;

  const StatsCards({
    super.key,
    required this.user,
  });

  @override
  State<StatsCards> createState() => _StatsCardsState();
}

class _StatsCardsState extends State<StatsCards> {
  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'count': 12,
        'label': 'Wishes',
        'icon': Icons.card_giftcard,
        'color': AppColors.pink,
        'gradient': AppColors.pinkGradient,
      },
      {
        'count': 3,
        'label': 'Reserved',
        'icon': Icons.check_circle,
        'color': AppColors.success,
        'gradient': AppColors.successGradient,
      },
      {
        'count': 25,
        'label': 'Friends',
        'icon': Icons.people,
        'color': AppColors.indigo,
        'gradient': AppColors.indigoGradient,
      },
      {
        'count': 8,
        'label': 'Events',
        'icon': Icons.event,
        'color': AppColors.secondary,
        'gradient': AppColors.tealGradient,
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 Statistics',
                style: AppStyles.heading4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2, // Increased aspect ratio to prevent overflow
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(stat);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: AppStyles.cardDecoration.copyWith(
        gradient: stat['gradient'],
      ),
      child: ClipRRect( // Added ClipRRect to prevent overflow
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Pattern - Reduced size to prevent overflow
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content - Reduced padding to prevent overflow
            Padding(
              padding: const EdgeInsets.all(16.0), // Reduced from 20.0
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stat['label'] ?? 'Unknown',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 14, // Reduced from 15
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10), // Reduced from 12
                        decoration: BoxDecoration(
                          color: stat['color']?.withOpacity(0.2) ?? Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10), // Reduced from 12
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8, // Reduced from 10
                              offset: const Offset(0, 3), // Reduced from 4
                            ),
                          ],
                        ),
                        child: Icon(
                          stat['icon'] ?? Icons.help,
                          color: stat['color'] ?? Colors.white,
                          size: 18, // Reduced from 20
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Added spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (stat['count'] ?? 0).toString(),
                        style: AppStyles.heading2.copyWith(
                          color: AppColors.textWhite,
                          fontSize: 24, // Reduced from 28
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'items',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textWhite.withOpacity(0.8),
                          fontSize: 11, // Reduced from 12
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
