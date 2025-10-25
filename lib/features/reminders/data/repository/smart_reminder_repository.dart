import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/auth/data/models/user_model.dart';
import 'package:wish_listy/features/wishlists/data/models/wish.dart';

/// Smart Reminder Repository
/// Handles AI-powered reminder suggestions and smart notifications
class SmartReminderRepository {
  static final SmartReminderRepository _instance =
      SmartReminderRepository._internal();
  factory SmartReminderRepository() => _instance;
  SmartReminderRepository._internal();

  // AI-powered reminder suggestions
  List<SmartReminder> generateSmartReminders(
    List<EventSummary> events,
    List<Wish> friendWishes,
    UserProfile userProfile,
  ) {
    List<SmartReminder> reminders = [];

    // 1. Event-based reminders with AI timing
    for (var event in events) {
      reminders.addAll(_generateEventReminders(event, userProfile));
    }

    // 2. Friend birthday reminders with gift suggestions
    reminders.addAll(_generateBirthdayReminders(friendWishes, userProfile));

    // 3. Seasonal and trending gift reminders
    reminders.addAll(_generateSeasonalReminders(userProfile));

    // 4. Budget and savings reminders
    reminders.addAll(_generateBudgetReminders(userProfile));

    // Sort by AI priority score
    reminders.sort((a, b) => b.aiPriorityScore.compareTo(a.aiPriorityScore));

    return reminders;
  }

  List<SmartReminder> _generateEventReminders(
    EventSummary event,
    UserProfile userProfile,
  ) {
    List<SmartReminder> reminders = [];
    final daysUntilEvent = event.date.difference(DateTime.now()).inDays;

    if (daysUntilEvent <= 0) return reminders;

    // AI decides optimal reminder timing based on user behavior
    List<int> reminderDays = _calculateOptimalReminderDays(
      daysUntilEvent,
      userProfile.behaviorPattern,
      event.type,
    );

    for (int reminderDay in reminderDays) {
      if (reminderDay > 0) {
        reminders.add(
          SmartReminder(
            id: '${event.id}_$reminderDay',
            type: ReminderType.eventPreparation,
            title: _generateEventReminderTitle(event, reminderDay),
            description: _generateEventReminderDescription(event, reminderDay),
            scheduledDate: event.date.subtract(Duration(days: reminderDay)),
            relatedEventId: event.id,
            aiPriorityScore: _calculatePriority(
              reminderDay,
              event.type,
              userProfile,
            ),
            aiSuggestions: _generateEventSuggestions(event, reminderDay),
          ),
        );
      }
    }

    return reminders;
  }

  List<SmartReminder> _generateBirthdayReminders(
    List<Wish> friendWishes,
    UserProfile userProfile,
  ) {
    List<SmartReminder> reminders = [];

    // Simulate friend birthdays (in real app, this would come from friends data)
    List<FriendBirthday> upcomingBirthdays = _getUpcomingBirthdays();

    for (var birthday in upcomingBirthdays) {
      final daysUntil = birthday.date.difference(DateTime.now()).inDays;

      if (daysUntil > 0 && daysUntil <= 30) {
        // AI suggests optimal reminder timing
        int reminderDay = _calculateBirthdayReminderDay(daysUntil, userProfile);

        reminders.add(
          SmartReminder(
            id: 'birthday_${birthday.friendId}_$reminderDay',
            type: ReminderType.friendBirthday,
            title: '🎂 ${birthday.friendName}\'s Birthday Coming Up!',
            description: _generateBirthdayReminderDescription(
              birthday,
              daysUntil,
            ),
            scheduledDate: birthday.date.subtract(Duration(days: reminderDay)),
            relatedFriendId: birthday.friendId,
            aiPriorityScore: _calculateBirthdayPriority(
              daysUntil,
              birthday.closeness,
            ),
            aiSuggestions: _generateBirthdayGiftSuggestions(
              birthday,
              friendWishes,
            ),
          ),
        );
      }
    }

    return reminders;
  }

