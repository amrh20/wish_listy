import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class ItemDetailsScreen extends StatefulWidget {
  final WishlistItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final WishlistRepository _wishlistRepository = WishlistRepository();

  WishlistItem? _currentItem;
  bool _isLoading = true;
  String? _errorMessage;
  String? _wishlistName; // Store wishlist name for navigation
  Map<String, dynamic>? _rawItemData; // keep raw API data (price/url/purchasedBy object)

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _initializeAnimations();
    _fetchItemDetails();
  }

  Future<void> _fetchItemDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      
      if (authService.isGuest) {
        // Load from local storage for guests

        final guestDataRepo = Provider.of<GuestDataRepository>(context, listen: false);
        final items = await guestDataRepo.getWishlistItems(widget.item.wishlistId);

        // Find the specific item by ID
        final item = items.firstWhere(
          (item) => item.id == widget.item.id,
          orElse: () {

            throw Exception('Item not found in local storage');
          },
        );

        // Load wishlist name for navigation
        final wishlist = await guestDataRepo.getWishlistById(widget.item.wishlistId);
        
        // Use the item directly (no need to convert from JSON)
        if (mounted) {
          setState(() {
            _currentItem = item;
            _wishlistName = wishlist?.name ?? 'Wishlist';
            _isLoading = false;
          });
          _startAnimations();
        }
      } else {
        // Load from API for authenticated users

        final itemData = await _wishlistRepository.getItemById(widget.item.id);
        _rawItemData = itemData;

        // Parse the item data to WishlistItem model
        final updatedItem = WishlistItem.fromJson(itemData);
        
        // Try to get wishlist name from itemData or use default
        // API may return `wishlist` as a String id OR an object {name: ...}
        String wishlistName = 'Wishlist';
        final directName = itemData['wishlistName']?.toString();
        if (directName != null && directName.isNotEmpty) {
          wishlistName = directName;
        } else {
          final wishlistField = itemData['wishlist'];
          if (wishlistField is Map<String, dynamic>) {
            final nestedName = wishlistField['name']?.toString();
            if (nestedName != null && nestedName.isNotEmpty) {
              wishlistName = nestedName;
            }
          }
        }

        if (mounted) {
          setState(() {
            _currentItem = updatedItem;
            _wishlistName = wishlistName;
            _isLoading = false;
          });
          _startAnimations();
        }
      }
    } on ApiException catch (e) {

      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Exception')
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to load item details. Please try again.';
          _isLoading = false;
        });
      }
    }
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
    if (mounted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem ?? widget.item;

    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _errorMessage != null
                  ? _buildErrorState()
                  : _currentItem == null
                      ? Center(
                          child: Text(
                            'Item not found',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            _buildCleanTopBar(item),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTitleSection(item),
                                    const SizedBox(height: 14),
                                    if (item.imageUrl != null &&
                                        item.imageUrl!.trim().isNotEmpty)
                                      _buildImageCard(item),
                                    if (item.imageUrl != null &&
                                        item.imageUrl!.trim().isNotEmpty)
                                      const SizedBox(height: 14),
                                    if (_isPurchased(item)) ...[
                                      _buildGiftedBanner(item),
                                      const SizedBox(height: 14),
                                    ],
                                    if (_getItemUrl(item) != null) ...[
                                      _buildVisitStoreButton(item),
                                      const SizedBox(height: 16),
                                    ],
                                    _buildSoftInfoGrid(item),
                                    const SizedBox(height: 18),
                                    _buildDescriptionSection(item),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildCleanTopBar(WishlistItem item) {
    final isPurchased = _isPurchased(item);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: AppColors.textPrimary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Share',
            onPressed: () => _shareItem(item),
            icon: const Icon(Icons.share_outlined, size: 22),
            color: AppColors.textPrimary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (!isPurchased)
            IconButton(
              tooltip: 'Edit',
              onPressed: _editItem,
              icon: const Icon(Icons.edit_outlined, size: 22),
              color: AppColors.textPrimary,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(WishlistItem item) {
    final priceText = _getDisplayPrice(item);
    final priorityText = _getPriorityText(item.priority);
    final subtitle =
        (priceText != null && priceText.trim().isNotEmpty)
            ? '${priceText.trim()} • $priorityText'
            : priorityText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: AppStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(WishlistItem item) {
    final url = item.imageUrl!.trim();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftedBanner(WishlistItem item) {
    final buyerName = _getPurchasedByName();
    final text = (buyerName != null && buyerName.isNotEmpty)
        ? 'Gifted by $buyerName'
        : 'Gifted by a friend';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitStoreButton(WishlistItem item) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Visit Store 🌐',
        onPressed: () => _openStoreUrl(item),
        variant: ButtonVariant.primary,
      ),
    );
  }

  Widget _buildSoftInfoGrid(WishlistItem item) {
    final w = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;

    final priorityColor = _getPriorityColor(item.priority);
    final store = _rawItemData?['storeName']?.toString() ??
        _rawItemData?['store']?.toString() ??
        '—';

    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        _InfoTile(
          width: w,
          title: 'Date Added',
          value: _formatDate(item.createdAt),
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.textSecondary,
          chipColor: AppColors.surfaceVariant.withOpacity(0.6),
        ),
        _InfoTile(
          width: w,
          title: 'Store',
          value: (store.trim().isEmpty || store.trim() == 'null') ? '—' : store,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          chipColor: AppColors.primary.withOpacity(0.10),
        ),
        _InfoTile(
          width: w,
          title: 'Priority',
          value: _getPriorityText(item.priority),
          icon: Icons.priority_high,
          iconColor: priorityColor,
          chipColor: priorityColor.withOpacity(0.12),
        ),
      ],
    );
  }

  bool _isPurchased(WishlistItem item) {
    return item.status == ItemStatus.purchased;
  }

  String? _getItemUrl(WishlistItem item) {
    final rawUrl = _rawItemData?['url']?.toString();
    final fromModel = item.link;
    final url = (rawUrl != null && rawUrl.trim().isNotEmpty) ? rawUrl : fromModel;
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }

  String? _getDisplayPrice(WishlistItem item) {
    final rawPrice = _rawItemData?['price']?.toString();
    if (rawPrice != null && rawPrice.trim().isNotEmpty) return rawPrice.trim();

    // Fallback to model's priceRange string if available
    final pr = item.priceRange?.toString();
    if (pr != null && pr.trim().isNotEmpty && pr != 'Price not specified') {
      return pr.trim();
    }
    return null;
  }

  String? _getPurchasedByName() {
    final pb = _rawItemData?['purchasedBy'];
    if (pb is Map) {
      final fullName = pb['fullName']?.toString();
      if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
      final username = pb['username']?.toString();
      if (username != null && username.trim().isNotEmpty) return username.trim();
    }
    return null;
  }

  Future<void> _openStoreUrl(WishlistItem item) async {
    final url = _getItemUrl(item);
    if (url == null) return;

    Uri uri;
    try {
      uri = Uri.parse(url);
      if (uri.scheme.isEmpty) {
        uri = Uri.parse('https://$url');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid URL'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildGiftedStatusCard(WishlistItem item) {
    final buyerName = _getPurchasedByName();
    final byText = (buyerName != null && buyerName.isNotEmpty)
        ? 'By $buyerName'
        : 'By a Secret Friend 🤫';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.14),
            Colors.white.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -22,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎁 Gifted!',
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      byText,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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

  Widget _buildInfoGrid(WishlistItem item) {
    final priorityColor = _getPriorityColor(item.priority);
    final store = _rawItemData?['storeName']?.toString() ??
        _rawItemData?['store']?.toString() ??
        '—';
    final createdAt = item.createdAt;

    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: 'Priority',
          value: _getPriorityText(item.priority),
          icon: Icons.priority_high,
          iconColor: priorityColor,
          chipColor: priorityColor.withOpacity(0.12),
        ),
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: 'Status',
          value: _isPurchased(item) ? 'Gifted' : 'Available',
          icon: _isPurchased(item) ? Icons.check_circle : Icons.inventory_2_outlined,
          iconColor: _isPurchased(item) ? AppColors.success : AppColors.info,
          chipColor: (_isPurchased(item) ? AppColors.success : AppColors.info)
              .withOpacity(0.12),
        ),
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: 'Store',
          value: (store.trim().isEmpty || store.trim() == 'null') ? '—' : store,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          chipColor: AppColors.primary.withOpacity(0.12),
        ),
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: 'Added',
          value: _formatDate(createdAt),
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.textSecondary,
          chipColor: AppColors.surfaceVariant.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(WishlistItem item) {
    final desc = item.description?.trim();
    if (desc == null || desc.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            desc,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    // lightweight formatting without intl
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  Widget _buildHeader() {
    final isPurchased =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased;
    
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
          const Spacer(),
          // Mark as Purchased text button (small, compact)
          if (!isGuest) ...[
            TextButton(
              onPressed: _togglePurchaseStatus,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isPurchased ? 'Mark as Available' : 'Mark as Gifted',
                style: AppStyles.caption.copyWith(
                  fontSize: 12,
                  color: isPurchased ? AppColors.textSecondary : AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Actions menu (Edit, Delete)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editItem();
                  break;
                case 'delete':
                  _deleteItem();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppStyles.headingMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _fetchItemDetails,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (!mounted) return const SizedBox.shrink();

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Item Icon - Simplified
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          _currentItem?.priority ?? widget.item.priority,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getCategoryIcon('General'),
                        color: _getPriorityColor(
                          _currentItem?.priority ?? widget.item.priority,
                        ),
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Item Name - H1 Style
                  Text(
                    _currentItem?.name ?? widget.item.name,
                    style: AppStyles.headingLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      decoration:
                          (_currentItem?.status ?? widget.item.status) ==
                              ItemStatus.purchased
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Badges - Pill-shaped Chips
                  Row(
                    children: [
                      // Priority Badge
                      _buildPillBadge(
                        text: _getPriorityText(
                          _currentItem?.priority ?? widget.item.priority,
                        ),
                        color: _getPriorityColor(
                          _currentItem?.priority ?? widget.item.priority,
                        ),
                        icon: Icons.priority_high,
                      ),
                      const SizedBox(width: 8),
                      // Category Badge
                      _buildPillBadge(
                        text: 'General',
                        color: AppColors.info,
                        icon: _getCategoryIcon('General'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Item Information Section - Unified
                  _buildUnifiedInfoSection(),

                  const SizedBox(height: 32),

                  // Notes Section (if exists)
                  if (_currentItem?.description != null &&
                      _currentItem!.description!.isNotEmpty) ...[
                    _buildNotesSection(),
                    const SizedBox(height: 32),
                  ],

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillBadge({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedInfoSection() {
    final isPurchased =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Information',
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),

        // Status Label - Integrated
        _buildInfoRow(
          icon: isPurchased ? Icons.check_circle : Icons.shopping_bag_outlined,
          label: 'Status',
          value: isPurchased ? 'Gifted' : 'Available',
          iconColor: isPurchased ? AppColors.success : AppColors.warning,
          valueColor: isPurchased ? AppColors.success : AppColors.warning,
        ),

        const SizedBox(height: 16),

        // Category
        _buildInfoRow(
          icon: Icons.category_outlined,
          label: 'Category',
          value: 'General',
          iconColor: AppColors.info,
        ),

        const SizedBox(height: 16),

        // Added Date
        _buildInfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Added on',
          value: _formatDate(_currentItem?.createdAt ?? widget.item.createdAt),
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_outlined, color: AppColors.info, size: 18),
            const SizedBox(width: 8),
            Text(
              'Notes',
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentItem!.description!,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isPurchased =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased;
    
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;

    // Standardized button height and border radius
    const double buttonHeight = 56.0;
    const double buttonBorderRadius = 16.0;
    const double buttonSpacing = 12.0;

    return Column(
      children: [
        // Button 1: Share Item (Secondary Action)
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _shareItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Share Item',
                  style: AppStyles.button.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: buttonSpacing),

        // Button 3: Delete Item (Destructive Action)
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _deleteItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'Delete Item',
                  style: AppStyles.button.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Color _getPriorityColor(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return AppColors.error;
      case ItemPriority.medium:
        return AppColors.warning;
      case ItemPriority.low:
        return AppColors.success;
      case ItemPriority.urgent:
        return AppColors.accent;
    }
  }

  String _getPriorityText(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return 'High';
      case ItemPriority.medium:
        return 'Medium';
      case ItemPriority.low:
        return 'Low';
      case ItemPriority.urgent:
        return 'Urgent';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'fashion':
        return Icons.checkroom;
      case 'books':
        return Icons.book;
      case 'home & kitchen':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  // NOTE: _formatDate already exists above (yyyy-mm-dd). Keep one implementation only.

  // Action Handlers
  void _togglePurchaseStatus() {
    // TODO: Implement API call to update item status
    final newStatus =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased
        ? ItemStatus.desired
        : ItemStatus.purchased;

    setState(() {
      _currentItem =
          _currentItem?.copyWith(status: newStatus) ??
          widget.item.copyWith(status: newStatus);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == ItemStatus.purchased
              ? 'Wish marked as gifted! 🎉'
              : 'Wish marked as available! 📝',
        ),
        backgroundColor: newStatus == ItemStatus.purchased
            ? AppColors.success
            : AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _editItem() {
    // Navigate to edit item screen
    final item = _currentItem ?? widget.item;
    Navigator.pushNamed(
      context,
      AppRoutes.addItem,
      arguments: {
        'wishlistId': item.wishlistId,
        'wishlistName': _wishlistName ?? 'Wishlist',
        'itemId': item.id,
        'isEditing': true,
        'item': item,
      },
    ).then((_) {
      // Refresh item details when returning from edit screen
      if (mounted) {
        _fetchItemDetails();
      }
    });
  }

  void _shareItem([WishlistItem? item]) {
    // Lightweight "share": copy link (if any) or item name to clipboard
    final it = item ?? _currentItem ?? widget.item;
    final url = _getItemUrl(it);
    final text = (url != null && url.isNotEmpty) ? url : it.name;

    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteItem() {
    final item = _currentItem ?? widget.item;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Item',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _performDeleteItem(item),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteItem(WishlistItem item) async {
    // Close dialog first
    Navigator.pop(context);
    
    try {

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Deleting item...'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      
      if (authService.isGuest) {
        // Delete from local storage for guests
        final guestDataRepo = Provider.of<GuestDataRepository>(context, listen: false);
        await guestDataRepo.deleteWishlistItem(item.id);

      } else {
        // Call API to delete item for authenticated users
        await _wishlistRepository.deleteItem(item.id);

      }

      // Navigate back to previous screen
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.name} deleted successfully',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on ApiException catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete item: ${e.message}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete item: ${e.toString()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color chipColor;

  const _InfoTile({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
