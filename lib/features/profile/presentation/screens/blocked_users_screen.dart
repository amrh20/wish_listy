import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class BlockedUsersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> blockedUsers;

  const BlockedUsersScreen({super.key, required this.blockedUsers});

  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _blockedUsers = List.from(widget.blockedUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Blocked Users'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: SafeArea(
              child: _blockedUsers.isEmpty
                  ? _buildEmptyState(localization)
                  : _buildBlockedUsersList(localization),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(LocalizationService localization) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.block_outlined,
                size: 60,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Blocked Users',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t blocked any users yet. When you block someone, they won\'t be able to see your profile or send you messages.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Learn More About Blocking',
              onPressed: _showBlockingInfo,
              variant: ButtonVariant.outline,
              icon: Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUsersList(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '${_blockedUsers.length} Blocked User${_blockedUsers.length == 1 ? '' : 's'}',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: _blockedUsers.length,
            itemBuilder: (context, index) {
              final user = _blockedUsers[index];
              return _buildBlockedUserCard(user, index, localization);
            },
          ),
        ),
        if (_blockedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: CustomButton(
              text: 'Unblock All Users',
              onPressed: _unblockAllUsers,
              variant: ButtonVariant.outline,
              icon: Icons.lock_open_outlined,
            ),
          ),
      ],
    );
  }

  Widget _buildBlockedUserCard(
    Map<String, dynamic> user,
    int index,
    LocalizationService localization,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Text(
              user['name']?[0]?.toUpperCase() ?? 'U',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? 'No email',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Blocked on ${_formatBlockDate(user['blockedDate'])}',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.textTertiary),
          onSelected: (value) {
            if (value == 'unblock') {
              _unblockUser(index);
            } else if (value == 'report') {
              _reportUser(user);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'unblock',
              child: Row(
                children: [
                  Icon(
                    Icons.lock_open_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('Unblock User'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(
                    Icons.report_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text('Report User'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBlockDate(dynamic blockedDate) {
    if (blockedDate == null) return 'Unknown date';

    try {
      if (blockedDate is String) {
        final date = DateTime.parse(blockedDate);
        return '${date.day}/${date.month}/${date.year}';
      } else if (blockedDate is DateTime) {
        return '${blockedDate.day}/${blockedDate.month}/${blockedDate.year}';
      }
    } catch (e) {
      // Handle parsing error
    }

    return 'Unknown date';
  }

  void _unblockUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock ${_blockedUsers[index]['name']}? They will be able to see your profile and send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Unblock',
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _blockedUsers.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User unblocked successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _unblockAllUsers() {
    if (_blockedUsers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock All Users'),
        content: Text(
          'Are you sure you want to unblock all ${_blockedUsers.length} users? They will be able to see your profile and send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Unblock All',
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _blockedUsers.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All users unblocked successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _reportUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report ${user['name']} for inappropriate behavior.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Your report will be reviewed by our team. Please provide details about the issue.',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Submit Report',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report submitted successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _showBlockingInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Blocking Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              icon: Icons.block_outlined,
              title: 'What happens when you block someone?',
              description:
                  'Blocked users cannot see your profile, send you messages, or view your wishlists.',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.visibility_off_outlined,
              title: 'Profile visibility',
              description:
                  'Your profile and activities will be completely hidden from blocked users.',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.settings_outlined,
              title: 'Managing blocked users',
              description:
                  'You can unblock users anytime from this screen. They will be notified when unblocked.',
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Got It',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
