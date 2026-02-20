import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'reserved_item_card_widget.dart';

class ReservationsTabWidget extends StatelessWidget {
  final List<WishlistItem> reservations;
  final bool isLoading;
  final Function(WishlistItem) onCancelReservation;
  final Function(WishlistItem) onItemTap;
  final VoidCallback onRefresh;
  final Function(WishlistItem)? onMarkAsPurchased;
  final void Function(WishlistItem item, DateTime newDate)? onExtend;

  const ReservationsTabWidget({
    super.key,
    required this.reservations,
    required this.isLoading,
    required this.onCancelReservation,
    required this.onItemTap,
    required this.onRefresh,
    this.onMarkAsPurchased,
    this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 180),
                Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ],
            )
          : reservations.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  localization.translate('cards.noReservationsYet'),
                                  style: AppStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: localization.translate('cards.browseFriends'),
                                  onPressed: () {
                                    // Switch to Friends tab; back button will return to Wishlists (index 1)
                                    MainNavigation.switchToTab(context, 3, returnToTabOnBack: 1);
                                  },
                                  icon: Icons.people_outlined,
                                  customColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 +
                        MediaQuery.of(context).padding.bottom +
                        100, // Extra space for bottom nav bar
                  ),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final item = reservations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReservedItemCardWidget(
                        item: item,
                        onCancelReservation: () => onCancelReservation(item),
                        onTap: () => onItemTap(item),
                        onMarkAsPurchased: onMarkAsPurchased != null ? () => onMarkAsPurchased!(item) : null,
                        onExtend: onExtend != null ? (DateTime newDate) => onExtend!(item, newDate) : null,
                      ),
                    );
                  },
                ),
    );
  }
}

