


import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class CreateEventScreen extends StatefulWidget {
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
  
  final List<EventTypeOption> _eventTypes = [
    EventTypeOption(
      id: 'birthday',
      name: 'Birthday',
      icon: Icons.cake_outlined,
      color: AppColors.secondary,
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(),
                
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Progress Indicator
                                  _buildProgressIndicator(),
                                  const SizedBox(height: 32),
                                  
                                  // Event Type Selection
                                  _buildEventTypeSelection(),
                                  const SizedBox(height: 24),
                                  
                                  // Event Name
                                  CustomTextField(
                                    controller: _nameController,
                                    label: 'Event Name',
                                    hint: 'What are we celebrating?',
                                    prefixIcon: Icons.celebration_outlined,
                                    isRequired: true,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter event name';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Description
                                  CustomTextField(
                                    controller: _descriptionController,
                                    label: 'Description',
                                    hint: 'Tell guests about your event (optional)',
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
                                    label: 'Location',
                                    hint: 'Where will it take place?',
                                    prefixIcon: Icons.location_on_outlined,
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.map_outlined),
                                      onPressed: _selectLocationFromMap,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Wishlist Option
                                  _buildWishlistOption(),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Preview Section
                                  _buildEventPreview(),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Create Button
                                  CustomButton(
                                    text: 'Create Event',
                                    onPressed: _createEvent,
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
                                    text: 'Save as Draft',
                                    onPressed: _saveDraft,
                                    variant: ButtonVariant.outline,
                                    customColor: _getSelectedEventTypeColor(),
                                  ),
                                  
                                  const SizedBox(height: 100), // Bottom padding
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
  }

  Widget _buildHeader() {
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
                  'Create Event',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Plan your celebration and invite friends',
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

  Widget _buildEventTypeSelection() {
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
                'What are you celebrating?',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Event Type Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                    color: isSelected 
                        ? eventType.color.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
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
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        eventType.icon,
                        color: isSelected 
                            ? eventType.color
                            : AppColors.textTertiary,
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eventType.name,
                        style: AppStyles.caption.copyWith(
                          color: isSelected 
                              ? eventType.color
                              : AppColors.textTertiary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 10,
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
              Icon(
                Icons.schedule_outlined,
                color: AppColors.info,
                size: 20,
              ),
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

  Widget _buildWishlistOption() {
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
                'Event Wishlist',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Switch(
                value: _createWishlist,
                onChanged: (value) {
                  setState(() {
                    _createWishlist = value;
                  });
                },
                activeColor: AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a wishlist for this event',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Guests can see what you\'d like to receive and mark items as purchased',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _getSelectedEventTypeColor(),
            ),
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _getSelectedEventTypeColor(),
            ),
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

  Future<void> _createEvent() async {
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
    _showSuccessDialog();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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

  void _showSuccessDialog() {
    final selectedEventType = _eventTypes.firstWhere(
      (type) => type.id == _selectedEventType,
      orElse: () => _eventTypes.first,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
              'Event Created! ${selectedEventType.emoji}',
              style: AppStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your event "${_nameController.text}" has been created successfully.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Invite Friends',
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
                    text: 'View Event',
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