  List<SmartReminder> _generateSeasonalReminders(UserProfile userProfile) {
    List<SmartReminder> reminders = [];
    final now = DateTime.now();

    // AI detects upcoming seasons and holidays
    Map<String, DateTime> upcomingHolidays = _getUpcomingHolidays(now);

    for (var holiday in upcomingHolidays.entries) {
      final daysUntil = holiday.value.difference(now).inDays;

      if (daysUntil > 0 && daysUntil <= 45) {
        reminders.add(
          SmartReminder(
            id: 'holiday_${holiday.key}',
            type: ReminderType.seasonalShopping,
            title: '🎄 ${holiday.key} is approaching!',
            description: 'Start planning gifts for friends and family',
            scheduledDate: holiday.value.subtract(Duration(days: 14)),
            aiPriorityScore: _calculateSeasonalPriority(daysUntil, holiday.key),
            aiSuggestions: _generateSeasonalSuggestions(holiday.key),
          ),
        );
      }
    }

    return reminders;
  }

  List<SmartReminder> _generateBudgetReminders(UserProfile userProfile) {
    List<SmartReminder> reminders = [];

    // AI analyzes spending patterns and suggests budget planning
    if (_shouldSuggestBudgetPlanning(userProfile)) {
      reminders.add(
        SmartReminder(
          id: 'budget_planning',
          type: ReminderType.budgetPlanning,
          title: '💰 Smart Budget Planning',
          description: 'Set aside money for upcoming gift occasions',
          scheduledDate: DateTime.now().add(Duration(days: 1)),
          aiPriorityScore: 0.7,
          aiSuggestions: _generateBudgetSuggestions(userProfile),
        ),
      );
    }

    return reminders;
  }

  // AI Helper Methods
  List<int> _calculateOptimalReminderDays(
    int daysUntilEvent,
    String behaviorPattern,
    EventType eventType,
  ) {
    // AI logic: Different personalities need different reminder patterns
    switch (behaviorPattern) {
      case 'procrastinator':
        return [1, 3, 7]; // More frequent, closer reminders
      case 'planner':
        return [7, 14, 21]; // Early reminders
      case 'spontaneous':
        return [2, 5]; // Medium timing
      default:
        return [3, 7, 14]; // Balanced approach
    }
  }

  int _calculateBirthdayReminderDay(int daysUntil, UserProfile userProfile) {
    // AI decides when to remind based on user's shopping habits
    if (userProfile.averageShoppingDays != null) {
      return (userProfile.averageShoppingDays! * 1.5).round();
    }
    return daysUntil > 7 ? 7 : 3; // Default AI suggestion
  }

  double _calculatePriority(
    int reminderDay,
    EventType eventType,
    UserProfile userProfile,
  ) {
    double basePriority = 0.5;

    // AI weighs different factors
    switch (eventType) {
      case EventType.birthday:
        basePriority = 0.9;
        break;
      case EventType.wedding:
        basePriority = 0.95;
        break;
      case EventType.anniversary:
        basePriority = 0.8;
        break;
      default:
        basePriority = 0.7;
    }

    // Adjust based on timing
    if (reminderDay <= 3) basePriority += 0.1;
    if (reminderDay > 14) basePriority -= 0.2;

    return basePriority.clamp(0.0, 1.0);
  }

  double _calculateBirthdayPriority(int daysUntil, double closeness) {
    double priority = closeness * 0.8; // Closeness factor

    if (daysUntil <= 3) priority += 0.2; // Urgency factor
    if (daysUntil <= 7) priority += 0.1;

    return priority.clamp(0.0, 1.0);
  }

  double _calculateSeasonalPriority(int daysUntil, String holiday) {
    double priority = 0.6; // Base seasonal priority

    // Major holidays get higher priority
    if (holiday.contains('Christmas') || holiday.contains('New Year')) {
      priority = 0.8;
    }

    return priority;
  }

