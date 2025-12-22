import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/features/profile/presentation/screens/guest_login_prompt_dialog.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/wishlist_filter_chip_widget.dart';

class WishItemModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final ItemPriority? priority;
  final ItemStatus? status;
  final String? description;
  final String? note;
  final String? url;
  final String? storeName;
  final String? storeLocation;

  const WishItemModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.priority,
    this.status,
    this.description,
    this.note,
    this.url,
    this.storeName,
    this.storeLocation,
  });
}

class GuestWishlistDetailsScreen extends StatefulWidget {
  final String? wishlistId; // required for real lists to persist add/edit/delete
  final String title;
  final String category;
  final List<WishItemModel> items;
  final bool isDummy;

  const GuestWishlistDetailsScreen({
    super.key,
    this.wishlistId,
    required this.title,
    required this.category,
    required this.items,
    required this.isDummy,
  });

  @override
  State<GuestWishlistDetailsScreen> createState() =>
      _GuestWishlistDetailsScreenState();
}

class _GuestWishlistDetailsScreenState extends State<GuestWishlistDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  late List<WishItemModel> _items;
  bool _loading = false;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<WishItemModel>.from(widget.items);
    if (!widget.isDummy) {
      _reloadFromLocal();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reloadFromLocal() async {
    if (widget.isDummy || widget.wishlistId == null) return;
    setState(() => _loading = true);
    try {
      final repo = Provider.of<GuestDataRepository>(context, listen: false);
      final localItems = await repo.getWishlistItems(widget.wishlistId!);
      if (!mounted) return;
      setState(() {
        _items = localItems.map(_mapWishlistItemToUi).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    final c = category.trim().toLowerCase();
    if (c == 'birthday') return Icons.cake;
    if (c == 'wedding') return Icons.favorite;
    if (c == 'graduation') return Icons.school;
    return Icons.star;
  }

  Color _getCategoryColor(String category) {
    final c = category.trim().toLowerCase();
    if (c == 'birthday') return Colors.pink;
    if (c == 'wedding') return Colors.red;
    if (c == 'graduation') return Colors.blue;
    return AppColors.primary;
  }

  WishItemModel _mapWishlistItemToUi(WishlistItem item) {
    final icon = switch (item.priority) {
      ItemPriority.high => Icons.bolt,
      ItemPriority.urgent => Icons.priority_high,
      ItemPriority.low => Icons.star_border,
      ItemPriority.medium => Icons.card_giftcard,
    };

    final baseColor = switch (item.priority) {
      ItemPriority.high => Colors.red,
      ItemPriority.urgent => Colors.deepOrange,
      ItemPriority.low => Colors.blueGrey,
      ItemPriority.medium => Colors.orange,
    };

    final parsed = _parseGuestDescription(item.description);

    return WishItemModel(
      id: item.id,
      name: item.name,
      icon: icon,
      color: baseColor.withOpacity(0.12),
      priority: item.priority,
      status: item.status,
      description: parsed.description,
      note: parsed.note,
      url: (item.link != null && item.link!.trim().isNotEmpty) ? item.link!.trim() : null,
      storeName: parsed.storeName,
      storeLocation: parsed.storeLocation,
    );
  }

  _ParsedGuestDescription _parseGuestDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _ParsedGuestDescription();
    }

    String? description = raw;
    String? storeName;
    String? storeLocation;
    String? note;

    if (raw.contains(' | ')) {
      final parts = raw.split(' | ');
      final mainParts = <String>[];
      for (final part in parts) {
        final p = part.trim();
        if (p.toLowerCase().startsWith('storename:')) {
          storeName = p.substring('storeName:'.length).trim();
        } else if (p.toLowerCase().startsWith('storelocation:')) {
          storeLocation = p.substring('storeLocation:'.length).trim();
        } else if (p.toLowerCase().startsWith('notes:')) {
          note = p.substring('notes:'.length).trim();
        } else {
          mainParts.add(p);
        }
      }
      description = mainParts.isEmpty ? null : mainParts.join(' | ').trim();
    }

    if (description != null && description.trim().isEmpty) description = null;
    if (storeName != null && storeName.trim().isEmpty) storeName = null;
    if (storeLocation != null && storeLocation.trim().isEmpty) storeLocation = null;
    if (note != null && note.trim().isEmpty) note = null;

    return _ParsedGuestDescription(
      description: description,
      storeName: storeName,
      storeLocation: storeLocation,
      note: note,
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (_) => const GuestLoginPromptDialog(),
    );
  }

  Future<void> _navigateToAddItemScreen() async {
    if (widget.isDummy || widget.wishlistId == null) return;

    await Navigator.pushNamed(
      context,
      AppRoutes.addItem,
      arguments: widget.wishlistId!,
    );

    // Refresh from local after returning (guest add flow persists in Hive)
    if (!mounted) return;
    await _reloadFromLocal();
  }

  Future<void> _editItem(WishItemModel model) async {
    if (widget.isDummy || widget.wishlistId == null) return;

    // Navigate to AddItemScreen in edit mode (it already supports guest editing
    // via { wishlistId, itemId, isEditing } args and will prefill fields from Hive).
    await Navigator.pushNamed(
      context,
      AppRoutes.addItem,
      arguments: <String, dynamic>{
        'wishlistId': widget.wishlistId!,
        'itemId': model.id,
        'isEditing': true,
      },
    );

    if (!mounted) return;
    await _reloadFromLocal();
  }

  Future<void> _deleteItem(WishItemModel model) async {
    if (widget.isDummy || widget.wishlistId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Wish', style: AppStyles.headingSmall),
        content: Text(
          'Remove "${model.name}" from this wishlist?',
          style: AppStyles.bodyMedium,
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
    await repo.deleteWishlistItem(model.id);
    await _reloadFromLocal();
  }

  Widget _buildEmptyState() {
    if (widget.isDummy) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Wishes Yet',
                style: AppStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is a demo wishlist.',
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Wishes Yet',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This wishlist is empty. Start adding wishes you dream of!',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryGradientButton(
              text: 'Add First Wish',
              icon: Icons.add_rounded,
              onPressed: () {
                if (widget.wishlistId != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addItem,
                    arguments: widget.wishlistId!,
                  ).then((_) {
                    if (mounted) {
                      _reloadFromLocal();
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category);
    final total = _items.length;
    final gifted = _items.where((i) => i.status == ItemStatus.purchased).length;
    final filteredItems = _filteredItems();

    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        child: Stack(
          children: [
            AnimatedBackground(
              colors: [
                AppColors.background,
                AppColors.accent.withOpacity(0.03),
                AppColors.primary.withOpacity(0.02),
              ],
            ),
            SafeArea(
              child: Column(
                children: [
                  // Same header style as WishlistItemsScreen (authenticated UI)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const Spacer(),
                            if (!widget.isDummy)
                              IconButton(
                                onPressed: _navigateToAddItemScreen,
                                icon: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            if (!widget.isDummy)
                              IconButton(
                                tooltip: 'Share',
                                onPressed: _showLoginPrompt,
                                icon: Icon(Icons.share, color: categoryColor),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.title,
                          style: AppStyles.headingLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$total Wishes',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search + filters (same look as user screen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search wishes...',
                              hintStyle: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.search_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.secondary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Hide filter chips for guest details (keep UI clean).
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredItems.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                  itemCount: filteredItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];
                                    return _WishRow(
                                      item: item,
                                      isDummy: widget.isDummy,
                                      onTap: () {
                                        if (widget.isDummy) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('This is a demo item'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      onEdit: widget.isDummy ? null : () => _editItem(item),
                                      onDelete: widget.isDummy ? null : () => _deleteItem(item),
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WishItemModel> _filteredItems() {
    final q = _searchQuery.trim().toLowerCase();

    bool matchesSearch(WishItemModel item) {
      if (q.isEmpty) return true;
      final inName = item.name.toLowerCase().contains(q);
      final inDesc = (item.description ?? '').toLowerCase().contains(q);
      final inNote = (item.note ?? '').toLowerCase().contains(q);
      return inName || inDesc || inNote;
    }

    return _items.where((item) {
      final ok = matchesSearch(item);
      if (!ok) return false;

      final isGifted = item.status == ItemStatus.purchased;
      switch (_selectedFilter) {
        case 'available':
          return !isGifted;
        case 'gifted':
          return isGifted;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  Future<_EditResult?> _showEditDialog({
    required String title,
    required String initialName,
    required ItemPriority initialPriority,
    required String confirmText,
  }) async {
    final controller = TextEditingController(text: initialName);
    ItemPriority priority = initialPriority;

    return showDialog<_EditResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Wish name',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemPriority>(
              value: priority,
              items: ItemPriority.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) priority = v;
              },
              decoration: const InputDecoration(
                labelText: 'Priority',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context, _EditResult(name: name, priority: priority));
            },
            child: Text(
              confirmText,
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
}

class _EditResult {
  final String name;
  final ItemPriority priority;

  _EditResult({required this.name, required this.priority});
}

class _ParsedGuestDescription {
  final String? description;
  final String? storeName;
  final String? storeLocation;
  final String? note;

  const _ParsedGuestDescription({
    this.description,
    this.storeName,
    this.storeLocation,
    this.note,
  });
}

class _WishRow extends StatelessWidget {
  final WishItemModel item;
  final bool isDummy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _WishRow({
    required this.item,
    required this.isDummy,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final detailsText = (item.note != null && item.note!.trim().isNotEmpty)
        ? item.note!.trim()
        : (item.description != null && item.description!.trim().isNotEmpty)
            ? item.description!.trim()
            : null;

    final locationInfo = _computeLocationInfo(
      url: item.url,
      storeLocation: item.storeLocation,
      storeName: item.storeName,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (detailsText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        detailsText,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (locationInfo != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            locationInfo.icon,
                            size: 14,
                            color: locationInfo.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationInfo.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDummy && onEdit != null && onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  icon: const Icon(
                    Icons.more_vert,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                          SizedBox(width: 8),
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
                          SizedBox(width: 8),
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  _LocationInfo? _computeLocationInfo({
    required String? url,
    required String? storeLocation,
    required String? storeName,
  }) {
    final u = (url ?? '').trim();
    final loc = (storeLocation ?? '').trim();
    final name = (storeName ?? '').trim();

    if (u.isNotEmpty) {
      String text = 'Online Store';
      try {
        final uri = Uri.parse(u.contains('://') ? u : 'https://$u');
        final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
        if (host.isNotEmpty) text = host;
      } catch (_) {
        // fallback text already set
      }
      return _LocationInfo(
        icon: Icons.link,
        color: Colors.indigo,
        text: text,
      );
    }

    if (loc.isNotEmpty) {
      return _LocationInfo(
        icon: Icons.location_on_outlined,
        color: Colors.deepOrange,
        text: loc.isNotEmpty ? loc : 'In Store',
      );
    }

    if (name.isNotEmpty) {
      return _LocationInfo(
        icon: Icons.storefront_outlined,
        color: AppColors.primary,
        text: name,
      );
    }

    return null;
  }
}

class _LocationInfo {
  final IconData icon;
  final Color color;
  final String text;

  _LocationInfo({
    required this.icon,
    required this.color,
    required this.text,
  });
}


