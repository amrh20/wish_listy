import 'package:equatable/equatable.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart' as friends;
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Pending reservation made by the current user for a friend's wishlist item.
class PendingReservation extends Equatable {
  final String id;
  final WishlistItem item;
  final Wishlist? wishlist;
  final friends.User? owner;
  final DateTime? reservedUntil;

  const PendingReservation({
    required this.id,
    required this.item,
    this.wishlist,
    this.owner,
    this.reservedUntil,
  });

  factory PendingReservation.fromJson(Map<String, dynamic> json) {
    // Parse nested item object (primary source of data)
    final itemJson = (json['item'] ??
            json['wishlistItem'] ??
            json['wishItem']) as Map<String, dynamic>? ??
        <String, dynamic>{};
    final item = WishlistItem.fromJson(itemJson);

    // Parse wishlist either from top-level or from item.wishlist
    Wishlist? wishlist;
    if (json['wishlist'] is Map<String, dynamic>) {
      wishlist = Wishlist.fromJson(json['wishlist'] as Map<String, dynamic>);
    } else {
      wishlist = item.wishlist;
    }

    // Parse owner from top-level, wishlist.owner, or item.wishlist.owner
    friends.User? owner;
    final ownerRaw = json['owner'] ??
        (json['wishlist'] is Map<String, dynamic>
            ? (json['wishlist']['owner'])
            : null) ??
        wishlist?.owner ??
        item.reservedBy;
    if (ownerRaw is Map<String, dynamic>) {
      try {
        owner = friends.User.fromJson(ownerRaw);
      } catch (_) {
        owner = null;
      }
    }

    // Parse reservedUntil from top-level or fall back to item's reservedUntil
    DateTime? reservedUntil;
    final reservedRaw = json['reservedUntil'] ?? json['expiresAt'];
    if (reservedRaw != null) {
      try {
        reservedUntil = DateTime.parse(reservedRaw.toString());
      } catch (_) {
        reservedUntil = item.reservedUntil;
      }
    } else {
      reservedUntil = item.reservedUntil;
    }

    final id = json['id']?.toString() ??
        json['_id']?.toString() ??
        // Fallback to item id if reservation id is missing
        item.id;

    return PendingReservation(
      id: id,
      item: item,
      wishlist: wishlist,
      owner: owner,
      reservedUntil: reservedUntil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item.toJson(),
      if (wishlist != null) 'wishlist': wishlist!.toJson(),
      if (owner != null) 'owner': owner!.toJson(),
      if (reservedUntil != null) 'reservedUntil': reservedUntil!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, item, wishlist, owner, reservedUntil];
}

