import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../services/rewards_service.dart';
import '../../models/rewards_model.dart';
import '../../widgets/animated_background.dart';

class RewardsStoreScreen extends StatefulWidget {
  const RewardsStoreScreen({super.key});

  @override
  State<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends State<RewardsStoreScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final RewardsService _rewardsService = RewardsService();
  List<Reward> _rewards = [];
  RewardCategory _selectedCategory = RewardCategory.discount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRewards();
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

  void _loadRewards() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _rewards = _rewardsService.allRewards;
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
                  AppColors.success.withOpacity(0.02),
                  AppColors.primary.withOpacity(0.01),
                ],
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(localization),

                    // User Points Balance
                    _buildPointsBalance(),

                    // Category Filter
                    _buildCategoryFilter(),

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
                                  : _buildRewardsContent(localization),
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
                  '🛒 Rewards Store',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Redeem your points for amazing rewards',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Shopping cart icon
          IconButton(
            onPressed: () {
              // Show redemption history
              _showRedemptionHistory(context);
            },
            icon: Icon(Icons.history, color: AppColors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBalance() {
    final userRewards = _rewardsService.currentUserRewards;
    final points = userRewards?.totalPoints ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.stars, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Points Balance',
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points Points',
                  style: AppStyles.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userRewards?.currentLevel.name ?? 'Guest',
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

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: RewardCategory.values.length,
        itemBuilder: (context, index) {
          final category = RewardCategory.values[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          category.color,
                          category.color.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : AppColors.border.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: AppStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                colors: [AppColors.success, AppColors.primary],
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
            '🛒 Loading rewards store...',
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsContent(LocalizationService localization) {
    final filteredRewards = _rewards
        .where((reward) => reward.category == _selectedCategory)
        .toList();

    if (filteredRewards.isEmpty) {
      return _buildEmptyCategory();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredRewards.length,
      itemBuilder: (context, index) {
        return _buildRewardCard(filteredRewards[index]);
      },
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final userPoints = _rewardsService.currentUserRewards?.totalPoints ?? 0;
    final canAfford = userPoints >= reward.pointsCost;
    final canRedeem = reward.canRedeem && canAfford;

    return GestureDetector(
      onTap: () => _showRewardDetails(reward),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canRedeem
                ? reward.categoryColor.withOpacity(0.3)
                : AppColors.border.withOpacity(0.1),
            width: canRedeem ? 2 : 1,
          ),
          boxShadow: [
            if (canRedeem)
              BoxShadow(
                color: reward.categoryColor.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reward Icon and Status
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      reward.categoryColor.withOpacity(0.1),
                      reward.categoryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        reward.icon,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    // Status badges
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        children: [
                          if (reward.isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'EXPIRED',
                                style: AppStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          if (reward.isOutOfStock && !reward.isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'SOLD OUT',
                                style: AppStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          if (reward.quantityLeft != null &&
                              reward.quantityLeft! <= 5 &&
                              reward.quantityLeft! > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${reward.quantityLeft} LEFT',
                                style: AppStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Affordability indicator
                    if (!canAfford)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 10, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                'NEED ${reward.pointsCost - userPoints}',
                                style: AppStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Reward Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      reward.name,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: canRedeem
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Expanded(
                      child: Text(
                        reward.description,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Points cost
                    Row(
                      children: [
                        Icon(
                          Icons.stars,
                          size: 16,
                          color: canAfford
                              ? AppColors.warning
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.pointsCost}',
                          style: AppStyles.bodyMedium.copyWith(
                            color: canAfford
                                ? AppColors.warning
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: reward.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            reward.category
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: AppStyles.caption.copyWith(
                              color: reward.categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedCategory.color.withOpacity(0.1),
                    _selectedCategory.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                _getCategoryIcon(_selectedCategory),
                size: 60,
                color: _selectedCategory.color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_getCategoryName(_selectedCategory)} rewards yet',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new rewards in this category!',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDetails(Reward reward) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RewardDetailsBottomSheet(
        reward: reward,
        rewardsService: _rewardsService,
        onRedeemed: () {
          setState(() {
            // Refresh rewards after redemption
          });
        },
      ),
    );
  }

  void _showRedemptionHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛒 Redemption History'),
        content: const Text('Your redemption history will appear here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper methods

  IconData _getCategoryIcon(RewardCategory category) {
    switch (category) {
      case RewardCategory.discount:
        return Icons.local_offer;
      case RewardCategory.premium:
        return Icons.workspace_premium;
      case RewardCategory.cosmetic:
        return Icons.palette;
      case RewardCategory.feature:
        return Icons.auto_awesome;
      case RewardCategory.gift:
        return Icons.card_giftcard;
    }
  }

  String _getCategoryName(RewardCategory category) {
    switch (category) {
      case RewardCategory.discount:
        return 'Discounts';
      case RewardCategory.premium:
        return 'Premium';
      case RewardCategory.cosmetic:
        return 'Themes';
      case RewardCategory.feature:
        return 'Features';
      case RewardCategory.gift:
        return 'Gifts';
    }
  }
}

// Bottom sheet for reward details
class _RewardDetailsBottomSheet extends StatelessWidget {
  final Reward reward;
  final RewardsService rewardsService;
  final VoidCallback onRedeemed;

  const _RewardDetailsBottomSheet({
    required this.reward,
    required this.rewardsService,
    required this.onRedeemed,
  });

  @override
  Widget build(BuildContext context) {
    final userPoints = rewardsService.currentUserRewards?.totalPoints ?? 0;
    final canAfford = userPoints >= reward.pointsCost;
    final canRedeem = reward.canRedeem && canAfford;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reward Icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            reward.categoryColor.withOpacity(0.2),
                            reward.categoryColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          reward.icon,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reward Name
                  Text(
                    reward.name,
                    style: AppStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    reward.description,
                    style: AppStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Points cost
                  Row(
                    children: [
                      Icon(Icons.stars, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        '${reward.pointsCost} Points',
                        style: AppStyles.headingSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: reward.categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reward.category
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: AppStyles.caption.copyWith(
                            color: reward.categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Terms and conditions
                  if (reward.terms.isNotEmpty) ...[
                    Text(
                      'Terms & Conditions',
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reward.terms
                        .map(
                          (term) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(
                                    top: 8,
                                    right: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    term,
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ],
              ),
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canRedeem ? () => _redeemReward(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem
                      ? reward.categoryColor
                      : AppColors.textTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canRedeem
                      ? 'Redeem for ${reward.pointsCost} Points'
                      : canAfford
                      ? 'Not Available'
                      : 'Need ${reward.pointsCost - userPoints} more points',
                  style: AppStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(BuildContext context) async {
    try {
      await rewardsService.redeemReward(reward.id);

      Navigator.pop(context);
      onRedeemed();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Successfully redeemed ${reward.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Extension for color access
extension RewardCategoryExtension on RewardCategory {
  Color get color {
    switch (this) {
      case RewardCategory.discount:
        return AppColors.success;
      case RewardCategory.premium:
        return AppColors.primary;
      case RewardCategory.cosmetic:
        return AppColors.secondary;
      case RewardCategory.feature:
        return AppColors.accent;
      case RewardCategory.gift:
        return AppColors.warning;
    }
  }
}
