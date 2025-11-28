import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/features/events/presentation/screens/event_details_screen.dart';
import '../../data/models/wishlist_model.dart';

class WishlistItemDetailsScreen extends StatefulWidget {
  final WishlistItem item;

  const WishlistItemDetailsScreen({super.key, required this.item});

  @override
  _WishlistItemDetailsScreenState createState() =>
      _WishlistItemDetailsScreenState();
}

class _WishlistItemDetailsScreenState extends State<WishlistItemDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              AppColors.secondary.withOpacity(0.03),
              AppColors.primary.withOpacity(0.02),
            ],
          ),

          // Content
          SafeArea(
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
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Item Image Placeholder
                                _buildItemImage(),

                                const SizedBox(height: 24),

                                // Item Details
                                _buildItemDetails(),

                                const SizedBox(height: 24),

                                // Purchase Status
                                _buildPurchaseStatus(),

                                const SizedBox(height: 32),

                                // Action Buttons
                                _buildActionButtons(),

                                const SizedBox(height: 100), // Bottom padding
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
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
                  'Item Details',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wishlist Item',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Share Button
          IconButton(
            onPressed: _shareItem,
            icon: const Icon(Icons.share_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.item.isPurchased
                  ? Icons.check_circle_outline
                  : Icons.card_giftcard_outlined,
              size: 64,
              color: widget.item.isPurchased
                  ? AppColors.success
                  : AppColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.isPurchased ? 'Wish Gifted' : 'Wish Image',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Information',
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          _buildDetailRow(
            icon: Icons.card_giftcard_outlined,
            label: 'Name',
            value: widget.item.name,
            iconColor: AppColors.secondary,
          ),

          const SizedBox(height: 12),

          _buildDetailRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: widget.item.isPurchased ? 'Gifted' : 'Available',
            iconColor: widget.item.isPurchased
                ? AppColors.success
                : AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: widget.item.isPurchased
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.item.isPurchased
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.item.isPurchased
            ? AppColors.success.withOpacity(0.1)
            : AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.item.isPurchased
              ? AppColors.success.withOpacity(0.3)
              : AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.item.isPurchased
                ? Icons.check_circle_outline
                : Icons.info_outline,
            color: widget.item.isPurchased ? AppColors.success : AppColors.info,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.isPurchased ? 'Item Purchased' : 'Item Available',
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.item.isPurchased
                        ? AppColors.success
                        : AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.isPurchased
                      ? 'This wish has been gifted for the event'
                      : 'This item is still available for purchase',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Reserve Wish Button (only if not purchased)
        if (!widget.item.isPurchased)
          CustomButton(
            text: 'Reserve Item',
            onPressed: _reserveItem,
            variant: ButtonVariant.primary,
            customColor: AppColors.secondary,
            icon: Icons.bookmark_outline,
          ),

        if (!widget.item.isPurchased) const SizedBox(height: 12),

        // View Similar Wishes Button
        CustomButton(
          text: 'View Similar Wishes',
          onPressed: _viewSimilarItems,
          variant: ButtonVariant.outline,
          customColor: AppColors.info,
          icon: Icons.search_outlined,
        ),

        const SizedBox(height: 12),

        // Back to Wishlist Button
        CustomButton(
          text: 'Back to Wishlist',
          onPressed: () => Navigator.pop(context),
          variant: ButtonVariant.outline,
          customColor: AppColors.textTertiary,
          icon: Icons.arrow_back_outlined,
        ),
      ],
    );
  }

  // Action Handlers
  void _shareItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${widget.item.name}...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _reserveItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} has been reserved!'),
        backgroundColor: AppColors.success,
      ),
    );

    // TODO: Implement item reservation logic
  }

  void _viewSimilarItems() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for similar wishes...'),
        backgroundColor: AppColors.info,
      ),
    );

    // TODO: Navigate to similar items search
  }
}
