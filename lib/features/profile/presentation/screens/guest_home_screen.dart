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
  final IconData icon;
  final Color color;
  final String name;

  const WishItemIcon({
    required this.icon,
    required this.color,
    required this.name,
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

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  bool _isLoading = true;
  List<Wishlist> _guestWishlists = [];

  List<GuestWishlist> get _guestInspirationList => [
        GuestWishlist(
          title: 'Dream Setup',
          category: 'Other',
          description: 'My ultimate workspace upgrade for 2025.',
          itemCount: 3,
          items: [
            WishItemIcon(
              icon: Icons.tv,
              color: Colors.red.shade50,
              name: 'Monitor',
            ),
            WishItemIcon(
              icon: Icons.keyboard,
              color: Colors.grey.shade100,
              name: 'Keyboard',
            ),
            WishItemIcon(
              icon: Icons.chair,
              color: Colors.brown.shade50,
              name: 'Chair',
            ),
          ],
        ),
        GuestWishlist(
          title: 'My Birthday',
          category: 'Birthday',
          description: 'Things I\'d love to get for my party! 🎈',
          itemCount: 3,
          items: [
            WishItemIcon(
              icon: Icons.watch,
              color: Colors.orange.shade50,
              name: 'Watch',
            ),
            WishItemIcon(
              icon: Icons.cake,
              color: Colors.pink.shade50,
              name: 'Cake',
            ),
            WishItemIcon(
              icon: Icons.spa,
              color: Colors.teal.shade50,
              name: 'Perfume',
            ),
          ],
        ),
        GuestWishlist(
          title: 'Our Wedding',
          category: 'Wedding',
          description: 'Furniture and essentials for our new home.',
          itemCount: 3,
          items: [
            WishItemIcon(
              icon: Icons.home,
              color: Colors.blueGrey.shade50,
              name: 'Home',
            ),
            WishItemIcon(
              icon: Icons.card_giftcard,
              color: Colors.purple.shade50,
              name: 'Gifts',
            ),
            WishItemIcon(
              icon: Icons.favorite,
              color: Colors.red.shade50,
              name: 'Love',
            ),
          ],
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadGuestWishlists();
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
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  CategoryVisual getCategoryIcon(String category) {
    final c = category.trim().toLowerCase();
    if (c == 'birthday') return CategoryVisual(Icons.cake, Colors.pink);
    if (c == 'wedding') return CategoryVisual(Icons.favorite, Colors.red);
    if (c == 'graduation') return CategoryVisual(Icons.school, Colors.blue);
    return CategoryVisual(Icons.star, Colors.purple);
  }

  List<GuestWishlist> _buildUserCreatedLists() {
    return _guestWishlists.map((w) {
      final itemCount = w.items.length;
      final preview = w.items.take(3).map((it) {
        final bg = _priorityColor(it.priority).withOpacity(0.12);
        return WishItemIcon(
          icon: _priorityIcon(it.priority),
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
        return Icons.bolt;
      case ItemPriority.urgent:
        return Icons.priority_high;
      case ItemPriority.low:
        return Icons.star_border;
      case ItemPriority.medium:
      default:
        return Icons.card_giftcard;
    }
  }

  Color _priorityColor(ItemPriority p) {
    switch (p) {
      case ItemPriority.high:
        return Colors.red;
      case ItemPriority.urgent:
        return Colors.deepOrange;
      case ItemPriority.low:
        return Colors.blueGrey;
      case ItemPriority.medium:
      default:
        return Colors.orange;
    }
  }

  Future<void> _handleCreateWishlist() async {
    await widget.onCreateWishlist();
    await _loadGuestWishlists();
  }

  @override
  Widget build(BuildContext context) {
    final userLists = _buildUserCreatedLists();
    final inspiration = _guestInspirationList;
    final userEntries = _guestWishlists.map((w) {
      final itemCount = w.items.length;
      final preview = w.items.take(3).map((it) {
        final bg = _priorityColor(it.priority).withOpacity(0.12);
        return WishItemIcon(
          icon: _priorityIcon(it.priority),
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

    final allCards = <_GuestCardEntry>[
      ...userEntries,
      ...inspiration.map((w) => _GuestCardEntry(wishlist: w, isInspiration: true)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        showGifts: true,
        child: Column(
          children: [
            UnifiedPageHeader(
              title: 'WishListy',
              titleIcon: Icons.favorite_rounded,
              subtitle: 'Create wishlists and add items anytime.',
              showSearch: false,
              titleSubtitleSpacing: 24,
              actions: [
                if (widget.onLogin != null)
                  HeaderAction(
                    icon: Icons.login_rounded,
                    iconColor: AppColors.primary,
                    onTap: widget.onLogin!,
                  ),
              ],
            ),
            Expanded(
              child: UnifiedPageContainer(
                showTopRadius: true,
                child: RefreshIndicator(
                  onRefresh: _loadGuestWishlists,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
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
                        ...allCards.asMap().entries.map((e) {
                          final entry = e.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: e.key == allCards.length - 1 ? 0 : 14),
                            child: GuestWishlistCard(
                              wishlist: entry.wishlist,
                              categoryVisual: getCategoryIcon(entry.wishlist.category),
                              showPlaceholdersWhenEmpty: !entry.isInspiration,
                              onTap: () {
                                final isDummy = entry.isInspiration;
                                final items = isDummy
                                    ? entry.wishlist.items
                                        .asMap()
                                        .entries
                                        .map(
                                          (it) => WishItemModel(
                                            id: 'dummy_${it.key}',
                                            name: it.value.name,
                                            icon: it.value.icon,
                                            color: it.value.color,
                                            description: it.value.name == 'Monitor'
                                                ? '27\" 4K IPS display'
                                                : it.value.name == 'Keyboard'
                                                    ? 'Mechanical switches'
                                                    : it.value.name == 'Chair'
                                                        ? 'Ergonomic comfort'
                                                        : null,
                                            url: it.value.name == 'Monitor'
                                                ? 'https://amazon.com'
                                                : null,
                                            storeName: it.value.name == 'Chair'
                                                ? 'IKEA'
                                                : null,
                                            storeLocation: it.value.name == 'Keyboard'
                                                ? 'In Store'
                                                : null,
                                          ),
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

                                Navigator.push(
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
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Create Your First Wishlist',
                    onPressed: _handleCreateWishlist,
                    variant: ButtonVariant.primary,
                    icon: Icons.add_rounded,
                  ),
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
  final Color color;

  const CategoryVisual(this.icon, this.color);
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

  const GuestWishlistCard({
    super.key,
    required this.wishlist,
    required this.categoryVisual,
    this.onTap,
    required this.showPlaceholdersWhenEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = wishlist.items.isNotEmpty;
    final badgeText = '${wishlist.itemCount} ${wishlist.itemCount == 1 ? 'Wish' : 'Wishes'}';
    final description = wishlist.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.black.withOpacity(0.03),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      wishlist.title,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildCategoryChip(),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: (hasItems || !showPlaceholdersWhenEmpty)
                          ? _buildCompactBubbles()
                          : const [
                              _PlaceholderBubble(),
                              SizedBox(width: 12),
                              _PlaceholderBubble(),
                              SizedBox(width: 12),
                              _PlaceholderBubble(),
                            ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    tooltip: 'View Details',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    final bg = categoryVisual.color.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            categoryVisual.icon,
            size: 14,
            color: categoryVisual.color,
          ),
          const SizedBox(width: 4),
          Text(
            wishlist.category,
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: categoryVisual.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCompactBubbles() {
    final bubbles = wishlist.items.take(3).map((item) {
      return _WishIconBubble(item: item);
    }).toList();

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        item.icon,
        size: 22,
        color: AppColors.textPrimary.withOpacity(0.85),
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


