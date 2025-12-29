import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/profile/presentation/screens/guest_wishlist_details_screen.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

class GuestWishlist {
  final String title;
  final String category;
  final String? description;
  final int itemCount;
  final List<WishItemIcon> items; // preview list (limit 3)

  const GuestWishlist({
    required this.title,
    required this.category,
    this.description,
    required this.itemCount,
    required this.items,
  });
}

class WishItemIcon {
  final IconData? icon; // Nullable: null for user-created items (show letter), IconData for dummy items
  final Color color;
  final String name;
  final String? description;
  final String? url; // For online store
  final String? storeName; // For brand name
  final String? storeLocation; // For physical store

  const WishItemIcon({
    this.icon,
    required this.color,
    required this.name,
    this.description,
    this.url,
    this.storeName,
    this.storeLocation,
  });
}

class GuestHomeScreen extends StatefulWidget {
  final Future<void> Function() onCreateWishlist;
  final VoidCallback? onLogin;

  const GuestHomeScreen({
    super.key,
    required this.onCreateWishlist,
    this.onLogin,
  });

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  List<Wishlist> _guestWishlists = [];
  late AnimationController _floatingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  List<GuestWishlist> get _guestInspirationList => [
        GuestWishlist(
          title: 'Graduation Goals',
          category: 'Graduation',
          description: 'Tech upgrades for my new journey! 🎓',
          itemCount: 3,
          items: [
            WishItemIcon(
              icon: Icons.laptop_mac,
              color: Colors.indigo.shade50,
              name: 'MacBook',
              description: 'M2 chip, 13-inch display',
              url: 'https://apple.com',
            ),
            WishItemIcon(
              icon: Icons.desktop_mac,
              color: Colors.blue.shade50,
              name: 'Monitor',
              description: '27" 4K IPS display',
              url: 'https://amazon.com',
            ),
            WishItemIcon(
              icon: Icons.headphones,
              color: Colors.grey.shade100,
              name: 'Headset',
              description: 'Wireless noise-cancelling',
              storeName: 'Sony',
            ),
          ],
        ),
        GuestWishlist(
          title: 'My 25th Birthday',
          category: 'Birthday',
          description: 'Can\'t wait to celebrate with you all! 🎉',
          itemCount: 3,
          items: [
            WishItemIcon(
              icon: Icons.watch,
              color: Colors.orange.shade50,
              name: 'Watch',
              description: 'Smartwatch with fitness tracking',
              url: 'https://apple.com',
            ),
            WishItemIcon(
              icon: Icons.cake,
              color: Colors.pink.shade50,
              name: 'Cake',
              description: 'Custom birthday cake',
              storeName: 'Local Bakery',
            ),
            WishItemIcon(
              icon: Icons.local_offer,
              color: Colors.teal.shade50,
              name: 'Perfume',
              description: 'Signature fragrance',
              storeLocation: 'Mall Store',
            ),
          ],
        ),
        GuestWishlist(
          title: 'Dream Wedding',
          category: 'Wedding',
          description: 'Essentials for our new home together. 💍',
          itemCount: 3,
          items: [
            WishItemIcon(
              icon: Icons.blender,
              color: Colors.pink.shade50,
              name: 'Mixer',
              description: 'Stand mixer for baking',
              storeName: 'KitchenAid',
            ),
            WishItemIcon(
              icon: Icons.coffee_maker,
              color: Colors.brown.shade50,
              name: 'Coffee',
              description: 'Espresso machine',
              url: 'https://amazon.com',
            ),
            WishItemIcon(
              icon: Icons.local_florist,
              color: Colors.teal.shade50,
              name: 'Decor',
              description: 'Wedding centerpieces',
              storeLocation: 'Florist Shop',
            ),
          ],
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadGuestWishlists();
    
    // Initialize floating animation for decorative icon
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Initialize pulse animation for button
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Reload data when screen becomes visible (e.g., returning from Wishlist screen after deletion)
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent && _hasLoadedOnce) {
      // Screen is now visible and we've loaded before, reload data to sync with local storage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadGuestWishlists();
        }
      });
    }
  }

  @override
  void dispose() {
    _floatingAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadGuestWishlists() async {
    final auth = Provider.of<AuthRepository>(context, listen: false);
    if (!auth.isGuest) return;

    setState(() => _isLoading = true);
    try {
      final guestRepo = Provider.of<GuestDataRepository>(context, listen: false);
      final wishlists = await guestRepo.getAllWishlists();

      // Load items for accurate counts
      final updated = <Wishlist>[];
      for (final w in wishlists) {
        final items = await guestRepo.getWishlistItems(w.id);
        updated.add(w.copyWith(items: items));
      }

      if (!mounted) return;
      setState(() {
        _guestWishlists = updated;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  CategoryVisual getCategoryIcon(String category) {
    final c = category.trim().toLowerCase();
    if (c == 'birthday') {
      return CategoryVisual(
        Icons.cake,
        Colors.orange.shade50,
        Colors.orange.shade700,
      );
    }
    if (c == 'wedding') {
      return CategoryVisual(
        Icons.favorite,
        Colors.teal.shade50,
        Colors.teal.shade700,
      );
    }
    if (c == 'graduation') {
      return CategoryVisual(
        Icons.school,
        Colors.lightBlue.shade50,
        Colors.lightBlue.shade700,
      );
    }
    return CategoryVisual(
      Icons.star,
      Colors.grey.shade100,
      Colors.grey.shade700,
    );
  }

  List<GuestWishlist> _buildUserCreatedLists() {
    return _guestWishlists.map((w) {
      final itemCount = w.items.length;
      final preview = w.items.take(3).map((it) {
        final bg = Colors.purple.shade50; // Use consistent purple background for user items
        return WishItemIcon(
          icon: null, // null for user-created items to show first letter
          color: bg,
          name: it.name,
        );
      }).toList();

      return GuestWishlist(
        title: w.name,
        category: (w.category?.isNotEmpty ?? false) ? (w.category!) : 'Other',
        description: (w.description != null && w.description!.trim().isNotEmpty)
            ? w.description!.trim()
            : null,
        itemCount: itemCount,
        items: preview,
      );
    }).toList();
  }

  IconData _priorityIcon(ItemPriority p) {
    switch (p) {
      case ItemPriority.high:
        return Icons.local_fire_department_rounded;
      case ItemPriority.low:
        return Icons.spa_rounded;
      case ItemPriority.medium:
      default:
        return Icons.bolt_rounded;
    }
  }

  Color _priorityColor(ItemPriority p) {
    switch (p) {
      case ItemPriority.high:
        return Colors.redAccent;
      case ItemPriority.low:
        return Colors.teal;
      case ItemPriority.medium:
      default:
        return AppColors.primary;
    }
  }

  Future<void> _handleCreateWishlist() async {
    await widget.onCreateWishlist();
    await _loadGuestWishlists();
  }

  Future<void> _editWishlist(String wishlistId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.createWishlist,
      arguments: {
        'wishlistId': wishlistId,
        'previousRoute': AppRoutes.home,
      },
    );
    if (!mounted) return;
    await _loadGuestWishlists();
  }

  Future<void> _deleteWishlist(String wishlistId, String wishlistName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Wishlist?',
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete \"$wishlistName\"?',
          style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final repo = Provider.of<GuestDataRepository>(context, listen: false);
    await repo.deleteWishlist(wishlistId);
    if (!mounted) return;
    await _loadGuestWishlists();
  }

  @override
  Widget build(BuildContext context) {
    final userLists = _buildUserCreatedLists();
    final inspiration = _guestInspirationList;
    final userEntries = _guestWishlists.map((w) {
      final itemCount = w.items.length;
      final preview = w.items.take(3).map((it) {
        final bg = Colors.purple.shade50; // Use consistent purple background for user items
        return WishItemIcon(
          icon: null, // null for user-created items to show first letter
          color: bg,
          name: it.name,
        );
      }).toList();

      final display = GuestWishlist(
        title: w.name,
        category: (w.category?.isNotEmpty ?? false) ? (w.category!) : 'Other',
        description: (w.description != null && w.description!.trim().isNotEmpty)
            ? w.description!.trim()
            : null,
        itemCount: itemCount,
        items: preview,
      );

      return _GuestCardEntry(
        wishlist: display,
        isInspiration: false,
        wishlistId: w.id,
        realItems: w.items,
      );
    }).toList();

    final userCards = userEntries;
    final inspirationCards = inspiration.map((w) => _GuestCardEntry(wishlist: w, isInspiration: true)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        showGifts: true,
        child: Stack(
          children: [
            // Layer A: Purple Header Background (Bottom Layer)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardPurple,
                  borderRadius: BorderRadius.zero,
                ),
                child: Stack(
                  children: [
                    // Decorative floating icon
                    Positioned(
                      right: -20,
                      top: -20,
                      child: AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: Opacity(
                              opacity: 0.15,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 120,
                                color: Colors.white,
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
            
            // Layer B: Content (Top Layer)
            SafeArea(
              child: Column(
                children: [
                  // Part 1: Header Content (on top of purple background)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make Your Wishes Come True ✨',
                                style: AppStyles.headingLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The fun way to organize dreams & receive gifts you love.',
                                style: AppStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Log In Button (always visible for guests)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          icon: Icon(
                            Icons.login_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Log In',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Part 2: White Body Sheet (The "Carved" Effect)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: RefreshIndicator(
                          onRefresh: _loadGuestWishlists,
                          color: AppColors.primary,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              _guestWishlists.isEmpty ? 80 : 16,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else ...[
                                // User's Real Lists
                                if (userLists.isNotEmpty) ...[
                                  Text(
                                    'Your Lists',
                                    style: AppStyles.headingSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                ...userCards.asMap().entries.map((e) {
                                  final entry = e.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: e.key == userCards.length - 1 ? 0 : 14,
                                    ),
                                    child: GuestWishlistCard(
                                      wishlist: entry.wishlist,
                                      categoryVisual: getCategoryIcon(entry.wishlist.category),
                                      showPlaceholdersWhenEmpty: !entry.isInspiration,
                                      onEdit: (!entry.isInspiration && entry.wishlistId != null)
                                          ? () => _editWishlist(entry.wishlistId!)
                                          : null,
                                      onDelete: (!entry.isInspiration && entry.wishlistId != null)
                                          ? () => _deleteWishlist(entry.wishlistId!, entry.wishlist.title)
                                          : null,
                                      onTap: () async {
                                        final isDummy = entry.isInspiration;
                                        final items = isDummy
                                            ? entry.wishlist.items
                                                .asMap()
                                                .entries
                                                .map(
                                                  (it) {
                                                    final itemIcon = it.value.icon ?? Icons.card_giftcard;
                                                    return WishItemModel(
                                                      id: 'dummy_${it.key}',
                                                      name: it.value.name,
                                                      icon: itemIcon,
                                                      color: it.value.color,
                                                      description: it.value.description,
                                                      url: it.value.url,
                                                      storeName: it.value.storeName,
                                                      storeLocation: it.value.storeLocation,
                                                    );
                                                  },
                                                )
                                                .toList()
                                            : (entry.realItems ?? const <WishlistItem>[])
                                                .map(
                                                  (it) => WishItemModel(
                                                    id: it.id,
                                                    name: it.name,
                                                    icon: _priorityIcon(it.priority),
                                                    color: _priorityColor(it.priority).withOpacity(0.12),
                                                    priority: it.priority,
                                                    // Real fields are parsed in GuestWishlistDetailsScreen from Hive,
                                                    // but keeping a fallback here helps initial render before reload.
                                                    description: it.description,
                                                    url: it.link,
                                                  ),
                                                )
                                                .toList();

                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GuestWishlistDetailsScreen(
                                              wishlistId: isDummy ? null : entry.wishlistId,
                                              title: entry.wishlist.title,
                                              category: entry.wishlist.category,
                                              items: items,
                                              isDummy: isDummy,
                                            ),
                                          ),
                                        );
                                        // Reload wishlists after returning from details screen to show new items
                                        if (!mounted) return;
                                        await _loadGuestWishlists();
                                      },
                                    ),
                                  );
                                }),
                                
                                // Inspiration Section Header
                                if (inspirationCards.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4, right: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Get Inspired ✨',
                                          style: AppStyles.headingSmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sample collections to spark your creativity',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Inspiration Cards
                                ...inspirationCards.asMap().entries.map((e) {
                                  final entry = e.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: e.key == inspirationCards.length - 1 ? 0 : 14,
                                    ),
                                    child: GuestWishlistCard(
                                      wishlist: entry.wishlist,
                                      categoryVisual: getCategoryIcon(entry.wishlist.category),
                                      showPlaceholdersWhenEmpty: !entry.isInspiration,
                                      onEdit: (!entry.isInspiration && entry.wishlistId != null)
                                          ? () => _editWishlist(entry.wishlistId!)
                                          : null,
                                      onDelete: (!entry.isInspiration && entry.wishlistId != null)
                                          ? () => _deleteWishlist(entry.wishlistId!, entry.wishlist.title)
                                          : null,
                                      onTap: () async {
                                        final isDummy = entry.isInspiration;
                                        final items = isDummy
                                            ? entry.wishlist.items
                                                .asMap()
                                                .entries
                                                .map(
                                                  (it) {
                                                    final itemIcon = it.value.icon ?? Icons.card_giftcard;
                                                    return WishItemModel(
                                                      id: 'dummy_${it.key}',
                                                      name: it.value.name,
                                                      icon: itemIcon,
                                                      color: it.value.color,
                                                      description: it.value.description,
                                                      url: it.value.url,
                                                      storeName: it.value.storeName,
                                                      storeLocation: it.value.storeLocation,
                                                    );
                                                  },
                                                )
                                                .toList()
                                            : (entry.realItems ?? const <WishlistItem>[])
                                                .map(
                                                  (it) => WishItemModel(
                                                    id: it.id,
                                                    name: it.name,
                                                    icon: _priorityIcon(it.priority),
                                                    color: _priorityColor(it.priority).withOpacity(0.12),
                                                    priority: it.priority,
                                                    // Real fields are parsed in GuestWishlistDetailsScreen from Hive,
                                                    // but keeping a fallback here helps initial render before reload.
                                                    description: it.description,
                                                    url: it.link,
                                                  ),
                                                )
                                                .toList();

                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GuestWishlistDetailsScreen(
                                              wishlistId: isDummy ? null : entry.wishlistId,
                                              title: entry.wishlist.title,
                                              category: entry.wishlist.category,
                                              items: items,
                                              isDummy: isDummy,
                                            ),
                                          ),
                                        );
                                        // Reload wishlists after returning from details screen to show new items
                                        if (!mounted) return;
                                        await _loadGuestWishlists();
                                      },
                                    ),
                                  );
                                }),
                                
                                // Add bottom padding to prevent button from covering last item
                                const SizedBox(height: 120),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Create Button (floating at bottom)
            if (_guestWishlists.isEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6B46C1), // Purple
                                Color(0xFF9333EA), // Deep purple
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B46C1).withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleCreateWishlist,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Create Your First Wishlist',
                                      style: AppStyles.bodyLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CategoryVisual {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const CategoryVisual(
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  );
}

class _GuestCardEntry {
  final GuestWishlist wishlist;
  final bool isInspiration;
  final String? wishlistId;
  final List<WishlistItem>? realItems;

  const _GuestCardEntry({
    required this.wishlist,
    required this.isInspiration,
    this.wishlistId,
    this.realItems,
  });
}

class GuestWishlistCard extends StatelessWidget {
  final GuestWishlist wishlist;
  final CategoryVisual categoryVisual;
  final VoidCallback? onTap;
  final bool showPlaceholdersWhenEmpty;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GuestWishlistCard({
    super.key,
    required this.wishlist,
    required this.categoryVisual,
    this.onTap,
    required this.showPlaceholdersWhenEmpty,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = wishlist.items.isNotEmpty;

    final categoryColor = categoryVisual.foregroundColor;
    final categoryName = wishlist.category;
    final wishesText = '• ${wishlist.itemCount} ${wishlist.itemCount == 1 ? 'Wish' : 'Wishes'}';
    final description = wishlist.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
          // 1. Top Section: Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // B. Title & Metadata (Right Side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Small inline icon (no background circle)
                              Icon(
                                categoryVisual.icon,
                                size: 20,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 8),
                              // Title text
                              Expanded(
                                child: Text(
                                  wishlist.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onEdit != null && onDelete != null)
                          PopupMenuButton<String>(
                            tooltip: 'Options',
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') onEdit?.call();
                              if (value == 'delete') onDelete?.call();
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          const Icon(Icons.more_vert, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Metadata Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          wishesText,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    if (hasDescription) ...[
                      const SizedBox(height: 10),
                      Text(
                        description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Middle Section: Bubbles Preview (only if has items)
          if (hasItems) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: _buildCompactBubbles(),
                  ),
                ),
              ),
            ),
          ],

          // 3. Bottom Section: Action Button (Only if 0 items)
          if (!hasItems) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Your First Wish',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryVisual.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            categoryVisual.icon,
            size: 14,
            color: categoryVisual.foregroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            wishlist.category,
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: categoryVisual.foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCompactBubbles() {
    final total = wishlist.itemCount;
    final preview = wishlist.items.take(3).toList();

    final bubbles = <Widget>[
      for (final item in preview) _WishIconBubble(item: item),
    ];

    if (total > 3) {
      bubbles.add(_MoreCountBubble(count: total - 3));
    } else {
      final remaining = 3 - bubbles.length;
      for (var i = 0; i < remaining; i++) {
        bubbles.add(const _PlaceholderBubble());
      }
    }

    final spaced = <Widget>[];
    for (int i = 0; i < bubbles.length; i++) {
      spaced.add(bubbles[i]);
      if (i != bubbles.length - 1) spaced.add(const SizedBox(width: 12));
    }
    return spaced;
  }
}

class _WishIconBubble extends StatelessWidget {
  final WishItemIcon item;

  const _WishIconBubble({required this.item});

  String _getInitial(String name) {
    if (name.isEmpty) return '';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Hybrid approach: Show icon if available (dummy items), otherwise show first letter (user items)
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.color, // Use item's color for background
        shape: BoxShape.circle,
      ),
      child: Center(
        child: item.icon != null
            ? Icon(
                item.icon!,
                size: 20,
                color: AppColors.primary, // Dark purple icon
              )
            : (_getInitial(item.name).isNotEmpty
                ? Text(
                    _getInitial(item.name),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary, // Dark purple text
                    ),
                  )
                : Icon(
                    Icons.card_giftcard, // Fallback icon
                    size: 18,
                    color: AppColors.primary,
                  )),
      ),
    );
  }
}

class _PlaceholderBubble extends StatelessWidget {
  const _PlaceholderBubble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: Colors.grey.withOpacity(0.45),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 16,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _MoreCountBubble extends StatelessWidget {
  final int count;

  const _MoreCountBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.20),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: AppStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final fill = Paint()
      ..color = Colors.grey.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;

    // subtle fill
    canvas.drawCircle(center, radius, fill);

    // dashed border
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1));
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    const dashLength = 4.0;
    const gapLength = 3.0;
    double distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dashLength;
      final extract = metric.extractPath(distance, next.clamp(0.0, metric.length));
      canvas.drawPath(extract, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}


