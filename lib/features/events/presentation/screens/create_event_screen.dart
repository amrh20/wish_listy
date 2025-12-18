import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/constants/bottom_sheet_vectors.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/widgets/decorated_bottom_sheet.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/core/services/api_service.dart';
import '../widgets/index.dart';

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
  String? _wishlistOption = 'create'; // 'create', 'link', 'none'
  String? _linkedWishlistId;
  String? _linkedWishlistName;
  String _selectedPrivacy = 'friends_only';
  String _selectedEventMode = 'in_person';
  final _meetingLinkController = TextEditingController();

  // New variables for enhanced features
  List<String> _invitedFriends = [];
  final WishlistRepository _wishlistRepository = WishlistRepository();
  final EventRepository _eventRepository = EventRepository();
  String? _createdEventId; // Store created event ID for navigation

  // Edit mode variables
  String? _eventId; // Event ID when in edit mode
  Event? _existingEvent; // Existing event data when in edit mode
  bool get _isEditMode => _eventId != null;

  final List<EventTypeOption> _eventTypes = [
    EventTypeOption(
      id: 'birthday',
      name: 'Birthday',
      icon: Icons.cake_outlined,
      color: AppColors.accent,
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
    _handleRouteArguments();
  }

  void _handleRouteArguments() {
    // Get route arguments after first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final eventId = args['eventId'] as String?;
        final event = args['event'] as Event?;

        if (eventId != null && event != null) {
          setState(() {
            _eventId = eventId;
            _existingEvent = event;
          });
          _populateFormFromEvent(event);
        }
      }
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

  /// Populates form fields from existing event data
  void _populateFormFromEvent(Event event) {
    // Set basic fields
    _nameController.text = event.name;
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location ?? '';

    // Set event type
    _selectedEventType = event.type.toString().split('.').last;

    // Set privacy
    _selectedPrivacy = event.privacy ?? 'friends_only';

    // Set mode
    _selectedEventMode = event.mode ?? 'in_person';

    // Set meeting link
    _meetingLinkController.text = event.meetingLink ?? '';

    // Parse date and time separately from event
    final eventDateTime = event.date;
    _selectedDate = DateTime(
      eventDateTime.year,
      eventDateTime.month,
      eventDateTime.day,
    );

    // Use event.time if available, otherwise extract from event.date
    if (event.time != null && event.time!.isNotEmpty) {
      try {
        final timeParts = event.time!.split(':');
        if (timeParts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } else {
          // Fallback to event.date time
          _selectedTime = TimeOfDay(
            hour: eventDateTime.hour,
            minute: eventDateTime.minute,
          );
        }
      } catch (e) {
        // Fallback to event.date time
        _selectedTime = TimeOfDay(
          hour: eventDateTime.hour,
          minute: eventDateTime.minute,
        );
      }
    } else {
      // Fallback to event.date time
      _selectedTime = TimeOfDay(
        hour: eventDateTime.hour,
        minute: eventDateTime.minute,
      );
    }

    // Set wishlist option
    if (event.wishlistId != null && event.wishlistId!.isNotEmpty) {
      _wishlistOption = 'link';
      _linkedWishlistId = event.wishlistId;
    } else {
      _wishlistOption = 'none';
    }

    // Extract invited friends from invitations
    if (event.invitations.isNotEmpty) {
      _invitedFriends = event.invitations
          .map((invitation) => invitation.inviteeId)
          .where((id) => id.isNotEmpty)
          .toList();
    }
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
                      title: _isEditMode
                          ? (localization.translate('events.editEventTitle') !=
                                    'events.editEventTitle'
                                ? localization.translate(
                                    'events.editEventTitle',
                                  )
                                : 'Edit Event')
                          : null,
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
                                        wishlistOption: _wishlistOption,
                                        linkedWishlistName: _linkedWishlistName,
                                        onWishlistChanged: (option) {
                                          setState(() {
                                            _wishlistOption = option;
                                            if (option != 'link') {
                                              _linkedWishlistId = null;
                                              _linkedWishlistName = null;
                                            }
                                          });
                                        },
                                        onLinkWishlistPressed: () {
                                          _showLinkWishlistBottomSheet();
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
                                            _saveEvent(localization),
                                        isLoading: _isLoading,
                                        primaryColor:
                                            _getSelectedEventTypeColor(),
                                        buttonText: _isEditMode
                                            ? localization.translate(
                                                        'events.updateEvent',
                                                      ) !=
                                                      'events.updateEvent'
                                                  ? localization.translate(
                                                      'events.updateEvent',
                                                    )
                                                  : 'Update Event'
                                            : null,
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

  void _showLinkWishlistBottomSheet() async {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    try {
      // Fetch user's wishlists
      final wishlists = await _wishlistRepository.getWishlists();

      if (!mounted) return;

      if (wishlists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('events.noWishlistsAvailable'),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      DecoratedBottomSheet.show(
        context: context,
        vectorType: BottomSheetVectorType.creation,
        title: localization.translate('events.selectWishlistToLink'),
        height: MediaQuery.of(context).size.height * 0.7,
        children: [
          // Wishlists List
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              itemCount: wishlists.length,
              itemBuilder: (context, index) {
                final wishlist = wishlists[index];
                final wishlistId = wishlist['id']?.toString() ?? '';
                final wishlistName =
                    wishlist['name']?.toString() ?? 'Unnamed Wishlist';
                final isSelected = _linkedWishlistId == wishlistId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _wishlistOption = 'link';
                        _linkedWishlistId = wishlistId;
                        _linkedWishlistName = wishlistName;
                      });
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      wishlistName,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      wishlist['description']?.toString() ?? '',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

          // Cancel Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: localization.translate('common.cancel'),
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.outline,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wishlists: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DecoratedBottomSheet(
            vectorType: BottomSheetVectorType.friends,
            height: MediaQuery.of(context).size.height * 0.7,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localization.translate('events.inviteFriends'),
                        style: AppStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
              ),
              const SizedBox(height: 24),

              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomTextField(
                  controller: TextEditingController(),
                  label: localization.translate('events.searchFriends'),
                  hint: localization.translate('events.searchFriendsHint'),
                  prefixIcon: Icons.search,
                ),
              ),
              const SizedBox(height: 16),

              // Select All Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
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
                            // Select all friends (by ID)
                            _invitedFriends = mockFriends
                                .map((friend) => friend['id'] as String)
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
              ),
              const SizedBox(height: 20),

              // Friends List
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: ListView.builder(
                  itemCount: mockFriends.length,
                  itemBuilder: (context, index) {
                    final friend = mockFriends[index];
                    final friendId = friend['id'] as String;
                    final isSelected = _invitedFriends.contains(friendId);

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 8,
                        left: 16,
                        right: 16,
                      ),
                      child: ListTile(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              _invitedFriends.remove(friendId);
                            } else {
                              _invitedFriends.add(friendId);
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
                            color: AppColors.textPrimary,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
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
              ),
              const SizedBox(height: 16),
            ],
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

  /// Format selected date as ISO 8601 UTC format string
  String _formatDateForAPI() {
    if (_selectedDate == null) return '';
    // Create UTC date directly (at midnight UTC) to preserve the selected day
    // This ensures the date doesn't change when converting from local timezone
    final utcDate = DateTime.utc(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    return utcDate.toIso8601String();
  }

  /// Format selected time as HH:mm format string
  String _formatTimeForAPI() {
    if (_selectedTime == null) return '';
    // Format as HH:mm (local time)
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
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

  Future<void> _saveEvent(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date
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

    // Validate time
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select event time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate meeting link for online/hybrid events
    if ((_selectedEventMode == 'online' || _selectedEventMode == 'hybrid') &&
        (_meetingLinkController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter meeting link for online events'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? wishlistId;

      // Handle wishlist creation/linking based on selected option (only for create mode)
      if (!_isEditMode && _wishlistOption == 'create') {
        // Create empty wishlist linked to event
        final eventName = _nameController.text.trim();
        final wishlistName = '$eventName Wishlist';

        final wishlistResponse = await _wishlistRepository.createWishlist(
          name: wishlistName,
          description: 'Wishlist for ${eventName} event',
          privacy: 'friends',
          category: _selectedEventType,
        );

        final wishlistData = wishlistResponse['data'] ?? wishlistResponse;
        wishlistId =
            wishlistData['id']?.toString() ??
            wishlistData['wishlistId']?.toString();

      } else if (_wishlistOption == 'link' && _linkedWishlistId != null) {
        // Use linked wishlist ID
        wishlistId = _linkedWishlistId;

      } else if (_isEditMode && _existingEvent?.wishlistId != null) {
        // In edit mode, preserve existing wishlist ID if no change
        wishlistId = _existingEvent!.wishlistId;
      }

      // Prepare event data
      final eventDate = _formatDateForAPI();
      final eventTime = _formatTimeForAPI();
      if (eventDate.isEmpty || eventTime.isEmpty) {
        throw Exception('Invalid date/time combination');
      }

      // Determine meeting link
      String? meetingLink;
      if (_selectedEventMode == 'online' || _selectedEventMode == 'hybrid') {
        meetingLink = _meetingLinkController.text.trim();
        if (meetingLink.isEmpty) {
          throw Exception('Meeting link is required for online/hybrid events');
        }
      }

      Event updatedEvent;

      if (_isEditMode) {
        // Update existing event via API

        updatedEvent = await _eventRepository.updateEvent(
          eventId: _eventId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          date: eventDate,
          time: eventTime,
          type: _selectedEventType,
          privacy: _selectedPrivacy,
          mode: _selectedEventMode,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          meetingLink: meetingLink,
          wishlistId: wishlistId,
          invitedFriends: _invitedFriends,
        );

      } else {
        // Create new event via API

        updatedEvent = await _eventRepository.createEvent(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          date: eventDate,
          time: eventTime,
          type: _selectedEventType,
          privacy: _selectedPrivacy,
          mode: _selectedEventMode,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          meetingLink: meetingLink,
          wishlistId: wishlistId,
          invitedFriends: _invitedFriends,
        );

        // Store event ID from response
        _createdEventId = updatedEvent.id;

      }

      if (mounted) {
        setState(() => _isLoading = false);
        // Show success dialog
        _showSuccessDialog(localization, eventId: updatedEvent.id);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_isEditMode ? 'update' : 'create'} event: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }

    }
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

  void _showSuccessDialog(
    LocalizationService localization, {
    required String eventId,
  }) {
    final selectedEventType = _eventTypes.firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _eventTypes.first,
    );

    // Different messages for create vs edit
    final String title = _isEditMode
        ? 'Event Updated Successfully ${selectedEventType.emoji}'
        : '${localization.translate('events.eventCreatedSuccessfully')} ${selectedEventType.emoji}';

    final String message = _isEditMode
        ? 'Your event "${_nameController.text}" has been updated successfully.'
        : localization.translate(
            'events.eventCreatedMessage',
            args: {'eventName': _nameController.text},
          );

    ConfirmationDialog.show(
      context: context,
      isSuccess: true,
      title: title,
      message: message,
      primaryActionLabel: _isEditMode
          ? (localization.translate('events.viewEvent') != 'events.viewEvent'
                ? localization.translate('events.viewEvent')
                : 'View Event')
          : localization.translate('events.inviteGuestsNow'),
      onPrimaryAction: () {
        Navigator.of(context).pop(); // Close dialog
        if (_isEditMode) {
          // Navigate to event details for edit mode
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.eventDetails,
            arguments: {'eventId': eventId},
          );
        } else {
          // Open invite guests bottom sheet for create mode
          _showFriendsSelectionModal();
        }
      },
      additionalActions: [
        if (!_isEditMode)
          DialogAction(
            label: localization.translate('events.viewEvent'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Navigate to event details, replacing create event screen
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.eventDetails,
                arguments: {'eventId': eventId},
              );
            },
            variant: ButtonVariant.outline,
            icon: Icons.visibility_rounded,
          ),
        DialogAction(
          label: localization.translate('events.done'),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            if (_isEditMode) {
              // For edit mode, navigate back to event details
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.eventDetails,
                arguments: {'eventId': eventId},
              );
            } else {
              // For create mode, navigate back to Events screen
              Navigator.of(context).pop();
            }
          },
          variant: ButtonVariant.text,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }
}
