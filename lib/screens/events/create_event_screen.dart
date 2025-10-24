import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/localization_service.dart';
import '../../widgets/events/index.dart';

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

  // New variables for enhanced features
  List<String> _invitedFriends = [];

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
          backgroundColor: Colors.grey.shade50,
          body: Stack(
            children: [
              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    CreateEventHeaderWidget(
                      onBackPressed: () => Navigator.pop(context),
                      onHelpPressed: _showHelpDialog,
                    ),

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
                                      // Event Type Selection
                                      EventTypeSelectionWidget(
                                        eventTypes: _eventTypes,
                                        selectedEventType: _selectedEventType,
                                        selectedColor:
                                            _getSelectedEventTypeColor(),
                                        onEventTypeChanged: (type) {
                                          setState(() {
                                            _selectedEventType = type;
                                          });
                                        },
                                      ),
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
                                      DateTimeSectionWidget(
                                        selectedDate: _selectedDate,
                                        selectedTime: _selectedTime,
                                        onDateSelected: _selectDate,
                                        onTimeSelected: _selectTime,
                                        formatDate: _formatDate,
                                        formatTime: _formatTime,
                                      ),

                                      const SizedBox(height: 24),

                                      // Event Privacy
                                      EventPrivacyWidget(
                                        selectedPrivacy: _selectedPrivacy,
                                        onPrivacyChanged: (privacy) {
                                          setState(() {
                                            _selectedPrivacy = privacy;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 24),

                                      // Event Mode
                                      EventModeWidget(
                                        selectedMode: _selectedEventMode,
                                        onModeChanged: (mode) {
                                          setState(() {
                                            _selectedEventMode = mode;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 24),

                                      // Location (moved under Event Mode)
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

                                      // Wishlist Option
                                      WishlistOptionWidget(
                                        createWishlist: _createWishlist,
                                        onWishlistChanged: (create) {
                                          setState(() {
                                            _createWishlist = create;
                                          });
                                        },
                                      ),

                                      const SizedBox(height: 24),

                                      // Invite Guests Section
                                      InviteGuestsWidget(
                                        invitedFriends: _invitedFriends,
                                        onInvitePressed:
                                            _navigateToInviteGuests,
                                      ),

                                      const SizedBox(height: 32),

                                      // Preview Section
                                      EventPreviewWidget(
                                        eventName: _nameController.text,
                                        selectedDate: _selectedDate,
                                        selectedTime: _selectedTime,
                                        location: _locationController.text,
                                        selectedEventType: _eventTypes
                                            .firstWhere(
                                              (type) =>
                                                  type.id == _selectedEventType,
                                              orElse: () => _eventTypes.first,
                                            ),
                                        formatDate: _formatDate,
                                        formatTime: _formatTime,
                                      ),

                                      const SizedBox(height: 32),

                                      // Action Buttons
                                      CreateEventActionsWidget(
                                        onCreatePressed: () =>
                                            _createEvent(localization),
                                        onSaveDraftPressed: _saveDraft,
                                        isLoading: _isLoading,
                                        primaryColor:
                                            _getSelectedEventTypeColor(),
                                      ),
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

  void _navigateToInviteGuests() {
    _showFriendsSelectionModal();
  }

  void _showFriendsSelectionModal() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    // Mock friends data - in real app, this would come from API
    final List<Map<String, dynamic>> mockFriends = [
      {
        'id': '1',
        'name': 'Ahmed Ali',
        'email': 'ahmed@example.com',
        'avatar': null,
      },
      {
        'id': '2',
        'name': 'Sara Mohamed',
        'email': 'sara@example.com',
        'avatar': null,
      },
      {
        'id': '3',
        'name': 'Omar Hassan',
        'email': 'omar@example.com',
        'avatar': null,
      },
      {
        'id': '4',
        'name': 'Fatma Ibrahim',
        'email': 'fatma@example.com',
        'avatar': null,
      },
      {
        'id': '5',
        'name': 'Youssef Ahmed',
        'email': 'youssef@example.com',
        'avatar': null,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localization.translate('events.inviteFriends'),
                        style: AppStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_invitedFriends.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_invitedFriends.length} ${localization.translate('events.selected')}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Field
                CustomTextField(
                  controller: TextEditingController(),
                  label: localization.translate('events.searchFriends'),
                  hint: localization.translate('events.searchFriendsHint'),
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 16),

                // Select All Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localization.translate('events.selectAll'),
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (_invitedFriends.length == mockFriends.length) {
                            // If all are selected, deselect all
                            _invitedFriends.clear();
                          } else {
                            // Select all friends
                            _invitedFriends = mockFriends
                                .map((friend) => friend['name'] as String)
                                .toList();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _invitedFriends.length == mockFriends.length
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _invitedFriends.length == mockFriends.length
                                  ? Icons.check
                                  : Icons.add,
                              size: 16,
                              color:
                                  _invitedFriends.length == mockFriends.length
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _invitedFriends.length == mockFriends.length
                                  ? localization.translate('events.deselectAll')
                                  : localization.translate('events.selectAll'),
                              style: AppStyles.bodySmall.copyWith(
                                color:
                                    _invitedFriends.length == mockFriends.length
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Friends List
                Expanded(
                  child: ListView.builder(
                    itemCount: mockFriends.length,
                    itemBuilder: (context, index) {
                      final friend = mockFriends[index];
                      final isSelected = _invitedFriends.contains(
                        friend['name'],
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _invitedFriends.remove(friend['name']);
                              } else {
                                _invitedFriends.add(friend['name']);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surface,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              friend['name'][0].toUpperCase(),
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            friend['name'],
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            friend['email'],
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 24,
                                )
                              : Icon(
                                  Icons.radio_button_unchecked,
                                  color: AppColors.textTertiary,
                                  size: 24,
                                ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('common.cancel'),
                        onPressed: () => Navigator.pop(context),
                        variant: ButtonVariant.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('events.inviteSelected'),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        variant: ButtonVariant.gradient,
                        gradientColors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
          content: Text(
            localization.translate('dialogs.pleaseSelectEventDate'),
          ),
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
                // Primary Action: Invite Guests Now
                CustomButton(
                  text: localization.translate('events.inviteGuestsNow'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    _navigateToInviteGuests();
                  },
                  variant: ButtonVariant.gradient,
                  gradientColors: [
                    selectedEventType.color,
                    selectedEventType.color.withOpacity(0.8),
                  ],
                  icon: Icons.person_add_outlined,
                  fullWidth: true,
                ),
                const SizedBox(height: 12),

                // Secondary Action: View Event
                CustomButton(
                  text: localization.translate('events.viewEvent'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    // Navigate to event details
                  },
                  variant: ButtonVariant.outline,
                  customColor: selectedEventType.color,
                  fullWidth: true,
                ),
                const SizedBox(height: 12),

                // Tertiary Action: Done
                CustomButton(
                  text: localization.translate('events.done'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  variant: ButtonVariant.text,
                  fullWidth: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
