import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../utils/app_routes.dart';

/// Model for user profile
class UserProfile {
  final String id;
  final String name;
  final String? profilePicture;
  final int publicWishlistsCount;
  final int totalWishlistItems;

  UserProfile({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.publicWishlistsCount,
    required this.totalWishlistItems,
  });
}

/// Guest view widget for wishlists
class GuestWishlistsViewWidget extends StatefulWidget {
  final List<UserProfile> publicUsers;

  const GuestWishlistsViewWidget({super.key, required this.publicUsers});

  @override
  State<GuestWishlistsViewWidget> createState() =>
      _GuestWishlistsViewWidgetState();
}

class _GuestWishlistsViewWidgetState extends State<GuestWishlistsViewWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = widget.publicUsers
            .where(
              (user) => user.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      } else {
        _searchResults = [];
      }
    });
  }

  void _showGuestRestrictionDialog() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('guest.restrictions.title')),
        content: Text(localization.translate('guest.restrictions.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('common.close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: Text(localization.translate('auth.signIn')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localization.translate('auth.signInToCreateWishlists'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search section
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: localization.translate(
                'wishlists.searchPublicWishlists',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Search results or public users
          if (_isSearching && _searchResults.isNotEmpty) ...[
            Text(
              localization.translate('wishlists.searchResults'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._searchResults
                .map((user) => _buildUserCard(user, localization))
                .toList(),
          ] else if (!_isSearching) ...[
            Text(
              localization.translate('wishlists.popularUsers'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.publicUsers
                .map((user) => _buildUserCard(user, localization))
                .toList(),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localization.translate('wishlists.noResultsFound'),
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user, LocalizationService localization) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            user.name[0],
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${user.publicWishlistsCount} ${localization.translate("wishlists.publicWishlists")} • ${user.totalWishlistItems} ${localization.translate("wishlists.items")}',
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.textTertiary,
        ),
        onTap: _showGuestRestrictionDialog,
      ),
    );
  }
}
