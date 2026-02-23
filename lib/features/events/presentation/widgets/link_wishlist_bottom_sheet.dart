import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Bottom sheet widget for linking an existing wishlist to an event
class LinkWishlistBottomSheet extends StatefulWidget {
  final String eventId;
  final Function(String wishlistId) onLink;

  const LinkWishlistBottomSheet({
    super.key,
    required this.eventId,
    required this.onLink,
  });

  @override
  State<LinkWishlistBottomSheet> createState() =>
      _LinkWishlistBottomSheetState();
}

class _LinkWishlistBottomSheetState extends State<LinkWishlistBottomSheet> {
  final WishlistRepository _wishlistRepository = WishlistRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allWishlists = [];
  List<Map<String, dynamic>> _filteredWishlists = [];
  String? _selectedWishlistId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWishlists();
    _searchController.addListener(_filterWishlists);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load wishlists from API
  Future<void> _loadWishlists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wishlists = await _wishlistRepository.getWishlists();
      setState(() {
        _allWishlists = wishlists;
        _filteredWishlists = wishlists;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = Provider.of<LocalizationService>(context, listen: false)
            .translate('wishlists.failedToLoadWishlistsTryAgain');
        _isLoading = false;
      });
    }
  }

  /// Filter wishlists based on search query
  void _filterWishlists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredWishlists = _allWishlists;
      } else {
        _filteredWishlists = _allWishlists
            .where(
              (wishlist) =>
                  (wishlist['name']?.toString().toLowerCase().contains(query) ??
                      false) ||
                  (wishlist['description']?.toString().toLowerCase().contains(
                        query,
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  /// Toggle wishlist selection
  void _toggleWishlistSelection(String wishlistId) {
    setState(() {
      if (_selectedWishlistId == wishlistId) {
        _selectedWishlistId = null;
      } else {
        _selectedWishlistId = wishlistId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .translate('events.linkExistingWishlistHeader'),
                    style: AppStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: Provider.of<LocalizationService>(context, listen: false).translate('wishlists.searchWishlists'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(child: _buildContent()),

          // Bottom Action Button
          if (_selectedWishlistId != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onLink(_selectedWishlistId!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .translate('events.linkWishlistButton'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWishlists,
              child: Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .translate('app.retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredWishlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? Provider.of<LocalizationService>(context, listen: false)
                      .translate('wishlists.noWishlistsAvailableForLink')
                  : Provider.of<LocalizationService>(context, listen: false)
                      .translate('wishlists.noWishlistsFoundSearch'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredWishlists.length,
      itemBuilder: (context, index) {
        final wishlist = _filteredWishlists[index];
        final wishlistId =
            wishlist['id']?.toString() ?? wishlist['_id']?.toString() ?? '';
        final isSelected = _selectedWishlistId == wishlistId;
        final itemCount =
            wishlist['itemCount'] ?? wishlist['items']?.length ?? 0;

        return _buildWishlistCard(context, wishlist, wishlistId, isSelected, itemCount);
      },
    );
  }

  Widget _buildWishlistCard(
    BuildContext context,
    Map<String, dynamic> wishlist,
    String wishlistId,
    bool isSelected,
    int itemCount,
  ) {
    final t = Provider.of<LocalizationService>(context, listen: false);
    final name = wishlist['name']?.toString() ??
        t.translate('wishlists.unnamedWishlist');
    final description = wishlist['description']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.border.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleWishlistSelection(wishlistId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        itemCount == 1
                            ? '1 ${t.translate('wishlists.item')}'
                            : '$itemCount ${t.translate('wishlists.items')}',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
