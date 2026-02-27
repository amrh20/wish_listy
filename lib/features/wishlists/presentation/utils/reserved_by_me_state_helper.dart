import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Represents the three business states when the current user is the reserver.
enum ReservedByMeState {
  none,
  received, // State A: isReservedByMe && isReceived
  purchasedAwaitingReceipt, // State B: isReservedByMe && !isReceived && isPurchased == true
  reservedOnly, // State C: isReservedByMe && !isReceived && isPurchased != true
}

/// Derive the reserved-by-me state using raw backend flags.
///
/// The caller is responsible for determining whether the viewing user is the
/// reserver (`isReservedByMe`), since that may depend on the current user id.
ReservedByMeState getReservedByMeState(
  WishlistItem item, {
  required bool isReservedByMe,
}) {
  if (!isReservedByMe) {
    return ReservedByMeState.none;
  }

  final bool isReceived = item.isReceived;
  final bool isPurchased = item.isPurchased == true;

  if (isReceived) {
    return ReservedByMeState.received;
  }

  if (isPurchased) {
    return ReservedByMeState.purchasedAwaitingReceipt;
  }

  return ReservedByMeState.reservedOnly;
}

