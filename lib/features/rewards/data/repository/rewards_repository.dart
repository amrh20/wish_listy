import 'dart:math';
import 'package:wish_listy/features/rewards/data/models/rewards_model.dart';

/// Rewards Repository
/// Handles all rewards-related operations including:
/// - User rewards management
/// - Achievement tracking
/// - Points calculation
/// - Leaderboard management
class RewardsRepository {
  static final RewardsRepository _instance = RewardsRepository._internal();
  factory RewardsRepository() => _instance;
  RewardsRepository._internal();

  // Current user rewards state
  UserRewards? _currentUserRewards;
  List<Achievement> _allAchievements = [];
  List<Reward> _allRewards = [];
  List<LeaderboardEntry> _globalLeaderboard = [];

  // Getters
  UserRewards? get currentUserRewards => _currentUserRewards;
  List<Achievement> get allAchievements => _allAchievements;
  List<Reward> get allRewards => _allRewards;
  List<LeaderboardEntry> get globalLeaderboard => _globalLeaderboard;

  /// Initialize rewards system for user
  Future<void> initializeForUser(String userId) async {
    // In real app, this would load from backend
    _currentUserRewards = await _loadUserRewards(userId);
    _allAchievements = _loadAllAchievements();
    _allRewards = _loadAllRewards();
    _globalLeaderboard = await _loadGlobalLeaderboard();
  }

