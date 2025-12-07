import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import '../widgets/event_card.dart';

class GuestManagementScreen extends StatefulWidget {
  final EventSummary event;

  const GuestManagementScreen({super.key, required this.event});

  @override
  _GuestManagementScreenState createState() => _GuestManagementScreenState();
}

class _GuestManagementScreenState extends State<GuestManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedTab = 'invited';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock guest data
  final List<Guest> _guests = [
    Guest(
      id: '1',
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      status: GuestStatus.invited,
      rsvpStatus: RSVPStatus.pending,
      invitedDate: DateTime.now().subtract(Duration(days: 5)),
      responseDate: null,
      plusOne: false,
      dietaryRestrictions: null,
      notes: 'Close friend from college',
    ),
    Guest(
      id: '2',
      name: 'Ahmed Ali',
      email: 'ahmed@example.com',
      status: GuestStatus.invited,
      rsvpStatus: RSVPStatus.accepted,
      invitedDate: DateTime.now().subtract(Duration(days: 4)),
      responseDate: DateTime.now().subtract(Duration(days: 2)),
      plusOne: true,
      dietaryRestrictions: 'Vegetarian',
      notes: 'Work colleague',
    ),
    Guest(
      id: '3',
      name: 'Emma Watson',
      email: 'emma@example.com',
      status: GuestStatus.invited,
      rsvpStatus: RSVPStatus.declined,
      invitedDate: DateTime.now().subtract(Duration(days: 3)),
      responseDate: DateTime.now().subtract(Duration(days: 1)),
      plusOne: false,
      dietaryRestrictions: null,
      notes: 'Out of town that weekend',
    ),
    Guest(
      id: '4',
      name: 'Mike Thompson',
      email: 'mike@example.com',
      status: GuestStatus.invited,
      rsvpStatus: RSVPStatus.accepted,
      invitedDate: DateTime.now().subtract(Duration(days: 2)),
      responseDate: DateTime.now(),
      plusOne: false,
      dietaryRestrictions: 'Gluten-free',
      notes: 'Neighbor',
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
    _searchController.dispose();
    super.dispose();
  }

  List<Guest> get _filteredGuests {
    return _guests.where((guest) {
      final matchesSearch =
          guest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guest.email.toLowerCase().contains(_searchQuery.toLowerCase());

      switch (_selectedTab) {
        case 'invited':
          return matchesSearch && guest.status == GuestStatus.invited;
        case 'accepted':
          return matchesSearch && guest.rsvpStatus == RSVPStatus.accepted;
        case 'declined':
          return matchesSearch && guest.rsvpStatus == RSVPStatus.declined;
        case 'pending':
          return matchesSearch && guest.rsvpStatus == RSVPStatus.pending;
        default:
          return matchesSearch;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Stats Cards
                            _buildStatsCards(),

                            const SizedBox(height: 20),

                            // Search and Tabs
                            _buildSearchAndTabs(),

                            const SizedBox(height: 20),

                            // Guest List
                            Expanded(child: _buildGuestList()),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
                  'Guest Management',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.event.name,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Add Guest Button
          IconButton(
            onPressed: _addNewGuest,
            icon: const Icon(Icons.person_add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalGuests = _guests.length;
    final acceptedGuests = _guests
        .where((g) => g.rsvpStatus == RSVPStatus.accepted)
        .length;
    final pendingGuests = _guests
        .where((g) => g.rsvpStatus == RSVPStatus.pending)
        .length;
    final declinedGuests = _guests
        .where((g) => g.rsvpStatus == RSVPStatus.declined)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_outline,
              value: '$totalGuests',
              label: 'Total',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              value: '$acceptedGuests',
              label: 'Accepted',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule,
              value: '$pendingGuests',
              label: 'Pending',
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel_outlined,
              value: '$declinedGuests',
              label: 'Declined',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search guests...',
              prefixIcon: Icon(
                Icons.search_outlined,
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab('invited', 'All', Icons.people_outline),
                _buildTab('accepted', 'Accepted', Icons.check_circle_outline),
                _buildTab('pending', 'Pending', Icons.schedule),
                _buildTab('declined', 'Declined', Icons.cancel_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String value, String label, IconData icon) {
    final isSelected = _selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestList() {
    if (_filteredGuests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredGuests.length,
      itemBuilder: (context, index) {
        final guest = _filteredGuests[index];
        return _buildGuestCard(guest);
      },
    );
  }

  Widget _buildGuestCard(Guest guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getRSVPStatusColor(guest.rsvpStatus).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openGuestDetails(guest),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Guest Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getRSVPStatusColor(
                          guest.rsvpStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _getRSVPStatusColor(
                            guest.rsvpStatus,
                          ).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          guest.name[0].toUpperCase(),
                          style: AppStyles.bodyLarge.copyWith(
                            color: _getRSVPStatusColor(guest.rsvpStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Guest Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  guest.name,
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // RSVP Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRSVPStatusColor(guest.rsvpStatus),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getRSVPStatusText(guest.rsvpStatus),
                                  style: AppStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            guest.email,
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // Plus One Badge
                              if (guest.plusOne)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+1',
                                    style: AppStyles.caption.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              if (guest.plusOne) const SizedBox(width: 8),

                              // Dietary Restrictions
                              if (guest.dietaryRestrictions != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    guest.dietaryRestrictions!,
                                    style: AppStyles.caption.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Send Reminder',
                        onPressed: () => _sendReminder(guest),
                        variant: ButtonVariant.outline,
                        customColor: AppColors.info,
                        icon: Icons.notification_add_outlined,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: CustomButton(
                        text: 'Update Status',
                        onPressed: () => _updateGuestStatus(guest),
                        variant: ButtonVariant.outline,
                        customColor: AppColors.secondary,
                        icon: Icons.edit_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No guests found',
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _getStatusDisplayName(GuestStatus status) {
    switch (status) {
      case GuestStatus.invited:
        return 'Invited';
      case GuestStatus.confirmed:
        return 'Confirmed';
      case GuestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getRSVPDisplayName(RSVPStatus status) {
    switch (status) {
      case RSVPStatus.accepted:
        return 'Accepted';
      case RSVPStatus.declined:
        return 'Declined';
      case RSVPStatus.pending:
        return 'Pending';
    }
  }

  Color _getRSVPStatusColor(RSVPStatus status) {
    switch (status) {
      case RSVPStatus.accepted:
        return AppColors.success;
      case RSVPStatus.declined:
        return AppColors.error;
      case RSVPStatus.pending:
        return AppColors.warning;
    }
  }

  String _getRSVPStatusText(RSVPStatus status) {
    switch (status) {
      case RSVPStatus.accepted:
        return 'Accepted';
      case RSVPStatus.declined:
        return 'Declined';
      case RSVPStatus.pending:
        return 'Pending';
    }
  }

  // Action Handlers
  void _addNewGuest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Guest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email or Username',
                hintText: 'Enter email or username',
                prefixIcon: Icon(Icons.person_add),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Personal Message (Optional)',
                hintText: 'Add a personal message',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Guest invitation sent!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Send Invitation'),
          ),
        ],
      ),
    );
  }

  void _openGuestDetails(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Guest Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    guest.name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest.name,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        guest.email,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Status', _getStatusDisplayName(guest.status)),
            _buildDetailRow('RSVP', _getRSVPDisplayName(guest.rsvpStatus)),
            _buildDetailRow(
              'Invited',
              '${guest.invitedDate.day}/${guest.invitedDate.month}/${guest.invitedDate.year}',
            ),
            if (guest.dietaryRestrictions != null)
              _buildDetailRow(
                'Dietary Restrictions',
                guest.dietaryRestrictions!,
              ),
            if (guest.notes != null) _buildDetailRow('Notes', guest.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (guest.rsvpStatus == RSVPStatus.pending)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendReminder(guest);
              },
              child: Text('Send Reminder'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppStyles.bodySmall)),
        ],
      ),
    );
  }

  void _updateGuestStatus(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update ${guest.name}\'s Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: AppColors.success),
              title: Text('Mark as Confirmed'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${guest.name} marked as confirmed!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: AppColors.error),
              title: Text('Mark as Cancelled'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${guest.name} marked as cancelled!'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.send, color: AppColors.info),
              title: Text('Send Reminder'),
              onTap: () {
                Navigator.pop(context);
                _sendReminder(guest);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sendReminder(Guest guest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder sent to ${guest.name}!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// Data Models
enum GuestStatus { invited, confirmed, cancelled }

enum RSVPStatus { pending, accepted, declined }

class Guest {
  final String id;
  final String name;
  final String email;
  final GuestStatus status;
  final RSVPStatus rsvpStatus;
  final DateTime invitedDate;
  final DateTime? responseDate;
  final bool plusOne;
  final String? dietaryRestrictions;
  final String? notes;

  Guest({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.rsvpStatus,
    required this.invitedDate,
    this.responseDate,
    required this.plusOne,
    this.dietaryRestrictions,
    this.notes,
  });
}
