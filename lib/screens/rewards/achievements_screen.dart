import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../services/rewards_service.dart';
import '../../models/rewards_model.dart';
import '../../widgets/animated_background.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final RewardsService _rewardsService = RewardsService();
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAchievements();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  void _loadAchievements() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _achievements = _rewardsService.allAchievements;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Animated Background
              AnimatedBackground(
                colors: [
                  AppColors.background,
                  AppColors.accent.withOpacity(0.02),
                  AppColors.secondary.withOpacity(0.01),
                ],
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(localization),

                    // Content
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _isLoading
                                  ? _buildLoadingState()
                                  : _buildAchievementsContent(localization),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 Achievements',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your collection of accomplishments',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          if (_rewardsService.currentUserRewards != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_rewardsService.currentUserRewards!.unlockedAchievements.length}/${_achievements.length}',
                style: AppStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🏆 Loading your achievements...',
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsContent(LocalizationService localization) {
    final unlockedAchievements = _achievements
        .where((a) => a.isUnlocked)
        .toList();
    final lockedAchievements = _achievements
        .where((a) => !a.isUnlocked)
        .toList();

    return CustomScrollView(
      slivers: [
        // Stats Overview
        SliverToBoxAdapter(child: _buildStatsOverview()),

        // Unlocked Achievements
        if (unlockedAchievements.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              '🌟 Unlocked',
              'Your earned achievements',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildAchievementCard(
                  unlockedAchievements[index],
                  isUnlocked: true,
                );
              }, childCount: unlockedAchievements.length),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Locked Achievements
        if (lockedAchievements.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader('🔒 Locked', 'Achievements to unlock'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildAchievementCard(
                  lockedAchievements[index],
                  isUnlocked: false,
                );
              }, childCount: lockedAchievements.length),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatsOverview() {
    final userRewards = _rewardsService.currentUserRewards;
    if (userRewards == null) return const SizedBox.shrink();

    final unlockedCount = userRewards.unlockedAchievements.length;
    final totalCount = _achievements.length;
    final completionRate = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement Progress',
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlockedCount of $totalCount unlocked',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(completionRate * 100).round()}%',
                style: AppStyles.headingSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionRate,
            backgroundColor: AppColors.border.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement, {
    required bool isUnlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? achievement.rarityColor.withOpacity(0.3)
              : AppColors.border.withOpacity(0.1),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: achievement.rarityColor.withOpacity(0.15),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Achievement Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          achievement.rarityColor,
                          achievement.rarityColor.withOpacity(0.7),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.textTertiary,
                          AppColors.textTertiary.withOpacity(0.7),
                        ],
                      ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Achievement Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.name,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: achievement.rarityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            achievement.rarity
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: AppStyles.caption.copyWith(
                              color: achievement.rarityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.pointsReward} points',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isUnlocked && achievement.unlockedAt != null) ...[
                        const Spacer(),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatUnlockedDate(achievement.unlockedAt!),
                          style: AppStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isUnlocked && achievement.progress > 0) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: ${achievement.currentValue}/${achievement.targetValue}',
                          style: AppStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: achievement.progress,
                          backgroundColor: AppColors.border.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUnlockedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      return '${difference ~/ 7} weeks ago';
    } else {
      return '${difference ~/ 30} months ago';
    }
  }
}