  /// Award points for user activity
  Future<UserRewards> awardPointsForActivity({
    required String userId,
    required ActivityType activityType,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (_currentUserRewards == null) {
      await initializeForUser(userId);
    }

    final pointsEarned = PointsRules.calculatePointsForActivity(
      activityType,
      metadata: metadata,
    );

    // Create activity log
    final activity = ActivityLog(
      id: _generateId(),
      userId: userId,
      type: activityType,
      description: _getActivityDescription(activityType, metadata),
      pointsEarned: pointsEarned,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    // Update user rewards
    final newTotalPoints = _currentUserRewards!.totalPoints + pointsEarned;
    final newLevel = UserLevel.getLevelByPoints(newTotalPoints);

    // Check if user leveled up
    final didLevelUp = newLevel.id != _currentUserRewards!.currentLevel.id;

    // Calculate current level points
    final currentLevelPoints = newTotalPoints - newLevel.requiredPoints;

    // Update recent activities
    final updatedActivities = [
      activity,
      ..._currentUserRewards!.recentActivities,
    ].take(50).toList();

    // Check for new achievements
    final newAchievements = await _checkForNewAchievements(
      userId,
      newTotalPoints,
      activityType,
      metadata,
    );

    _currentUserRewards = _currentUserRewards!.copyWith(
      totalPoints: newTotalPoints,
      currentLevelPoints: currentLevelPoints,
      currentLevel: newLevel,
      recentActivities: updatedActivities,
      unlockedAchievements: [
        ..._currentUserRewards!.unlockedAchievements,
        ...newAchievements,
      ],
      lastUpdated: DateTime.now(),
    );

    // Handle level up
    if (didLevelUp) {
      await _handleLevelUp(newLevel);
    }

    // Handle new achievements
    for (final achievement in newAchievements) {
      await _handleAchievementUnlocked(achievement);
    }

    return _currentUserRewards!;
  }

  /// Check for new achievements
  Future<List<Achievement>> _checkForNewAchievements(
    String userId,
    int totalPoints,
    ActivityType activityType,
    Map<String, dynamic> metadata,
  ) async {
    final newAchievements = <Achievement>[];
    final unlockedAchievementIds = _currentUserRewards!.unlockedAchievements
        .map((a) => a.id)
        .toSet();

    for (final achievement in _allAchievements) {
      if (unlockedAchievementIds.contains(achievement.id)) continue;

      if (await _isAchievementUnlocked(
        achievement,
        totalPoints,
        activityType,
        metadata,
      )) {
        newAchievements.add(
          achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            progress: 1.0,
          ),
        );
      }
    }

    return newAchievements;
  }

  /// Check if specific achievement should be unlocked
  Future<bool> _isAchievementUnlocked(
    Achievement achievement,
    int totalPoints,
    ActivityType activityType,
    Map<String, dynamic> metadata,
  ) async {
    // Implementation would check various conditions based on achievement type
    switch (achievement.id) {
      case 'first_gift':
        return activityType == ActivityType.giftSent;
      case 'social_butterfly':
        return activityType == ActivityType.friendAdded &&
            _getUserFriendCount() >= 10;
      case 'gift_master':
        return _getUserGiftsSentCount() >= 50;
      case 'points_collector':
        return totalPoints >= 1000;
      case 'event_planner':
        return _getUserEventsCreatedCount() >= 5;
      case 'week_warrior':
        return activityType == ActivityType.loginStreak &&
            (metadata['streak_days'] ?? 0) >= 7;
      default:
        return false;
    }
  }

  /// Handle level up event
  Future<void> _handleLevelUp(UserLevel newLevel) async {
    // In real app, would trigger notifications/celebrations
    print('🎉 Level Up! Welcome to ${newLevel.name}');
  }

  /// Handle achievement unlocked event
  Future<void> _handleAchievementUnlocked(Achievement achievement) async {
    // Award achievement points
    await awardPointsForActivity(
      userId: _currentUserRewards!.userId,
      activityType: ActivityType.achievementUnlocked,
      metadata: {
        'achievement_id': achievement.id,
        'achievement_name': achievement.name,
        'points_reward': achievement.pointsReward,
      },
    );

    // In real app, would trigger notifications/celebrations
    print('🏆 Achievement Unlocked: ${achievement.name}');
  }

  /// Redeem reward with points
  Future<bool> redeemReward(String rewardId) async {
    final reward = _allRewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => throw Exception('Reward not found'),
    );

    if (!reward.canRedeem) {
      throw Exception('Reward cannot be redeemed');
    }

    if (_currentUserRewards!.totalPoints < reward.pointsCost) {
      throw Exception('Insufficient points');
    }

    // Deduct points
    final newTotalPoints = _currentUserRewards!.totalPoints - reward.pointsCost;
    final newLevel = UserLevel.getLevelByPoints(newTotalPoints);
    final currentLevelPoints = newTotalPoints - newLevel.requiredPoints;

    _currentUserRewards = _currentUserRewards!.copyWith(
      totalPoints: newTotalPoints,
      currentLevelPoints: currentLevelPoints,
      currentLevel: newLevel,
      lastUpdated: DateTime.now(),
    );

    // Log redemption activity
    final activity = ActivityLog(
      id: _generateId(),
      userId: _currentUserRewards!.userId,
      type: ActivityType.giftReceived, // Using as redemption type
      description: 'Redeemed ${reward.name}',
      pointsEarned: -reward.pointsCost,
      timestamp: DateTime.now(),
      metadata: {'reward_id': rewardId, 'reward_name': reward.name},
    );

    final updatedActivities = [
      activity,
      ..._currentUserRewards!.recentActivities,
    ].take(50).toList();

    _currentUserRewards = _currentUserRewards!.copyWith(
      recentActivities: updatedActivities,
    );

    return true;
  }

  /// Get user's rank in global leaderboard
  int getUserRank(String userId) {
    final index = _globalLeaderboard.indexWhere(
      (entry) => entry.userId == userId,
    );
    return index != -1 ? index + 1 : -1;
  }

  /// Get friends leaderboard
  List<LeaderboardEntry> getFriendsLeaderboard(List<String> friendIds) {
    return _globalLeaderboard
        .where((entry) => friendIds.contains(entry.userId))
        .toList();
  }

  // Mock data loaders (in real app, these would call backend APIs)

