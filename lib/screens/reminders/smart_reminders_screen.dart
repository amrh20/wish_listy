import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../services/smart_reminder_service.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../constants/mock_data.dart';
import '../../widgets/animated_background.dart';

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<SmartReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSmartReminders();
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

  void _loadSmartReminders() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Create mock data
    final userProfile = UserProfile.fromUser(MockData.currentUser);
    final events = _getMockEvents();
    final wishes = MockData.wishes;

    // Generate AI reminders
    final smartReminderService = SmartReminderService();
    final reminders = smartReminderService.generateSmartReminders(
      events,
      wishes,
      userProfile,
    );

    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  List<EventSummary> _getMockEvents() {
    final now = DateTime.now();
    return [
      EventSummary(
        id: '1',
        name: 'Sarah\'s Birthday Party',
        date: now.add(const Duration(days: 5)),
        type: EventType.birthday,
        location: 'Sarah\'s House',
        invitedCount: 12,
        acceptedCount: 8,
        wishlistItemCount: 15,
        isCreatedByMe: false,
        status: EventStatus.upcoming,
      ),
      EventSummary(
        id: '2',
        name: 'Company Anniversary',
        date: now.add(const Duration(days: 18)),
        type: EventType.anniversary,
        location: 'Office Building',
        invitedCount: 50,
        acceptedCount: 42,
        wishlistItemCount: 8,
        isCreatedByMe: true,
        status: EventStatus.upcoming,
      ),
    ];
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
          backgroundColor: Colors.grey.shade50,
          body: Stack(
            children: [
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
                                  : _buildRemindersContent(localization),
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
                  '🤖 Smart Reminders',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI-powered notifications just for you',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'AI',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.success,
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
                colors: [AppColors.primary, AppColors.secondary],
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
            '🧠 AI is analyzing your patterns...',
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Creating personalized reminders for you',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersContent(LocalizationService localization) {
    if (_reminders.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        // Priority Reminders
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(
              '🔥 High Priority',
              'AI detected these as urgent',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final highPriorityReminders = _reminders
                    .where((r) => r.aiPriorityScore >= 0.8)
                    .toList();
                if (index >= highPriorityReminders.length) return null;
                return _buildReminderCard(
                  highPriorityReminders[index],
                  isHighPriority: true,
                );
              },
              childCount: _reminders
                  .where((r) => r.aiPriorityScore >= 0.8)
                  .length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Other Reminders
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(
              '📅 Upcoming',
              'Smart suggestions for you',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final otherReminders = _reminders
                    .where((r) => r.aiPriorityScore < 0.8)
                    .toList();
                if (index >= otherReminders.length) return null;
                return _buildReminderCard(otherReminders[index]);
              },
              childCount: _reminders
                  .where((r) => r.aiPriorityScore < 0.8)
                  .length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildReminderCard(
    SmartReminder reminder, {
    bool isHighPriority = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighPriority
            ? Border.all(color: AppColors.accent.withOpacity(0.3), width: 2)
            : Border.all(color: AppColors.border.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getReminderTypeColor(
                      reminder.type,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getReminderTypeIcon(reminder.type),
                    size: 20,
                    color: _getReminderTypeColor(reminder.type),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: AppStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isHighPriority)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'HIGH',
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatScheduledDate(reminder.scheduledDate),
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AI Score: ${(reminder.aiPriorityScore * 100).round()}%',
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AI Suggestions
          if (reminder.aiSuggestions.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Suggestions',
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...reminder.aiSuggestions.take(3).map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8, right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _snoozeReminder(reminder),
                    icon: Icon(Icons.snooze, size: 16),
                    label: Text('Snooze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markReminderAsDone(reminder),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Got it'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(Icons.psychology, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 You\'re all caught up!',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI will notify you when there\'s something important to remember.',
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

  // Helper Methods
  Color _getReminderTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.eventPreparation:
        return AppColors.accent;
      case ReminderType.friendBirthday:
        return AppColors.secondary;
      case ReminderType.seasonalShopping:
        return AppColors.warning;
      case ReminderType.budgetPlanning:
        return AppColors.success;
      case ReminderType.giftSuggestion:
        return AppColors.info;
    }
  }

  IconData _getReminderTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.eventPreparation:
        return Icons.event;
      case ReminderType.friendBirthday:
        return Icons.cake;
      case ReminderType.seasonalShopping:
        return Icons.shopping_bag;
      case ReminderType.budgetPlanning:
        return Icons.account_balance_wallet;
      case ReminderType.giftSuggestion:
        return Icons.card_giftcard;
    }
  }

  String _formatScheduledDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _snoozeReminder(SmartReminder reminder) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ Reminder snoozed for 1 hour'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _markReminderAsDone(SmartReminder reminder) {
    setState(() {
      _reminders.remove(reminder);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Reminder marked as done!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
