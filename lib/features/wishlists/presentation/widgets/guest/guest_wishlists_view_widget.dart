import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Model for public wishlist
class PublicWishlist {
  final String id;
  final String name;
  final String ownerName;
  final int itemCount;
  final String? description;
  final DateTime lastUpdated;

  PublicWishlist({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.itemCount,
    this.description,
    required this.lastUpdated,
  });
}

/// Guest view widget for wishlists
class GuestWishlistsViewWidget extends StatefulWidget {
  final List<PublicWishlist> publicWishlists;

  const GuestWishlistsViewWidget({super.key, required this.publicWishlists});

  @override
  State<GuestWishlistsViewWidget> createState() =>
      _GuestWishlistsViewWidgetState();
}

class _GuestWishlistsViewWidgetState extends State<GuestWishlistsViewWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<PublicWishlist> _searchResults = [];
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
        _searchResults = widget.publicWishlists
            .where(
              (wishlist) =>
                  wishlist.name.toLowerCase().contains(query.toLowerCase()) ||
                  wishlist.ownerName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (wishlist.description?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
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
                    style: AppStyles.bodyMediumWithContext(context).copyWith(
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
              hintText: localization.translate('wishlists.searchWishlists'),
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

          // Search results or public wishlists
          if (_isSearching && _searchResults.isNotEmpty) ...[
            Text(
              localization.translate('wishlists.searchResults'),
              style: AppStyles.headingSmallWithContext(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._searchResults
                .map((wishlist) => _buildWishlistCard(wishlist, localization))
                .toList(),
          ] else if (!_isSearching && widget.publicWishlists.isNotEmpty) ...[
            Text(
              localization.translate('wishlists.publicWishlists'),
              style: AppStyles.headingSmallWithContext(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.publicWishlists
                .map((wishlist) => _buildWishlistCard(wishlist, localization))
                .toList(),
          ] else ...[
            // Improved empty state with suggestions
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Public Wishlists Yet',
                      style: AppStyles.headingMediumWithContext(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Be the first to share your wishlist! Sign up to create and share your wishlists with friends.',
                      style: AppStyles.bodyMediumWithContext(context).copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Sign Up to Create Wishlists',
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.signup);
                      },
                      variant: ButtonVariant.gradient,
                      gradientColors: [AppColors.primary, AppColors.secondary],
                      size: ButtonSize.large,
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

  Widget _buildWishlistCard(
    PublicWishlist wishlist,
    LocalizationService localization,
  ) {
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
          child: Icon(
            Icons.favorite_outline,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          wishlist.name,
          style: AppStyles.bodyLargeWithContext(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localization.translate("wishlists.by")} ${wishlist.ownerName}',
              style: AppStyles.bodySmallWithContext(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${wishlist.itemCount} ${wishlist.itemCount == 1 ? "Wish" : "Wishes"} • ${localization.translate("wishlists.updated")} ${_formatDate(wishlist.lastUpdated)}',
              style: AppStyles.bodySmallWithContext(context).copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