  // AI Suggestion Generators
  List<String> _generateEventSuggestions(EventSummary event, int reminderDay) {
    List<String> suggestions = [];

    switch (reminderDay) {
      case 1:
        suggestions.addAll([
          'Pick up any last-minute items',
          'Confirm your attendance',
          'Prepare your outfit',
        ]);
        break;
      case 3:
        suggestions.addAll([
          'Buy gifts if you haven\'t already',
          'Check the weather forecast',
          'Plan your transportation',
        ]);
        break;
      case 7:
        suggestions.addAll([
          'Start shopping for gifts',
          'Check your calendar for the day',
          'Think about what to wear',
        ]);
        break;
      default:
        suggestions.addAll([
          'Start planning your gift',
          'Save the date in your calendar',
          'Think about what the person might like',
        ]);
    }

    return suggestions;
  }

  List<String> _generateBirthdayGiftSuggestions(
    FriendBirthday birthday,
    List<Wish> friendWishes,
  ) {
    List<String> suggestions = [];

    // AI analyzes friend's interests and suggests gifts
    switch (birthday.interests?.first ?? 'general') {
      case 'technology':
        suggestions.addAll([
          'Latest gadgets or accessories',
          'Tech books or online courses',
          'Smart home devices',
        ]);
        break;
      case 'books':
        suggestions.addAll([
          'Bestselling novels in their favorite genre',
          'Beautiful notebook or journal',
          'Bookshelf or reading accessories',
        ]);
        break;
      case 'fitness':
        suggestions.addAll([
          'Workout gear or accessories',
          'Fitness tracker or smartwatch',
          'Healthy cookbook or meal prep containers',
        ]);
        break;
      default:
        suggestions.addAll([
          'Something personal and thoughtful',
          'Experience gift like dinner or activity',
          'Customized item with their name or photo',
        ]);
    }

    return suggestions;
  }

  List<String> _generateSeasonalSuggestions(String holiday) {
    switch (holiday) {
      case 'Christmas':
        return [
          'Start your Christmas shopping early',
          'Make a list of everyone you want to gift',
          'Set a budget for holiday gifts',
          'Look for early bird discounts',
        ];
      case 'Valentine\'s Day':
        return [
          'Plan something romantic and thoughtful',
          'Consider personalized gifts',
          'Book dinner reservations early',
        ];
      default:
        return [
          'Start planning ahead for better deals',
          'Make a gift list for the occasion',
          'Set aside budget for gifts',
        ];
    }
  }

  List<String> _generateBudgetSuggestions(UserProfile userProfile) {
    return [
      'Set aside 10-15% of monthly income for gifts',
      'Create separate savings for each upcoming occasion',
      'Track your gift spending to identify patterns',
      'Consider DIY or experience gifts to save money',
      'Start a gift fund that automatically saves money',
    ];
  }

  // Helper Methods for Mock Data
  List<FriendBirthday> _getUpcomingBirthdays() {
    final now = DateTime.now();
    return [
      FriendBirthday(
        friendId: '1',
        friendName: 'Sarah Johnson',
        date: now.add(Duration(days: 5)),
        closeness: 0.9,
        interests: ['technology', 'books'],
      ),
      FriendBirthday(
        friendId: '2',
        friendName: 'Ahmed Ali',
        date: now.add(Duration(days: 12)),
        closeness: 0.8,
        interests: ['fitness', 'travel'],
      ),
      FriendBirthday(
        friendId: '3',
        friendName: 'Emma Watson',
        date: now.add(Duration(days: 28)),
        closeness: 0.7,
        interests: ['art', 'music'],
      ),
    ];
  }

