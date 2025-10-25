import 'package:flutter/material.dart';

// User Points and Level System
class UserRewards {
  final String userId;
  final int totalPoints;
  final int currentLevelPoints;
  final UserLevel currentLevel;
  final List<Achievement> unlockedAchievements;
  final List<Reward> availableRewards;
  final List<ActivityLog> recentActivities;
  final DateTime lastUpdated;

  UserRewards({
    required this.userId,
    required this.totalPoints,
    required this.currentLevelPoints,
    required this.currentLevel,
    required this.unlockedAchievements,
    required this.availableRewards,
    required this.recentActivities,
    required this.lastUpdated,
  });

  // Calculate progress to next level
  double get progressToNextLevel {
    if (currentLevel.isMaxLevel) return 1.0;
    final nextLevel = UserLevel.getNextLevel(currentLevel);
    final pointsNeeded = nextLevel.requiredPoints - currentLevel.requiredPoints;
    final currentProgress = currentLevelPoints;
    return (currentProgress / pointsNeeded).clamp(0.0, 1.0);
  }

  int get pointsToNextLevel {
    if (currentLevel.isMaxLevel) return 0;
    final nextLevel = UserLevel.getNextLevel(currentLevel);
    return nextLevel.requiredPoints - totalPoints;
  }

  factory UserRewards.fromJson(Map<String, dynamic> json) {
    return UserRewards(
      userId: json['user_id'] ?? '',
      totalPoints: json['total_points'] ?? 0,
      currentLevelPoints: json['current_level_points'] ?? 0,
      currentLevel: UserLevel.fromJson(json['current_level'] ?? {}),
      unlockedAchievements:
          (json['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
      availableRewards:
          (json['available_rewards'] as List<dynamic>?)
              ?.map((r) => Reward.fromJson(r))
              .toList() ??
          [],
      recentActivities:
          (json['recent_activities'] as List<dynamic>?)
              ?.map((a) => ActivityLog.fromJson(a))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'current_level_points': currentLevelPoints,
      'current_level': currentLevel.toJson(),
      'achievements': unlockedAchievements.map((a) => a.toJson()).toList(),
      'available_rewards': availableRewards.map((r) => r.toJson()).toList(),
      'recent_activities': recentActivities.map((a) => a.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  UserRewards copyWith({
    String? userId,
    int? totalPoints,
    int? currentLevelPoints,
    UserLevel? currentLevel,
    List<Achievement>? unlockedAchievements,
    List<Reward>? availableRewards,
    List<ActivityLog>? recentActivities,
    DateTime? lastUpdated,
  }) {
    return UserRewards(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevelPoints: currentLevelPoints ?? this.currentLevelPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      availableRewards: availableRewards ?? this.availableRewards,
      recentActivities: recentActivities ?? this.recentActivities,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// User Level System
class UserLevel {
  final String id;
  final String name;
  final String description;
  final int requiredPoints;
  final String badgeIcon;
  final Color badgeColor;
  final List<String> perks;
  final bool isMaxLevel;

  const UserLevel({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredPoints,
    required this.badgeIcon,
    required this.badgeColor,
    required this.perks,
    this.isMaxLevel = false,
  });

  // Predefined levels
  static const UserLevel bronze = UserLevel(
    id: 'bronze',
    name: 'Gift Starter',
    description: 'Welcome to the gift-giving journey!',
    requiredPoints: 0,
    badgeIcon: '🥉',
    badgeColor: Color(0xFFCD7F32),
    perks: ['Basic features access', 'Standard support'],
  );

  static const UserLevel silver = UserLevel(
    id: 'silver',
    name: 'Gift Enthusiast',
    description: 'You\'re getting the hang of thoughtful gifting!',
    requiredPoints: 100,
    badgeIcon: '🥈',
    badgeColor: Color(0xFFC0C0C0),
    perks: [
      'Priority notifications',
      'Early access to features',
      '5% discount on premium',
    ],
  );

  static const UserLevel gold = UserLevel(
    id: 'gold',
    name: 'Gift Master',
    description: 'A true connoisseur of gift-giving!',
    requiredPoints: 500,
    badgeIcon: '🥇',
    badgeColor: Color(0xFFFFD700),
    perks: [
      'Premium features access',
      '10% discount',
      'Personal gift consultant',
    ],
  );

  static const UserLevel platinum = UserLevel(
    id: 'platinum',
    name: 'Gift Legend',
    description: 'The ultimate gift-giving champion!',
    requiredPoints: 1500,
    badgeIcon: '💎',
    badgeColor: Color(0xFFE5E4E2),
    perks: [
      'All premium features',
      '20% discount',
      'VIP support',
      'Exclusive events',
    ],
    isMaxLevel: true,
  );

  static const UserLevel diamond = UserLevel(
    id: 'diamond',
    name: 'Gift Deity',
    description: 'You have transcended mere mortal gift-giving!',
    requiredPoints: 5000,
    badgeIcon: '💠',
    badgeColor: Color(0xFF75D5FD),
    perks: [
      'Unlimited everything',
      '50% discount',
      'Personal concierge',
      'Beta access',
    ],
    isMaxLevel: true,
  );

  static List<UserLevel> get allLevels => [
    bronze,
    silver,
    gold,
    platinum,
    diamond,
  ];

  static UserLevel getLevelByPoints(int points) {
    final sortedLevels = allLevels.reversed.toList();
    return sortedLevels.firstWhere(
      (level) => points >= level.requiredPoints,
      orElse: () => bronze,
    );
  }

  static UserLevel getNextLevel(UserLevel currentLevel) {
    final currentIndex = allLevels.indexWhere((l) => l.id == currentLevel.id);
    if (currentIndex == -1 || currentIndex >= allLevels.length - 1) {
      return currentLevel; // Max level reached
    }
    return allLevels[currentIndex + 1];
  }

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? 'bronze';
    return allLevels.firstWhere(
      (level) => level.id == id,
      orElse: () => bronze,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'required_points': requiredPoints,
      'badge_icon': badgeIcon,
      'perks': perks,
      'is_max_level': isMaxLevel,
    };
  }
}

// Achievement System
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final int pointsReward;
  final AchievementRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;
  final int targetValue;
  final int currentValue;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.pointsReward,
    required this.rarity,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    required this.targetValue,
    this.currentValue = 0,
  });

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF9E9E9E);
      case AchievementRarity.rare:
        return const Color(0xFF4CAF50);
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0);
      case AchievementRarity.legendary:
        return const Color(0xFFFF9800);
      case AchievementRarity.mythic:
        return const Color(0xFFE91E63);
    }
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      category: AchievementCategory.values.firstWhere(
        (c) => c.toString().split('.').last == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      pointsReward: json['points_reward'] ?? 0,
      rarity: AchievementRarity.values.firstWhere(
        (r) => r.toString().split('.').last == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'])
          : null,
      progress: (json['progress'] ?? 0.0).toDouble(),
      targetValue: json['target_value'] ?? 1,
      currentValue: json['current_value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category.toString().split('.').last,
      'points_reward': pointsReward,
      'rarity': rarity.toString().split('.').last,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'progress': progress,
      'target_value': targetValue,
      'current_value': currentValue,
    };
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementCategory? category,
    int? pointsReward,
    AchievementRarity? rarity,
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
    int? targetValue,
    int? currentValue,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      pointsReward: pointsReward ?? this.pointsReward,
      rarity: rarity ?? this.rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

enum AchievementCategory {
  general,
  gifting,
  social,
  events,
  shopping,
  milestones,
}

enum AchievementRarity { common, rare, epic, legendary, mythic }

// Points Activity System
class ActivityLog {
  final String id;
  final String userId;
  final ActivityType type;
  final String description;
  final int pointsEarned;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.pointsEarned,
    required this.timestamp,
    this.metadata = const {},
  });

  String get activityIcon {
    switch (type) {
      case ActivityType.giftSent:
        return '🎁';
      case ActivityType.giftReceived:
        return '📦';
      case ActivityType.wishlistCreated:
        return '📝';
      case ActivityType.friendAdded:
        return '👥';
      case ActivityType.eventCreated:
        return '🎉';
      case ActivityType.achievementUnlocked:
        return '🏆';
      case ActivityType.levelUp:
        return '⬆️';
      case ActivityType.loginStreak:
        return '🔥';
      case ActivityType.profileCompleted:
        return '✅';
      case ActivityType.reviewLeft:
        return '⭐';
    }
  }

  Color get activityColor {
    switch (type) {
      case ActivityType.giftSent:
      case ActivityType.giftReceived:
        return const Color(0xFF4CAF50);
      case ActivityType.achievementUnlocked:
      case ActivityType.levelUp:
        return const Color(0xFFFF9800);
      case ActivityType.friendAdded:
      case ActivityType.eventCreated:
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: ActivityType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => ActivityType.giftSent,
      ),
      description: json['description'] ?? '',
      pointsEarned: json['points_earned'] ?? 0,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'description': description,
      'points_earned': pointsEarned,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum ActivityType {
  giftSent,
  giftReceived,
  wishlistCreated,
  friendAdded,
  eventCreated,
  achievementUnlocked,
  levelUp,
  loginStreak,
  profileCompleted,
  reviewLeft,
}

// Rewards Store System
class Reward {
  final String id;
  final String name;
  final String description;
  final String icon;
  final RewardType type;
  final int pointsCost;
  final RewardCategory category;
  final bool isAvailable;
  final DateTime? expiresAt;
  final int? quantity;
  final int? quantityLeft;
  final List<String> terms;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.pointsCost,
    required this.category,
    this.isAvailable = true,
    this.expiresAt,
    this.quantity,
    this.quantityLeft,
    this.terms = const [],
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isOutOfStock => quantityLeft != null && quantityLeft! <= 0;
  bool get canRedeem => isAvailable && !isExpired && !isOutOfStock;

  Color get categoryColor {
    switch (category) {
      case RewardCategory.discount:
        return const Color(0xFF4CAF50);
      case RewardCategory.premium:
        return const Color(0xFF9C27B0);
      case RewardCategory.cosmetic:
        return const Color(0xFF2196F3);
      case RewardCategory.feature:
        return const Color(0xFFFF9800);
      case RewardCategory.gift:
        return const Color(0xFFE91E63);
    }
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🎁',
      type: RewardType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => RewardType.discount,
      ),
      pointsCost: json['points_cost'] ?? 0,
      category: RewardCategory.values.firstWhere(
        (c) => c.toString().split('.').last == json['category'],
        orElse: () => RewardCategory.discount,
      ),
      isAvailable: json['is_available'] ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      quantity: json['quantity'],
      quantityLeft: json['quantity_left'],
      terms: List<String>.from(json['terms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.toString().split('.').last,
      'points_cost': pointsCost,
      'category': category.toString().split('.').last,
      'is_available': isAvailable,
      'expires_at': expiresAt?.toIso8601String(),
      'quantity': quantity,
      'quantity_left': quantityLeft,
      'terms': terms,
    };
  }
}

enum RewardType {
  discount,
  premiumFeature,
  customization,
  virtualGift,
  realGift,
}

enum RewardCategory { discount, premium, cosmetic, feature, gift }

// Leaderboard System
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int totalPoints;
  final UserLevel currentLevel;
  final int rank;
  final int giftsGiven;
  final int giftsReceived;
  final List<Achievement> topAchievements;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.totalPoints,
    required this.currentLevel,
    required this.rank,
    required this.giftsGiven,
    required this.giftsReceived,
    this.topAchievements = const [],
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'],
      totalPoints: json['total_points'] ?? 0,
      currentLevel: UserLevel.fromJson(json['current_level'] ?? {}),
      rank: json['rank'] ?? 0,
      giftsGiven: json['gifts_given'] ?? 0,
      giftsReceived: json['gifts_received'] ?? 0,
      topAchievements:
          (json['top_achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'total_points': totalPoints,
      'current_level': currentLevel.toJson(),
      'rank': rank,
      'gifts_given': giftsGiven,
      'gifts_received': giftsReceived,
      'top_achievements': topAchievements.map((a) => a.toJson()).toList(),
    };
  }
}

// Points calculation rules
class PointsRules {
  static const int giftSent = 20;
  static const int giftReceived = 10;
  static const int wishlistCreated = 5;
  static const int friendAdded = 15;
  static const int eventCreated = 25;
  static const int profileCompleted = 30;
  static const int dailyLogin = 5;
  static const int weeklyLoginStreak = 50;
  static const int reviewLeft = 10;
  static const int photoUploaded = 5;
  static const int eventAttended = 15;
  static const int wishlistShared = 10;

  static int calculatePointsForActivity(
    ActivityType type, {
    Map<String, dynamic>? metadata,
  }) {
    switch (type) {
      case ActivityType.giftSent:
        return giftSent;
      case ActivityType.giftReceived:
        return giftReceived;
      case ActivityType.wishlistCreated:
        return wishlistCreated;
      case ActivityType.friendAdded:
        return friendAdded;
      case ActivityType.eventCreated:
        return eventCreated;
      case ActivityType.profileCompleted:
        return profileCompleted;
      case ActivityType.loginStreak:
        final days = metadata?['streak_days'] ?? 1;
        return days * dailyLogin + (days >= 7 ? weeklyLoginStreak : 0);
      case ActivityType.reviewLeft:
        return reviewLeft;
      default:
        return 0;
    }
  }
}
