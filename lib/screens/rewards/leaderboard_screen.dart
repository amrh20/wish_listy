import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../services/rewards_service.dart';
import '../../models/rewards_model.dart';
import '../../widgets/animated_background.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  final RewardsService _rewardsService = RewardsService();
  List<LeaderboardEntry> _globalLeaderboard = [];
  List<LeaderboardEntry> _friendsLeaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadLeaderboards();
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

  void _loadLeaderboards() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _globalLeaderboard = _rewardsService.globalLeaderboard;
      // Mock friends leaderboard (subset of global)
      _friendsLeaderboard = _globalLeaderboard.take(10).toList();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
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
                  AppColors.warning.withOpacity(0.02),
                  AppColors.accent.withOpacity(0.01),
                ],
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(localization),

                    // Tabs
                    _buildTabs(),

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
                                  : _buildLeaderboardContent(),
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
                  '🏆 Leaderboard',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'See who\'s the ultimate gift giver',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Current user rank
          if (_rewardsService.currentUserRewards != null)
            Container(
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
                  Icon(Icons.emoji_events, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Rank #${_getCurrentUserRank()}',
                    style: AppStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '🌍 Global'),
          Tab(text: '👥 Friends'),
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
                colors: [AppColors.warning, AppColors.accent],
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
            '🏆 Loading leaderboard...',
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeaderboardList(_globalLeaderboard, isGlobal: true),
        _buildLeaderboardList(_friendsLeaderboard, isGlobal: false),
      ],
    );
  }

  Widget _buildLeaderboardList(
    List<LeaderboardEntry> entries, {
    required bool isGlobal,
  }) {
    if (entries.isEmpty) {
      return _buildEmptyState(isGlobal);
    }

    return CustomScrollView(
      slivers: [
        // Top 3 Podium
        if (entries.length >= 3)
          SliverToBoxAdapter(child: _buildPodium(entries.take(3).toList())),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Rest of the leaderboard
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entryIndex = entries.length >= 3 ? index + 3 : index;
                if (entryIndex >= entries.length) return null;
                return _buildLeaderboardEntry(entries[entryIndex], entryIndex);
              },
              childCount: entries.length >= 3
                  ? entries.length - 3
                  : entries.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.warning.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place
          if (topThree.length > 1)
            _buildPodiumPosition(topThree[1], 2, height: 60),

          // First place
          _buildPodiumPosition(topThree[0], 1, height: 75),

          // Third place
          if (topThree.length > 2)
            _buildPodiumPosition(topThree[2], 3, height: 45),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    LeaderboardEntry entry,
    int position, {
    required double height,
  }) {
    Color positionColor;
    String positionIcon;

    switch (position) {
      case 1:
        positionColor = const Color(0xFFFFD700); // Gold
        positionIcon = '🥇';
        break;
      case 2:
        positionColor = const Color(0xFFC0C0C0); // Silver
        positionIcon = '🥈';
        break;
      case 3:
        positionColor = const Color(0xFFCD7F32); // Bronze
        positionIcon = '🥉';
        break;
      default:
        positionColor = AppColors.textSecondary;
        positionIcon = '🏅';
    }

    return Column(
      children: [
        // User avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [positionColor, positionColor.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: positionColor, width: 2),
          ),
          child: Center(
            child: Text(
              entry.userName.substring(0, 1).toUpperCase(),
              style: AppStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // User name
        Text(
          entry.userName.split(' ').first,
          style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Points
        Text(
          '${entry.totalPoints} pts',
          style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),

        // Podium base
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                positionColor.withOpacity(0.3),
                positionColor.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: positionColor.withOpacity(0.5)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(positionIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  '#$position',
                  style: AppStyles.bodyMedium.copyWith(
                    color: positionColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final isCurrentUser = entry.userId == 'current_user'; // Mock check

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textSecondary.withOpacity(0.2),
                  AppColors.textSecondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  entry.currentLevel.badgeColor,
                  entry.currentLevel.badgeColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                entry.userName.substring(0, 1).toUpperCase(),
                style: AppStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.userName,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      entry.currentLevel.badgeIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.stars, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.totalPoints} points',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.card_giftcard,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.giftsGiven} gifts',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: entry.currentLevel.badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.currentLevel.name.split(' ').last,
              style: AppStyles.caption.copyWith(
                color: entry.currentLevel.badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isGlobal) {
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
                    AppColors.textTertiary.withOpacity(0.1),
                    AppColors.textTertiary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                isGlobal ? Icons.public : Icons.group,
                size: 60,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isGlobal ? 'No global rankings yet' : 'No friends on leaderboard',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isGlobal
                  ? 'Be the first to earn points and climb the ranks!'
                  : 'Invite friends to join and compete together!',
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

  int _getCurrentUserRank() {
    // Mock current user rank
    return 15;
  }
}