  Map<String, DateTime> _getUpcomingHolidays(DateTime now) {
    Map<String, DateTime> holidays = {};

    // Calculate upcoming holidays (simplified)
    int currentYear = now.year;

    // Christmas
    DateTime christmas = DateTime(currentYear, 12, 25);
    if (christmas.isBefore(now)) {
      christmas = DateTime(currentYear + 1, 12, 25);
    }
    holidays['Christmas'] = christmas;

    // Valentine's Day
    DateTime valentines = DateTime(currentYear, 2, 14);
    if (valentines.isBefore(now)) {
      valentines = DateTime(currentYear + 1, 2, 14);
    }
    holidays['Valentine\'s Day'] = valentines;

    // Mother's Day (second Sunday of May)
    DateTime mothersDay = _getSecondSunday(currentYear, 5);
    if (mothersDay.isBefore(now)) {
      mothersDay = _getSecondSunday(currentYear + 1, 5);
    }
    holidays['Mother\'s Day'] = mothersDay;

    return holidays;
  }

  DateTime _getSecondSunday(int year, int month) {
    DateTime firstDay = DateTime(year, month, 1);
    int firstSunday = 7 - firstDay.weekday;
    if (firstSunday == 7) firstSunday = 0;
    return DateTime(year, month, firstSunday + 7 + 1);
  }

  bool _shouldSuggestBudgetPlanning(UserProfile userProfile) {
    // AI logic: Suggest budget planning if user hasn't set one recently
    return userProfile.lastBudgetUpdate == null ||
        DateTime.now().difference(userProfile.lastBudgetUpdate!).inDays > 30;
  }

  String _generateEventReminderTitle(EventSummary event, int reminderDay) {
    if (reminderDay == 1) {
      return '⏰ ${event.name} is tomorrow!';
    } else if (reminderDay <= 3) {
      return '📅 ${event.name} in $reminderDay days';
    } else if (reminderDay == 7) {
      return '🗓️ ${event.name} next week';
    } else {
      return '📌 Upcoming: ${event.name}';
    }
  }

  String _generateEventReminderDescription(
    EventSummary event,
    int reminderDay,
  ) {
    if (reminderDay == 1) {
      return 'Final preparations for ${event.name}. Make sure you have everything ready!';
    } else if (reminderDay <= 3) {
      return 'Time to start preparing for ${event.name}. Consider what gifts or preparations you need.';
    } else if (reminderDay == 7) {
      return '${event.name} is coming up next week. Start thinking about your gift and preparations.';
    } else {
      return 'You have ${event.name} coming up. Early planning helps ensure a great experience!';
    }
  }

  String _generateBirthdayReminderDescription(
    FriendBirthday birthday,
    int daysUntil,
  ) {
    if (daysUntil == 1) {
      return '${birthday.friendName}\'s birthday is tomorrow! Time for last-minute gift pickup or preparation.';
    } else if (daysUntil <= 3) {
      return '${birthday.friendName}\'s birthday is in $daysUntil days. Perfect time to get their gift!';
    } else if (daysUntil <= 7) {
      return '${birthday.friendName}\'s birthday is next week. Start thinking about the perfect gift!';
    } else {
      return '${birthday.friendName}\'s birthday is coming up in $daysUntil days. Early planning leads to better gifts!';
    }
  }
}

// Supporting Models
class SmartReminder {
  final String id;
  final ReminderType type;
  final String title;
  final String description;
  final DateTime scheduledDate;
  final String? relatedEventId;
  final String? relatedFriendId;
  final double aiPriorityScore;
  final List<String> aiSuggestions;

  SmartReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.scheduledDate,
    this.relatedEventId,
    this.relatedFriendId,
    required this.aiPriorityScore,
    required this.aiSuggestions,
  });
}

enum ReminderType {
  eventPreparation,
  friendBirthday,
  seasonalShopping,
  budgetPlanning,
  giftSuggestion,
}

class FriendBirthday {
  final String friendId;
  final String friendName;
  final DateTime date;
  final double closeness; // 0.0 to 1.0
  final List<String>? interests;

  FriendBirthday({
    required this.friendId,
    required this.friendName,
    required this.date,
    required this.closeness,
    this.interests,
  });
}
