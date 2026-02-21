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
import 'package:wish_listy/features/friends/data/models/friendship_model.dart';
import '../widgets/index.dart';
import '../widgets/invite_friends_bottom_sheet.dart';

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
  final _customEventTypeController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  /// Default date/time for new events (today at end of day). If that is already in the past, use tomorrow. Edit mode overwrites via _populateFormFromEvent.
  static DateTime get _defaultDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static TimeOfDay get _defaultTime => const TimeOfDay(hour: 23, minute: 59);

  /// Applies default date/time, ensuring the combined datetime is not in the past.
  void _applyDefaultDateAndTime() {
    final today = _defaultDate;
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59);
    if (endOfDay.isBefore(DateTime.now())) {
      _selectedDate = today.add(const Duration(days: 1));
      _selectedTime = _defaultTime;
    } else {
      _selectedDate = today;
      _selectedTime = _defaultTime;
    }
  }
  String _selectedEventType = 'birthday';
  String? _wishlistOption = 'none'; // 'link', 'none' (removed 'create' option)
  String? _linkedWishlistId;
  String? _linkedWishlistName;
  String _selectedPrivacy = 'friends_only';
  EventMode _selectedEventMode = EventMode.inPerson;
  final _meetingLinkController = TextEditingController();

  // New variables for enhanced features
  List<String> _invitedFriends = [];
  List<InvitedFriend> _invitedFriendsData = []; // Full friend data for display
  final WishlistRepository _wishlistRepository = WishlistRepository();
  final EventRepository _eventRepository = EventRepository();
  String? _createdEventId; // Store created event ID for navigation

  // Edit mode variables
  String? _eventId; // Event ID when in edit mode
  Event? _existingEvent; // Existing event data when in edit mode
  bool get _isEditMode => _eventId != null;

  List<EventTypeOption> _getEventTypes(LocalizationService localization) {
    return [
      EventTypeOption(
        id: 'birthday',
        name: localization.translate('events.birthday'),
        icon: Icons.cake_outlined,
        color: AppColors.accent,
        emoji: '🎂',
      ),
      EventTypeOption(
        id: 'wedding',
        name: localization.translate('events.wedding'),
        icon: Icons.favorite_outline,
        color: AppColors.primary,
        emoji: '💒',
      ),
      EventTypeOption(
        id: 'anniversary',
        name: localization.translate('events.anniversary'),
        icon: Icons.favorite_border,
        color: AppColors.error,
        emoji: '💕',
      ),
      EventTypeOption(
        id: 'graduation',
        name: localization.translate('events.graduation'),
        icon: Icons.school_outlined,
        color: AppColors.accent,
        emoji: '🎓',
      ),
      EventTypeOption(
        id: 'holiday',
        name: localization.translate('common.holiday'),
        icon: Icons.celebration_outlined,
        color: AppColors.success,
        emoji: '🎄',
      ),
      EventTypeOption(
        id: 'baby_shower',
        name: localization.translate('events.babyShower'),
        icon: Icons.child_friendly_outlined,
        color: AppColors.info,
        emoji: '👶',
      ),
      EventTypeOption(
        id: 'house_warming',
        name: localization.translate('events.housewarming'),
        icon: Icons.home_outlined,
        color: AppColors.warning,
        emoji: '🏠',
      ),
      EventTypeOption(
        id: 'other',
        name: localization.translate('events.other'),
        icon: Icons.event_outlined,
        color: AppColors.primary,
        emoji: '🎈',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Default date/time for new events (today at end of day). Edit mode overwrites in _handleRouteArguments.
    _applyDefaultDateAndTime();
    _initializeAnimations();
    _startAnimations();
    _handleRouteArguments();
    _nameController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
    _meetingLinkController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  /// True when all required fields are filled so Create/Update button can be enabled.
  bool get _isCreateEventEnabled {
    if (_nameController.text.trim().isEmpty) return false;
    if (_selectedDate == null) return false;
    if (_selectedTime == null) return false;
    if ((_selectedEventMode == EventMode.inPerson ||
            _selectedEventMode == EventMode.hybrid) &&
        _locationController.text.trim().isEmpty) return false;
    if ((_selectedEventMode == EventMode.online ||
            _selectedEventMode == EventMode.hybrid) &&
        _meetingLinkController.text.trim().isEmpty) return false;
    return true;
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
    final eventTypeString = event.type.toString().split('.').last;
    
    // Check if this is a custom event type (not in the predefined list)
    // Get localization for predefined types check
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isPredefinedType = _getEventTypes(localization).any((type) => type.id == eventTypeString);
    
    if (isPredefinedType) {
      _selectedEventType = eventTypeString;
      _customEventTypeController.clear();
    } else {
      // It's a custom event type
      _selectedEventType = 'other';
      _customEventTypeController.text = eventTypeString;
    }

    // Set privacy
    _selectedPrivacy = event.privacy ?? 'friends_only';

    // Set mode
    _selectedEventMode = EventModeExtension.fromString(event.mode ?? 'in_person');

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

    // Extract invited friends from invitedFriends array (from API)
    if (event.invitedFriends.isNotEmpty) {
      _invitedFriends = event.invitedFriends
          .map((friend) => friend.id)
          .where((id) => id.isNotEmpty)
          .toList();
      _invitedFriendsData = event.invitedFriends;
    } else if (event.invitations.isNotEmpty) {
      // Fallback to invitations if invitedFriends is empty
      _invitedFriends = event.invitations
          .map((invitation) => invitation.inviteeId)
          .where((id) => id.isNotEmpty)
          .toList();
      // Note: invitations don't have full friend data, so _invitedFriendsData stays empty
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _locationController.removeListener(_onFormChanged);
    _meetingLinkController.removeListener(_onFormChanged);
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _customEventTypeController.dispose();
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
                          ? localization.translate('events.editEventTitle')
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
                                        eventTypes: _getEventTypes(localization),
                                        selectedEventType: _selectedEventType,
                                        selectedColor:
                                            _getSelectedEventTypeColor(localization),
                                        onEventTypeChanged: (type) {
                                          setState(() {
                                            _selectedEventType = type;
                                            // Clear custom event type when switching away from "other"
                                            if (type != 'other') {
                                              _customEventTypeController.clear();
                                            }
                                          });
                                        },
                                      ),
                                      // Show custom event type input when "other" is selected
                                      if (_selectedEventType == 'other') ...[
                                        const SizedBox(height: 16),
                                        CustomTextField(
                                          controller: _customEventTypeController,
                                          label: localization.translate(
                                            'events.customEventType',
                                          ),
                                          hint: localization.translate(
                                            'events.enterCustomEventType',
                                          ),
                                          prefixIcon: Icons.edit_outlined,
                                          isRequired: true,
                                          validator: (value) {
                                            if (_selectedEventType == 'other' &&
                                                (value?.isEmpty ?? true)) {
                                              return localization.translate(
                                                'events.pleaseEnterCustomEventType',
                                              );
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
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

                                      // Animated Fields Container based on Event Mode
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: Column(
                                          children: [
                                            // Location Field - Show for In Person & Hybrid
                                            if (_selectedEventMode == EventMode.inPerson ||
                                                _selectedEventMode == EventMode.hybrid)
                                              Column(
                                                children: [
                                                  CustomTextField(
                                                    controller: _locationController,
                                                    label: localization.translate('events.location'),
                                                    hint: 'Enter address or pick on map',
                                                    prefixIcon: null,
                                                    suffixIcon: IconButton(
                                                      icon: const Icon(Icons.map_outlined),
                                                      onPressed: () => _pickLocationOnMap(),
                                                      tooltip: 'Pick location on map',
                                                    ),
                                                    isRequired: true,
                                                    validator: (value) {
                                                      if ((_selectedEventMode == EventMode.inPerson ||
                                                              _selectedEventMode == EventMode.hybrid) &&
                                                          (value?.trim().isEmpty ?? true)) {
                                                        return 'Location is required for ${_selectedEventMode == EventMode.inPerson ? 'in-person' : 'hybrid'} events';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                  if (_selectedEventMode == EventMode.hybrid)
                                                    const SizedBox(height: 20),
                                                ],
                                              ),

                                            // Meeting Link Field - Show for Online & Hybrid
                                            if (_selectedEventMode == EventMode.online ||
                                                _selectedEventMode == EventMode.hybrid)
                                              CustomTextField(
                                                controller: _meetingLinkController,
                                                label: localization.translate('events.onlineMeetingLink'),
                                                hint: 'Paste meeting link (Zoom, Meet, etc)',
                                                prefixIcon: Icons.video_camera_front_outlined,
                                                keyboardType: TextInputType.url,
                                                isRequired: true,
                                                validator: (value) {
                                                  if ((_selectedEventMode == EventMode.online ||
                                                          _selectedEventMode == EventMode.hybrid) &&
                                                      (value?.trim().isEmpty ?? true)) {
                                                    return 'Meeting link is required for ${_selectedEventMode == EventMode.online ? 'online' : 'hybrid'} events';
                                                  }
                                                  return null;
                                                },
                                              ),
                                          ],
                                        ),
                                      ),

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
                                        invitedFriendsData: _invitedFriendsData.isNotEmpty
                                            ? _invitedFriendsData
                                            : _existingEvent?.invitedFriends,
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
                                        selectedEventType: _selectedEventType == 'other' &&
                                                _customEventTypeController.text.trim().isNotEmpty
                                            ? EventTypeOption(
                                                id: 'other',
                                                name: _customEventTypeController.text.trim(),
                                                icon: Icons.event_outlined,
                                                color: AppColors.primary,
                                                emoji: '🎈',
                                              )
                                            : _getEventTypes(localization).firstWhere(
                                                (type) => type.id == _selectedEventType,
                                                orElse: () => _getEventTypes(localization).first,
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
                                        isEnabled: _isCreateEventEnabled,
                                        primaryColor:
                                            _getSelectedEventTypeColor(localization),
                                        buttonText: _isEditMode
                                            ? localization.translate(
                                                'events.updateEvent',
                                              )
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

  void _showLinkWishlistBottomSheet() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    // Show bottom sheet immediately with loading state
    DecoratedBottomSheet.show(
      context: context,
      vectorType: BottomSheetVectorType.creation,
      title: localization.translate('events.selectWishlistToLink'),
      height: MediaQuery.of(context).size.height * 0.7,
      children: [
        // Use FutureBuilder to load wishlists asynchronously inside the bottom sheet
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _wishlistRepository.getWishlists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Failed to load wishlists: ${snapshot.error}',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showLinkWishlistBottomSheet(); // Retry
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final wishlists = snapshot.data ?? [];

            if (wishlists.isEmpty) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          localization.translate('events.noWishlistsAvailable') ??
                              'No wishlists available',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Wishlists List
            return Column(
              children: [
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
          },
        ),
      ],
    );
  }

  void _showFriendsSelectionModal() {
    // Create map of friend ID to their response status (for edit mode)
    final friendStatuses = <String, InvitationStatus>{};
    if (_isEditMode && _existingEvent?.invitedFriends != null) {
      for (final friend in _existingEvent!.invitedFriends) {
        if (friend.status != null) {
          friendStatuses[friend.id] = friend.status!;
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteFriendsBottomSheet(
        initiallySelectedIds: _invitedFriends,
        friendStatuses: friendStatuses.isNotEmpty ? friendStatuses : null,
        onInvite: (List<String> friendIds) {
          setState(() {
            _invitedFriends = friendIds;
          });
          Navigator.pop(context);
        },
        onInviteWithFriends: (List<Friend> friends) {
          // Convert Friend objects to InvitedFriend objects
          setState(() {
            _invitedFriendsData = friends.map((friend) {
              return InvitedFriend(
                id: friend.id,
                fullName: friend.fullName,
                username: friend.username,
                profileImage: friend.profileImage,
              );
            }).toList();
          });
        },
      ),
    );
  }

  // Helper Methods
  Color _getSelectedEventTypeColor(LocalizationService localization) {
    final selectedEventType = _getEventTypes(localization).firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _getEventTypes(localization).first,
    );
    return selectedEventType.color;
  }

  /// Get the final event type to use (custom value if "other" is selected, otherwise selected type)
  String _getFinalEventType() {
    if (_selectedEventType == 'other' &&
        _customEventTypeController.text.trim().isNotEmpty) {
      return _customEventTypeController.text.trim();
    }
    return _selectedEventType;
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
    // Get today's date at midnight to compare dates only (not time)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? todayDate,
      firstDate: todayDate, // Prevent past dates
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _getSelectedEventTypeColor(localization)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        // If the selected date is today and the current time is in the past, reset time
        final selectedDateOnly = DateTime(date.year, date.month, date.day);
        if (selectedDateOnly == todayDate && _selectedTime != null) {
          final now = DateTime.now();
          final currentTime = TimeOfDay.fromDateTime(now);
          final selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
          if (selectedDateTime.isBefore(now)) {
            // Reset to current time + 1 hour if past time was selected
            _selectedTime = TimeOfDay(
              hour: (currentTime.hour + 1) % 24,
              minute: 0,
            );
          }
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if selected date is today
    final isToday = _selectedDate != null &&
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) == today;
    
    // If today, set initial time to current time or later
    TimeOfDay initialTime;
    if (isToday && _selectedTime != null) {
      final currentTime = TimeOfDay.fromDateTime(now);
      final selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      // If current selected time is in the past, use current time + 1 hour
      if (selectedDateTime.isBefore(now)) {
        initialTime = TimeOfDay(
          hour: (currentTime.hour + 1) % 24,
          minute: 0,
        );
      } else {
        initialTime = _selectedTime!;
      }
    } else {
      initialTime = _selectedTime ?? TimeOfDay(hour: 18, minute: 0);
    }
    
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _getSelectedEventTypeColor(localization)),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Validate that the selected time is not in the past if date is today
      if (isToday) {
        final selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          time.hour,
          time.minute,
        );
        
        if (selectedDateTime.isBefore(now)) {
          // Show error message and don't update time
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select a time in the future',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
      
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

  void _pickLocationOnMap() {
    // TODO: Implement map picker integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
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

    // Validate that date and time are not in the past
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Event date and time must be in the future',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate Location for in-person and hybrid events
    if ((_selectedEventMode == EventMode.inPerson ||
            _selectedEventMode == EventMode.hybrid) &&
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location is required for ${_selectedEventMode == EventMode.inPerson ? 'in-person' : 'hybrid'} events',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate Meeting Link for online and hybrid events
    if ((_selectedEventMode == EventMode.online ||
            _selectedEventMode == EventMode.hybrid) &&
        _meetingLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting link is required for online/hybrid events'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? wishlistId;

      // Handle wishlist linking based on selected option
      // Note: 'create' option has been removed - users can only link existing wishlists
      if (_wishlistOption == 'link' && _linkedWishlistId != null) {
        // Use linked wishlist ID (new selection or existing in edit mode)
        wishlistId = _linkedWishlistId;
      } else if (_wishlistOption == 'none') {
        // Explicitly set to null to unlink wishlist (or no wishlist for new event)
        wishlistId = null;
      } else if (_isEditMode && _existingEvent?.wishlistId != null) {
        // In edit mode, preserve existing wishlist ID only if option hasn't changed
        // This handles the case where user hasn't explicitly changed the wishlist option
        wishlistId = _existingEvent!.wishlistId;
      } else {
        // Default: no wishlist
        wishlistId = null;
      }

      // Prepare event data
      final eventDate = _formatDateForAPI();
      final eventTime = _formatTimeForAPI();
      if (eventDate.isEmpty || eventTime.isEmpty) {
        throw Exception('Invalid date/time combination');
      }

      // Determine meeting link
      String? meetingLink;
      if (_selectedEventMode == EventMode.online || _selectedEventMode == EventMode.hybrid) {
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
          type: _getFinalEventType(),
          privacy: _selectedPrivacy,
          mode: _selectedEventMode.apiValue,
          location: (_selectedEventMode == EventMode.inPerson ||
                  _selectedEventMode == EventMode.hybrid)
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
          type: _getFinalEventType(),
          privacy: _selectedPrivacy,
          mode: _selectedEventMode.apiValue,
          location: (_selectedEventMode == EventMode.inPerson ||
                  _selectedEventMode == EventMode.hybrid)
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('dialogs.creatingEvents')),
        content: Text(
          localization.translate('dialogs.creatingEventsDescription'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('dialogs.gotIt')),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(
    LocalizationService localization, {
    required String eventId,
  }) {
    final selectedEventType = _getEventTypes(localization).firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _getEventTypes(localization).first,
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
          : localization.translate('events.viewEvent'),
      onPrimaryAction: () {
        Navigator.of(context).pop(); // Close dialog
        // Navigate to event details
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.eventDetails,
          arguments: {'eventId': eventId},
        );
      },
      additionalActions: [
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
