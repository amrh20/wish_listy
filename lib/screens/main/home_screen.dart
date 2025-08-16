import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/rewards_widgets.dart';
import '../../services/localization_service.dart';
import '../../services/rewards_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showWelcomeCard = true;
  final RewardsService _rewardsService = RewardsService();

  // Mock data - replace with real data from your backend
  final List<UpcomingEvent> _upcomingEvents = [
    UpcomingEvent(
      id: '1',
      name: 'Sarah\'s Birthday',
      date: DateTime.now().add(Duration(days: 3)),
      type: 'Birthday',
      hostName: 'Sarah Johnson',
      imageUrl: null,
    ),
    UpcomingEvent(
      id: '2',
      name: 'Wedding Anniversary',
      date: DateTime.now().add(Duration(days: 7)),
      type: 'Anniversary',
      hostName: 'Mike & Lisa',
      imageUrl: null,
    ),
    UpcomingEvent(
      id: '3',
      name: 'Graduation Party',
      date: DateTime.now().add(Duration(days: 12)),
      type: 'Graduation',
      hostName: 'Ahmed Ali',
      imageUrl: null,
    ),
  ];

  final List<FriendActivity> _friendActivities = [
    FriendActivity(
      id: '1',
      friendName: 'Emma Watson',
      action: 'added 3 new items to her wishlist',
      timeAgo: '2 hours ago',
      imageUrl: null,
    ),
    FriendActivity(
      id: '2',
      friendName: 'John Smith',
      action: 'created a new event: "Housewarming Party"',
      timeAgo: '5 hours ago',
      imageUrl: null,
    ),
    FriendActivity(
      id: '3',
      friendName: 'Fatima Al-Zahra',
      action: 'marked an item as received',
      timeAgo: '1 day ago',
      imageUrl: null,
    ),
  ];

  final List<GiftSuggestion> _giftSuggestions = [
    GiftSuggestion(
      id: '1',
      title: 'Smart Watch for Ahmed',
      subtitle: 'Based on his tech wishlist',
      price: '\$299',
      friendName: 'Ahmed',
      imageUrl: null,
    ),
    GiftSuggestion(
      id: '2',
      title: 'Art Supplies for Emma',
      subtitle: 'Perfect for her creative hobby',
      price: '\$45',
      friendName: 'Emma',
      imageUrl: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRewards();
    _startAnimations();
  }

  void _initializeRewards() async {
    // Initialize rewards system for current user
    await _rewardsService.initializeForUser('current_user');
    setState(() {
      // Refresh UI after rewards initialization
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
                  AppColors.primary.withOpacity(0.02),
                  AppColors.secondary.withOpacity(0.01),
                ],
              ),

              // Content
              RefreshIndicator(
                onRefresh: _refreshData,
                color: AppColors.primary,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // App Bar
                    _buildSliverAppBar(localization),

                    // Content
                    SliverToBoxAdapter(
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Welcome Card
                                    if (_showWelcomeCard) ...[
                                      _buildWelcomeCard(localization),
                                      const SizedBox(height: 24),
                                    ],

                                    // Points & Level Display
                                    _buildPointsAndLevel(),
                                    const SizedBox(height: 24),

                                    // Recent Achievement
                                    const RecentAchievementWidget(),
                                    const SizedBox(height: 24),

                                    // Quick Actions
                                    _buildQuickActions(localization),
                                    const SizedBox(height: 24),

                                    // Rewards Quick Actions
                                    _buildRewardsSection(localization),
                                    const SizedBox(height: 32),

                                    // Upcoming Events
                                    _buildUpcomingEvents(localization),
                                    const SizedBox(height: 32),

                                    // Friend Activity
                                    _buildFriendActivity(localization),
                                    const SizedBox(height: 32),

                                    // Gift Suggestions
                                    _buildGiftSuggestions(localization),
                                    const SizedBox(height: 32),

                                    // Leaderboard Preview
                                    const LeaderboardPreviewWidget(),
                                    const SizedBox(
                                      height: 100,
                                    ), // Bottom padding for FAB
                                  ],
                                ),
                              ),
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

  Widget _buildSliverAppBar(LocalizationService localization) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('home.greeting'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Ahmed',
              style: AppStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        // Search Button
        IconButton(
          onPressed: () {
            // Navigate to search screen
          },
          icon: Icon(Icons.search_rounded, color: AppColors.textPrimary),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 8),
        // Smart Reminders Button
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/smart-reminders');
              },
              icon: Icon(Icons.psychology, color: AppColors.textPrimary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.all(12),
              ),
            ),
            // AI Badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1),
                ),
                child: Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Notifications Button
        Stack(
          children: [
            IconButton(
              onPressed: () {
                AppRoutes.pushNamed(context, AppRoutes.notifications);
              },
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.all(12),
              ),
            ),
            // Notification Badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWelcomeCard(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.primaryAccent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.translate('home.welcomeBanner.title'),
                      style: AppStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localization.translate('home.welcomeBanner.description'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showWelcomeCard = false;
                  });
                },
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: localization.translate(
              'home.welcomeBanner.createFirstWishlist',
            ),
            onPressed: () {
              // Navigate to create wishlist
            },
            variant: ButtonVariant.secondary,
            customColor: Colors.white,
            customTextColor: AppColors.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('home.quickActions'),
          style: AppStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            textDirection: TextDirection.ltr, // Force LTR for consistent layout
            children: [
              SizedBox(
                width: 120,
                child: _buildActionCard(
                  icon: Icons.add_circle_outline,
                  title: localization.translate(
                    'home.quickActionsCards.addItem',
                  ),
                  subtitle: localization.translate(
                    'home.quickActionsCards.addItemSubtext',
                  ),
                  color: AppColors.primary,
                  onTap: () {
                    AppRoutes.pushNamed(context, AppRoutes.addItem);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _buildActionCard(
                  icon: Icons.event_outlined,
                  title: localization.translate(
                    'home.quickActionsCards.createEvent',
                  ),
                  subtitle: localization.translate(
                    'home.quickActionsCards.createEventSubtext',
                  ),
                  color: AppColors.accent,
                  onTap: () {
                    AppRoutes.pushNamed(context, AppRoutes.createEvent);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _buildActionCard(
                  icon: Icons.person_add_outlined,
                  title: localization.translate(
                    'home.quickActionsCards.addFriend',
                  ),
                  subtitle: localization.translate(
                    'home.quickActionsCards.addFriendSubtext',
                  ),
                  color: AppColors.success,
                  onTap: () {
                    AppRoutes.pushNamed(context, AppRoutes.friends);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _buildActionCard(
                  icon: Icons.psychology,
                  title: 'Smart\nReminders',
                  subtitle: 'AI suggestions\nfor you',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.pushNamed(context, '/smart-reminders');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.translate('home.upcomingEvents'),
              style: AppStyles.headingSmall,
            ),
            TextButton(
              onPressed: () {
                AppRoutes.pushNamed(context, AppRoutes.events);
              },
              child: Text(
                localization.translate('home.viewAll'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_upcomingEvents.isEmpty)
          _buildEmptyState(
            icon: Icons.event_outlined,
            title: localization.translate('home.noEvents'),
            subtitle: localization.translate('home.noEventsSubtitle'),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = _upcomingEvents[index];
                return _buildEventCard(event);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(UpcomingEvent event) {
    final daysUntil = event.date.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => _openEventDetails(event),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEventDetails(event),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.celebration_outlined,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'by ${event.hostName}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: daysUntil <= 3
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysUntil == 0
                        ? 'Today'
                        : daysUntil == 1
                        ? 'Tomorrow'
                        : 'In $daysUntil days',
                    style: AppStyles.caption.copyWith(
                      color: daysUntil <= 3
                          ? AppColors.warning
                          : AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEventDetails(UpcomingEvent event) {
    AppRoutes.pushNamed(context, AppRoutes.eventDetails, arguments: event);
  }

  Widget _buildFriendActivity(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.translate('home.friendActivity'),
              style: AppStyles.headingSmall,
            ),
            TextButton(
              onPressed: () {
                AppRoutes.pushNamed(context, AppRoutes.friends);
              },
              child: Text(
                localization.translate('home.viewAll'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_friendActivities.isEmpty)
          _buildEmptyState(
            icon: Icons.people_outline,
            title: localization.translate('home.noFriendActivity'),
            subtitle: localization.translate('home.noFriendActivitySubtitle'),
          )
        else
          Column(
            children: _friendActivities.map((activity) {
              return _buildActivityItem(activity);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActivityItem(FriendActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              activity.friendName[0].toUpperCase(),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium,
                    children: [
                      TextSpan(
                        text: activity.friendName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.action}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSuggestions(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gift Suggestions', style: AppStyles.headingSmall),
        const SizedBox(height: 16),
        if (_giftSuggestions.isEmpty)
          _buildEmptyState(
            icon: Icons.card_giftcard_outlined,
            title: 'No suggestions yet',
            subtitle: 'We\'ll suggest gifts based on your friends\' wishlists',
          )
        else
          Column(
            children: _giftSuggestions.map((suggestion) {
              return _buildSuggestionCard(suggestion);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(GiftSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.subtitle,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            suggestion.price,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsAndLevel() {
    return Row(
      children: [
        Expanded(child: const PointsDisplay()),
        const SizedBox(width: 16),
        Expanded(child: const LevelProgressWidget(showDetails: false)),
      ],
    );
  }

  Widget _buildRewardsSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🎮 Rewards & Achievements', style: AppStyles.headingSmall),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.achievements),
              child: Text(
                'View All',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const RewardsQuickActions(),
      ],
    );
  }

  Future<void> _refreshData() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));

    // Refresh rewards data
    _initializeRewards();

    // Refresh your data here
    setState(() {
      // Update data
    });
  }
}

// Mock data models
class UpcomingEvent {
  final String id;
  final String name;
  final DateTime date;
  final String type;
  final String hostName;
  final String? imageUrl;

  UpcomingEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.hostName,
    this.imageUrl,
  });
}

class FriendActivity {
  final String id;
  final String friendName;
  final String action;
  final String timeAgo;
  final String? imageUrl;

  FriendActivity({
    required this.id,
    required this.friendName,
    required this.action,
    required this.timeAgo,
    this.imageUrl,
  });
}

class GiftSuggestion {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final String friendName;
  final String? imageUrl;

  GiftSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.friendName,
    this.imageUrl,
  });
}