  Future<UserRewards> _loadUserRewards(String userId) async {
    // Mock user rewards data
    return UserRewards(
      userId: userId,
      totalPoints: 250,
      currentLevelPoints: 150,
      currentLevel: UserLevel.silver,
      unlockedAchievements: [
        _loadAllAchievements().first.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      availableRewards: _loadAllRewards().take(5).toList(),
      recentActivities: _generateMockActivities(userId),
      lastUpdated: DateTime.now(),
    );
  }

  List<Achievement> _loadAllAchievements() {
    return [
      Achievement(
        id: 'first_gift',
        name: 'First Gift',
        description: 'Send your first gift to a friend',
        icon: '🎁',
        category: AchievementCategory.gifting,
        pointsReward: 50,
        rarity: AchievementRarity.common,
        targetValue: 1,
      ),
      Achievement(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Add 10 friends to your network',
        icon: '🦋',
        category: AchievementCategory.social,
        pointsReward: 100,
        rarity: AchievementRarity.rare,
        targetValue: 10,
      ),
      Achievement(
        id: 'gift_master',
        name: 'Gift Master',
        description: 'Send 50 gifts to friends',
        icon: '🎯',
        category: AchievementCategory.gifting,
        pointsReward: 500,
        rarity: AchievementRarity.epic,
        targetValue: 50,
      ),
      Achievement(
        id: 'points_collector',
        name: 'Points Collector',
        description: 'Earn 1000 total points',
        icon: '💎',
        category: AchievementCategory.milestones,
        pointsReward: 200,
        rarity: AchievementRarity.rare,
        targetValue: 1000,
      ),
      Achievement(
        id: 'event_planner',
        name: 'Event Planner',
        description: 'Create 5 events for friends',
        icon: '🎪',
        category: AchievementCategory.events,
        pointsReward: 150,
        rarity: AchievementRarity.rare,
        targetValue: 5,
      ),
      Achievement(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Login for 7 consecutive days',
        icon: '🔥',
        category: AchievementCategory.general,
        pointsReward: 100,
        rarity: AchievementRarity.common,
        targetValue: 7,
      ),
      Achievement(
        id: 'wishlist_creator',
        name: 'Wishlist Creator',
        description: 'Create 10 wishlists',
        icon: '📝',
        category: AchievementCategory.shopping,
        pointsReward: 75,
        rarity: AchievementRarity.common,
        targetValue: 10,
      ),
      Achievement(
        id: 'generous_giver',
        name: 'Generous Giver',
        description: 'Give gifts worth over 500 dollars',
        icon: '💝',
        category: AchievementCategory.gifting,
        pointsReward: 300,
        rarity: AchievementRarity.epic,
        targetValue: 500,
      ),
      Achievement(
        id: 'party_host',
        name: 'Party Host',
        description: 'Host 3 successful events',
        icon: '🎉',
        category: AchievementCategory.events,
        pointsReward: 200,
        rarity: AchievementRarity.rare,
        targetValue: 3,
      ),
      Achievement(
        id: 'legendary_friend',
        name: 'Legendary Friend',
        description: 'Be someone\'s top gift giver for a year',
        icon: '👑',
        category: AchievementCategory.social,
        pointsReward: 1000,
        rarity: AchievementRarity.legendary,
        targetValue: 1,
      ),
    ];
  }

  List<Reward> _loadAllRewards() {
    return [
      Reward(
        id: 'discount_10',
        name: '10% Discount',
        description: 'Get 10% off your next purchase',
        icon: '🏷️',
        type: RewardType.discount,
        pointsCost: 100,
        category: RewardCategory.discount,
        terms: ['Valid for 30 days', 'Cannot be combined with other offers'],
      ),
      Reward(
        id: 'premium_1month',
        name: '1 Month Premium',
        description: 'Unlock premium features for 1 month',
        icon: '⭐',
        type: RewardType.premiumFeature,
        pointsCost: 500,
        category: RewardCategory.premium,
        terms: ['Auto-renewal disabled', 'Full premium access'],
      ),
      Reward(
        id: 'custom_theme',
        name: 'Custom Theme',
        description: 'Unlock exclusive app themes',
        icon: '🎨',
        type: RewardType.customization,
        pointsCost: 200,
        category: RewardCategory.cosmetic,
        terms: ['Permanent unlock', 'Choose from 5 themes'],
      ),
      Reward(
        id: 'virtual_gift',
        name: 'Virtual Gift Box',
        description: 'Send a special virtual gift to friends',
        icon: '🎁',
        type: RewardType.virtualGift,
        pointsCost: 150,
        category: RewardCategory.gift,
        terms: ['One-time use', 'Friend gets notification'],
      ),
      Reward(
        id: 'gift_card_25',
        name: '25 Dollar Gift Card',
        description: 'Amazon gift card worth 25 dollars',
        icon: '💳',
        type: RewardType.realGift,
        pointsCost: 2500,
        category: RewardCategory.gift,
        quantity: 10,
        quantityLeft: 3,
        terms: ['Digital delivery', 'Valid for 1 year', 'US only'],
      ),
      Reward(
        id: 'priority_support',
        name: 'Priority Support',
        description: 'Get priority customer support for 3 months',
        icon: '🎧',
        type: RewardType.premiumFeature,
        pointsCost: 300,
        category: RewardCategory.feature,
        terms: ['3 months duration', '24/7 support access'],
      ),
      Reward(
        id: 'badge_collection',
        name: 'Exclusive Badges',
        description: 'Unlock limited edition profile badges',
        icon: '🏅',
        type: RewardType.customization,
        pointsCost: 400,
        category: RewardCategory.cosmetic,
        terms: ['5 exclusive badges', 'Show on profile'],
      ),
      Reward(
        id: 'discount_25',
        name: '25% Discount',
        description: 'Get 25% off your next purchase',
        icon: '🔥',
        type: RewardType.discount,
        pointsCost: 250,
        category: RewardCategory.discount,
        terms: ['Valid for 14 days', 'Minimum purchase 50 dollars'],
      ),
    ];
  }

  Future<List<LeaderboardEntry>> _loadGlobalLeaderboard() async {
    // Mock leaderboard data
    final random = Random();
    return List.generate(50, (index) {
      final points = 5000 - (index * 50) + random.nextInt(50);
      return LeaderboardEntry(
        userId: 'user_$index',
        userName: _generateMockUserName(),
        totalPoints: points,
        currentLevel: UserLevel.getLevelByPoints(points),
        rank: index + 1,
        giftsGiven: random.nextInt(100),
        giftsReceived: random.nextInt(80),
        topAchievements: _loadAllAchievements()
            .where((a) => random.nextBool())
            .take(3)
            .toList(),
      );
    });
  }

  List<ActivityLog> _generateMockActivities(String userId) {
    final activities = <ActivityLog>[];
    final types = ActivityType.values;
    final random = Random();

    for (int i = 0; i < 20; i++) {
      final type = types[random.nextInt(types.length)];
      final timestamp = DateTime.now().subtract(Duration(hours: i * 2));

      activities.add(
        ActivityLog(
          id: _generateId(),
          userId: userId,
          type: type,
          description: _getActivityDescription(type, {}),
          pointsEarned: PointsRules.calculatePointsForActivity(type),
          timestamp: timestamp,
        ),
      );
    }

    return activities;
  }

  // Helper methods

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  String _getActivityDescription(
    ActivityType type,
    Map<String, dynamic> metadata,
  ) {
    switch (type) {
      case ActivityType.giftSent:
        return 'Sent a gift to ${metadata['friend_name'] ?? 'a friend'}';
      case ActivityType.giftReceived:
        return 'Received a gift from ${metadata['friend_name'] ?? 'a friend'}';
      case ActivityType.wishlistCreated:
        return 'Created a new wishlist';
      case ActivityType.friendAdded:
        return 'Added a new friend';
      case ActivityType.eventCreated:
        return 'Created a new event';
      case ActivityType.achievementUnlocked:
        return 'Unlocked achievement: ${metadata['achievement_name'] ?? 'Unknown'}';
      case ActivityType.levelUp:
        return 'Leveled up to ${metadata['level'] ?? 'new level'}!';
      case ActivityType.loginStreak:
        final days = metadata['streak_days'] ?? 1;
        return 'Login streak: $days days';
      case ActivityType.profileCompleted:
        return 'Completed profile setup';
      case ActivityType.reviewLeft:
        return 'Left a review for a gift';
    }
  }

  String _generateMockUserName() {
    final firstNames = [
      'Ahmed',
      'Fatima',
      'Omar',
      'Aisha',
      'Khalid',
      'Zeinab',
      'Hassan',
      'Nour',
    ];
    final lastNames = [
      'Ali',
      'Hassan',
      'Mohamed',
      'Ahmad',
      'Farouk',
      'Mansour',
      'Salem',
      'Nasser',
    ];
    final random = Random();

    return '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}';
  }

  // Mock user statistics (in real app, would come from database)
  int _getUserFriendCount() => Random().nextInt(20) + 5;
  int _getUserGiftsSentCount() => Random().nextInt(100);
  int _getUserEventsCreatedCount() => Random().nextInt(10);
}
