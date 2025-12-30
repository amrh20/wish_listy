import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class EventGuestListScreen extends StatefulWidget {
  final String eventId;
  final List<InvitedFriend> invitedFriends;

  const EventGuestListScreen({
    super.key,
    required this.eventId,
    required this.invitedFriends,
  });

  @override
  State<EventGuestListScreen> createState() => _EventGuestListScreenState();
}

class _EventGuestListScreenState extends State<EventGuestListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<InvitedFriend> get _filteredFriends {
    List<InvitedFriend> filtered = widget.invitedFriends;

    // Filter by tab (status)
    switch (_selectedTabIndex) {
      case 1: // Going
        filtered = filtered
            .where((f) => f.status == InvitationStatus.accepted)
            .toList();
        break;
      case 2: // Maybe
        filtered = filtered
            .where((f) => f.status == InvitationStatus.maybe)
            .toList();
        break;
      case 3: // Pending
        filtered = filtered
            .where((f) =>
                f.status == InvitationStatus.pending || f.status == null)
            .toList();
        break;
      default: // All
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((friend) {
        final name = (friend.fullName ?? friend.username ?? '').toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          localization.translate('dialogs.whosComing'),
          style: AppStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localization.translate('dialogs.searchByName'),
                hintStyle: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppStyles.bodyMedium,
              tabs: [
                Tab(text: localization.translate('ui.all')),
                Tab(text: localization.translate('events.going')),
                Tab(text: localization.translate('dialogs.maybe')),
                Tab(text: localization.translate('events.pending')),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filteredFriends.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      return _buildGuestListItem(friend, localization);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestListItem(InvitedFriend friend, LocalizationService localization) {
    final displayName = friend.fullName ?? friend.username ?? 'Unknown';
    final initials = _getInitials(displayName);
    final status = friend.status ?? InvitationStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: friend.profileImage != null &&
                        friend.profileImage!.isNotEmpty
                    ? NetworkImage(friend.profileImage!)
                    : null,
                child: friend.profileImage == null ||
                        friend.profileImage!.isEmpty
                    ? Text(
                        initials,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              // Status indicator
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(status, localization),
              ],
            ),
          ),

          // Message Button
          IconButton(
            onPressed: () => _handleMessageFriend(friend),
            icon: Icon(
              Icons.message_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            tooltip: 'Message',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(InvitationStatus status, LocalizationService localization) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status, localization);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    String message;
    if (_searchQuery.isNotEmpty) {
      message = localization.translate('dialogs.noFriendsFoundMatching').replaceAll('{query}', _searchQuery);
    } else {
      switch (_selectedTabIndex) {
        case 1:
          message = localization.translate('dialogs.noOneGoingYet');
          break;
        case 2:
          message = localization.translate('dialogs.noOneRespondedMaybe');
          break;
        case 3:
          message = localization.translate('dialogs.noPendingInvitations');
          break;
        default:
          message = localization.translate('dialogs.noFriendsInvitedYet');
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return AppColors.success;
      case InvitationStatus.maybe:
        return AppColors.info;
      case InvitationStatus.pending:
        return AppColors.warning;
      case InvitationStatus.declined:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.maybe:
        return Icons.help_outline;
      case InvitationStatus.pending:
        return Icons.schedule;
      case InvitationStatus.declined:
        return Icons.cancel;
    }
  }

  String _getStatusText(InvitationStatus status, LocalizationService localization) {
    switch (status) {
      case InvitationStatus.accepted:
        return localization.translate('events.going');
      case InvitationStatus.maybe:
        return localization.translate('dialogs.maybe');
      case InvitationStatus.pending:
        return localization.translate('events.pending');
      case InvitationStatus.declined:
        return localization.translate('events.declined');
    }
  }

  Future<void> _handleMessageFriend(InvitedFriend friend) async {
    // TODO: Implement messaging functionality
    // For now, we can show a snackbar or navigate to a messaging screen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Messaging ${friend.fullName ?? friend.username ?? 'friend'}...'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

