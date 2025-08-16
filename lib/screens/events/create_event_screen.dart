import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';
import '../../services/localization_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedEventType = 'birthday';
  bool _createWishlist = true;
  String _selectedPrivacy = 'friends_only';
  String _selectedEventMode = 'in_person';
  final _meetingLinkController = TextEditingController();

  final List<EventTypeOption> _eventTypes = [
    EventTypeOption(
      id: 'birthday',
      name: 'Birthday',
      icon: Icons.cake_outlined,
      color: AppColors.pink,
      emoji: '🎂',
    ),
    EventTypeOption(
      id: 'wedding',
      name: 'Wedding',
      icon: Icons.favorite_outline,
      color: AppColors.primary,
      emoji: '💒',
    ),
    EventTypeOption(
      id: 'anniversary',
      name: 'Anniversary',
      icon: Icons.favorite_border,
      color: AppColors.error,
      emoji: '💕',
    ),
    EventTypeOption(
      id: 'graduation',
      name: 'Graduation',
      icon: Icons.school_outlined,
      color: AppColors.accent,
      emoji: '🎓',
    ),
    EventTypeOption(
      id: 'holiday',
      name: 'Holiday',
      icon: Icons.celebration_outlined,
      color: AppColors.success,
      emoji: '🎄',
    ),
    EventTypeOption(
      id: 'baby_shower',
      name: 'Baby Shower',
      icon: Icons.child_friendly_outlined,
      color: AppColors.info,
      emoji: '👶',
    ),
    EventTypeOption(
      id: 'house_warming',
      name: 'Housewarming',
      icon: Icons.home_outlined,
      color: AppColors.warning,
      emoji: '🏠',
    ),
    EventTypeOption(
      id: 'other',
      name: 'Other',
      icon: Icons.event_outlined,
      color: AppColors.primary,
      emoji: '🎈',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
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
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
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
                  AppColors.accent.withOpacity(0.03),
                  AppColors.secondary.withOpacity(0.02),
                ],
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(localization),

                    // Form
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Progress Indicator
                                      _buildProgressIndicator(),
                                      const SizedBox(height: 32),

                                      // Event Type Selection
                                      _buildEventTypeSelection(localization),
                                      const SizedBox(height: 24),

                                      // Event Name
                                      CustomTextField(
                                        controller: _nameController,
                                        label: localization.translate(
                                          'events.eventName',
                                        ),
                                        hint: localization.translate(
                                          'events.whatAreWeCelebrating',
                                        ),
                                        prefixIcon: Icons.celebration_outlined,
                                        isRequired: true,
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return localization.translate(
                                              'events.pleaseEnterEventName',
                                            );
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      // Description
                                      CustomTextField(
                                        controller: _descriptionController,
                                        label: localization.translate(
                                          'events.description',
                                        ),
                                        hint: localization.translate(
                                          'events.tellGuestsAboutEvent',
                                        ),
                                        prefixIcon: Icons.description_outlined,
                                        maxLines: 3,
                                      ),

                                      const SizedBox(height: 24),

                                      // Date and Time Section
                                      _buildDateTimeSection(),

                                      const SizedBox(height: 24),

                                      // Location
                                      CustomTextField(
                                        controller: _locationController,
                                        label: localization.translate(
                                          'events.location',
                                        ),
                                        hint: localization.translate(
                                          'events.whereWillItTakePlace',
                                        ),
                                        prefixIcon: Icons.location_on_outlined,
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.map_outlined),
                                          onPressed: _selectLocationFromMap,
                                        ),
                                      ),

                                      // Online Meeting Link (only for online/hybrid events)
                                      if (_selectedEventMode == 'online' ||
                                          _selectedEventMode == 'hybrid') ...[
                                        const SizedBox(height: 20),
                                        CustomTextField(
                                          controller: _meetingLinkController,
                                          label: localization.translate(
                                            'events.onlineMeetingLink',
                                          ),
                                          hint: localization.translate(
                                            'events.enterMeetingLink',
                                          ),
                                          prefixIcon: Icons.video_call_outlined,
                                          keyboardType: TextInputType.url,
                                          validator: (value) {
                                            if (_selectedEventMode ==
                                                    'online' &&
                                                (value?.isEmpty ?? true)) {
                                              return localization.translate(
                                                'events.pleaseEnterMeetingLink',
                                              );
                                            }
                                            return null;
                                          },
                                        ),
                                      ],

                                      const SizedBox(height: 24),

                                      // Event Privacy
                                      _buildEventPrivacySection(localization),
                                      const SizedBox(height: 24),

                                      // Event Mode
                                      _buildEventModeSection(localization),
                                      const SizedBox(height: 24),

                                      // Wishlist Option
                                      _buildWishlistOption(localization),

                                      const SizedBox(height: 32),

                                      // Preview Section
                                      _buildEventPreview(),

                                      const SizedBox(height: 32),

                                      // Create Button
                                      CustomButton(
                                        text: localization.translate(
                                          'events.createEvent',
                                        ),
                                        onPressed: () =>
                                            _createEvent(localization),
                                        isLoading: _isLoading,
                                        variant: ButtonVariant.gradient,
                                        gradientColors: [
                                          _getSelectedEventTypeColor(),
                                          AppColors.accent,
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Save Draft Button
                                      CustomButton(
                                        text: localization.translate(
                                          'events.saveAsDraft',
                                        ),
                                        onPressed: _saveDraft,
                                        variant: ButtonVariant.outline,
                                        customColor:
                                            _getSelectedEventTypeColor(),
                                      ),

                                      const SizedBox(
                                        height: 100,
                                      ), // Bottom padding
                                    ],
                                  ),
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

  Widget _buildHeader(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('events.createEventTitle'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  localization.translate('events.createEventSubtitle'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Help Button
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i == 0
                      ? _getSelectedEventTypeColor()
                      : AppColors.textTertiary.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTypeSelection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getSelectedEventTypeColor().withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: _getSelectedEventTypeColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.whatAreYouCelebrating'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Type Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - 18) / 4; // 18 = 6*3 (spacing)
              final itemHeight = itemWidth * 1.1; // Slightly taller than wide
              final gridHeight = (itemHeight * 2) + 6; // 2 rows + spacing

              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  shrinkWrap: false,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: itemWidth / itemHeight,
                  ),
                  itemCount: _eventTypes.length,
                  itemBuilder: (context, index) {
                    final eventType = _eventTypes[index];
                    final isSelected = _selectedEventType == eventType.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEventType = eventType.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? eventType.color.withOpacity(0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? eventType.color
                                : AppColors.textTertiary.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              eventType.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 1),
                            Icon(
                              eventType.icon,
                              color: isSelected
                                  ? eventType.color
                                  : AppColors.textTertiary,
                              size: 14,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              eventType.name,
                              style: AppStyles.caption.copyWith(
                                color: isSelected
                                    ? eventType.color
                                    : AppColors.textTertiary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'When is your event?',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Date Selector
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedDate != null
                            ? AppColors.info
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: _selectedDate != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: _selectedDate != null
                              ? AppColors.info
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Select date',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: _selectedDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: _selectedDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Time Selector
              Expanded(
                child: GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTime != null
                            ? AppColors.info
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: _selectedTime != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          color: _selectedTime != null
                              ? AppColors.info
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedTime != null
                                    ? _formatTime(_selectedTime!)
                                    : 'Select time',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: _selectedTime != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: _selectedTime != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventPrivacySection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.eventPrivacy'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('events.whoCanSeeThisEvent'),
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPrivacyOption(
                'public',
                localization.translate('events.public'),
                localization.translate('events.publicDescription'),
                Icons.public,
                AppColors.success,
                localization,
              ),
              _buildPrivacyOption(
                'friends_only',
                localization.translate('events.friendsOnly'),
                localization.translate('events.friendsOnlyDescription'),
                Icons.people_outline,
                AppColors.info,
                localization,
              ),
              _buildPrivacyOption(
                'private',
                localization.translate('events.private'),
                localization.translate('events.privateDescription'),
                Icons.lock_outline,
                AppColors.warning,
                localization,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
    LocalizationService localization,
  ) {
    final isSelected = _selectedPrivacy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPrivacy = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.textTertiary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEventModeSection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.eventMode'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('events.howWillPeopleAttend'),
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildModeOption(
                'in_person',
                localization.translate('events.inPerson'),
                localization.translate('events.inPersonDescription'),
                Icons.location_on_outlined,
                AppColors.success,
                localization,
              ),
              _buildModeOption(
                'online',
                localization.translate('events.online'),
                localization.translate('events.onlineDescription'),
                Icons.video_call_outlined,
                AppColors.info,
                localization,
              ),
              _buildModeOption(
                'hybrid',
                localization.translate('events.hybrid'),
                localization.translate('events.hybridDescription'),
                Icons.connect_without_contact_outlined,
                AppColors.warning,
                localization,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
    LocalizationService localization,
  ) {
    final isSelected = _selectedEventMode == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEventMode = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.textTertiary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistOption(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _createWishlist
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.eventWishlist'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            children: [
              // Yes Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    _createWishlist = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _createWishlist
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _createWishlist
                          ? AppColors.secondary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: _createWishlist ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _createWishlist
                            ? AppColors.secondary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localization.translate(
                                'events.yesCreateWishlist',
                              ),
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: _createWishlist
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _createWishlist
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              localization.translate(
                                'events.yesCreateWishlistDescription',
                              ),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_createWishlist)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // No Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    _createWishlist = false;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: !_createWishlist
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_createWishlist
                          ? AppColors.info
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: !_createWishlist ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: !_createWishlist
                            ? AppColors.info
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localization.translate(
                                'events.noUsePublicWishlist',
                              ),
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: !_createWishlist
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: !_createWishlist
                                    ? AppColors.info
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              localization.translate(
                                'events.noUsePublicWishlistDescription',
                              ),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_createWishlist)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.info,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreview() {
    final selectedEventType = _eventTypes.firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _eventTypes.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedEventType.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_outlined,
                color: selectedEventType.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Event Preview',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selectedEventType.color.withOpacity(0.1),
                  selectedEventType.color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedEventType.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selectedEventType.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selectedEventType.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty
                            ? 'Your Event Name'
                            : _nameController.text,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_selectedDate != null) ...[
                        Text(
                          '${_formatDate(_selectedDate!)}${_selectedTime != null ? ' at ${_formatTime(_selectedTime!)}' : ''}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Date & Time TBD',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (_locationController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _locationController.text,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getSelectedEventTypeColor() {
    final selectedEventType = _eventTypes.firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _eventTypes.first,
    );
    return selectedEventType.color;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  // Action Handlers
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _getSelectedEventTypeColor()),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _getSelectedEventTypeColor()),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _selectLocationFromMap() {
    // Open map for location selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map integration coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _createEvent(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an event date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Show success dialog
    _showSuccessDialog(localization);
  }

  void _saveDraft() {
    // Save as draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.save_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text('Event saved as draft'),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Creating Events'),
        content: Text(
          'Events help you plan celebrations and share wishlists with friends. Once created, you can invite friends and they\'ll be able to see your event wishlist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(LocalizationService localization) {
    // Debug: Print localization info
    debugPrint(
      '_showSuccessDialog - Current Language: ${localization.currentLanguage}',
    );
    debugPrint('_showSuccessDialog - Is Loading: ${localization.isLoading}');
    debugPrint(
      '_showSuccessDialog - Event Created Message: ${localization.translate('events.eventCreatedMessage', args: {'eventName': _nameController.text})}',
    );
    debugPrint(
      '_showSuccessDialog - Event Wishlist Created: ${localization.translate('events.eventWishlistCreated')}',
    );

    final selectedEventType = _eventTypes.firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _eventTypes.first,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: selectedEventType.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedEventType.icon,
                color: selectedEventType.color,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${localization.translate('events.eventCreatedSuccessfully')} ${selectedEventType.emoji}',
              style: AppStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localization.translate(
                'events.eventCreatedMessage',
                args: {'eventName': _nameController.text},
              ),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Wishlist Status
            if (_createWishlist) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.translate(
                              'events.eventWishlistCreated',
                            ),
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            localization.translate(
                              'events.wishlistCreatedMessage',
                            ),
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.translate(
                              'events.usingPublicWishlist',
                            ),
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                          Text(
                            localization.translate('events.noWishlistMessage'),
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              localization.translate('events.nextSteps'),
              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localization.translate('events.whatWouldYouLikeToDo'),
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                if (_createWishlist) ...[
                  CustomButton(
                    text: localization.translate('events.addWishlistItems'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      // Navigate to add wishlist items
                    },
                    variant: ButtonVariant.primary,
                    customColor: selectedEventType.color,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('events.inviteFriends'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          // Navigate to invite friends
                        },
                        variant: ButtonVariant.outline,
                        customColor: selectedEventType.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('events.viewEvent'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          // Navigate to event details
                        },
                        variant: ButtonVariant.primary,
                        customColor: selectedEventType.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Event Type Option Model
class EventTypeOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  EventTypeOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}
