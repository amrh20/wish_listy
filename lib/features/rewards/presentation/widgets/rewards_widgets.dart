import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/rewards/data/repository/rewards_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

// Points Display Widget
class PointsDisplay extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onTap;

  const PointsDisplay({super.key, this.isCompact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rewardsRepository = RewardsRepository();
    final userRewards = rewardsRepository.currentUserRewards;

    if (userRewards == null) return const SizedBox.shrink();

    if (isCompact) {
      return GestureDetector(
        onTap:
            onTap ??
            () => Navigator.of(context).pushNamed(AppRoutes.rewardsStore),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warning, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${userRewards.totalPoints}',
                style: AppStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.of(context).pushNamed(AppRoutes.rewardsStore),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warning.withOpacity(0.1),
              AppColors.accent.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.stars, color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Points',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${userRewards.totalPoints}',
                    style: AppStyles.headingSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// Level Progress Widget
class LevelProgressWidget extends StatelessWidget {
  final bool showDetails;

  const LevelProgressWidget({super.key, this.showDetails = true});

  @override
  Widget build(BuildContext context) {
    final rewardsRepository = RewardsRepository();
    final userRewards = rewardsRepository.currentUserRewards;

    if (userRewards == null) return const SizedBox.shrink();

    final currentLevel = userRewards.currentLevel;
    final progress = userRewards.progressToNextLevel;
    final pointsToNext = userRewards.pointsToNextLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            currentLevel.badgeColor.withOpacity(0.1),
            currentLevel.badgeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentLevel.badgeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentLevel.badgeColor,
                      currentLevel.badgeColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentLevel.badgeIcon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLevel.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentLevel.badgeColor,
                      ),
                    ),
                    if (showDetails)
                      Text(
                        currentLevel.description,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (showDetails && !currentLevel.isMaxLevel) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress to next level',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.border.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          currentLevel.badgeColor,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pointsToNext pts',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Recent Achievement Widget
class RecentAchievementWidget extends StatelessWidget {
  const RecentAchievementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardsRepository = RewardsRepository();
    final userRewards = rewardsRepository.currentUserRewards;

    if (userRewards == null || userRewards.unlockedAchievements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get most recent achievement
    final recentAchievement = userRewards.unlockedAchievements.first;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.achievements),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              recentAchievement.rarityColor.withOpacity(0.1),
              recentAchievement.rarityColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: recentAchievement.rarityColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    recentAchievement.rarityColor,
                    recentAchievement.rarityColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recentAchievement.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Latest Achievement',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: recentAchievement.rarityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recentAchievement.rarity
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: AppStyles.caption.copyWith(
                            color: recentAchievement.rarityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recentAchievement.name,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '+${recentAchievement.pointsReward} points',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// Leaderboard Preview Widget
class LeaderboardPreviewWidget extends StatelessWidget {
  const LeaderboardPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardsRepository = RewardsRepository();
    final leaderboard = rewardsRepository.globalLeaderboard.take(3).toList();

    if (leaderboard.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.leaderboard),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Top Gift Givers',
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...leaderboard.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final position = index + 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getPositionColors(position),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getPositionEmoji(position),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.userName.split(' ').first,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${user.totalPoints} pts',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<Color> _getPositionColors(int position) {
    switch (position) {
      case 1:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFD700).withOpacity(0.7),
        ];
      case 2:
        return [
          const Color(0xFFC0C0C0),
          const Color(0xFFC0C0C0).withOpacity(0.7),
        ];
      case 3:
        return [
          const Color(0xFFCD7F32),
          const Color(0xFFCD7F32).withOpacity(0.7),
        ];
      default:
        return [
          AppColors.textSecondary,
          AppColors.textSecondary.withOpacity(0.7),
        ];
    }
  }

  String _getPositionEmoji(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }
}

// Points Animation Widget (for when user earns points)
class PointsEarnedAnimation extends StatefulWidget {
  final int points;
  final String message;
  final VoidCallback? onComplete;

  const PointsEarnedAnimation({
    super.key,
    required this.points,
    required this.message,
    this.onComplete,
  });

  @override
  State<PointsEarnedAnimation> createState() => _PointsEarnedAnimationState();
}

class _PointsEarnedAnimationState extends State<PointsEarnedAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+${widget.points} Points!',
                          style: AppStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.message,
                          style: AppStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Quick Actions for Rewards
class RewardsQuickActions extends StatelessWidget {
  const RewardsQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.emoji_events,
            label: 'Achievements',
            color: AppColors.accent,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.achievements),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.leaderboard,
            label: 'Leaderboard',
            color: AppColors.warning,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.leaderboard),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.store,
            label: 'Store',
            color: AppColors.success,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.rewardsStore),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
