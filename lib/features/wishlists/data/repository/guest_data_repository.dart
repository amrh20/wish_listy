import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Repository for managing guest user wishlist data in local Hive storage
class GuestDataRepository {
  static const String _wishlistsBoxName = 'guest_wishlists';
  static const String _itemsBoxName = 'guest_wishlist_items';

  /// Get all wishlists for guest user
  Future<List<Wishlist>> getAllWishlists() async {
    try {
      final box = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      return box.values.toList();
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error getting wishlists: $e');
      return [];
    }
  }

  /// Get a single wishlist by ID
  Future<Wishlist?> getWishlistById(String id) async {
    try {
      final box = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      return box.get(id);
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error getting wishlist $id: $e');
      return null;
    }
  }

  /// Create a new wishlist and return its ID
  Future<String> createWishlist(Wishlist wishlist) async {
    try {
      final box = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      
      // Generate unique ID for guest wishlist
      final id = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create wishlist with generated ID
      final newWishlist = wishlist.copyWith(
        id: id,
        userId: 'guest',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await box.put(id, newWishlist);
      debugPrint('✅ GuestDataRepository: Created wishlist $id');
      
      return id;
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error creating wishlist: $e');
      rethrow;
    }
  }

  /// Update an existing wishlist
  Future<void> updateWishlist(Wishlist wishlist) async {
    try {
      final box = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      
      final updatedWishlist = wishlist.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await box.put(wishlist.id, updatedWishlist);
      debugPrint('✅ GuestDataRepository: Updated wishlist ${wishlist.id}');
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error updating wishlist: $e');
      rethrow;
    }
  }

  /// Delete a wishlist and all its items
  Future<void> deleteWishlist(String id) async {
    try {
      final wishlistBox = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      final itemsBox = await Hive.openBox<WishlistItem>(_itemsBoxName);
      
      // Delete all items belonging to this wishlist
      final itemsToDelete = itemsBox.values
          .where((item) => item.wishlistId == id)
          .map((item) => item.id)
          .toList();
      
      for (final itemId in itemsToDelete) {
        await itemsBox.delete(itemId);
      }
      
      // Delete the wishlist
      await wishlistBox.delete(id);
      debugPrint('✅ GuestDataRepository: Deleted wishlist $id and ${itemsToDelete.length} items');
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error deleting wishlist: $e');
      rethrow;
    }
  }

  /// Get all items for a specific wishlist
  Future<List<WishlistItem>> getWishlistItems(String wishlistId) async {
    try {
      final box = await Hive.openBox<WishlistItem>(_itemsBoxName);
      final items = box.values
          .where((item) => item.wishlistId == wishlistId)
          .toList();
      
      debugPrint('📦 GuestDataRepository: Found ${items.length} items for wishlist $wishlistId');
      return items;
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error getting items: $e');
      return [];
    }
  }

  /// Add a new item to a wishlist and return its ID
  Future<String> addWishlistItem(String wishlistId, WishlistItem item) async {
    try {
      final itemsBox = await Hive.openBox<WishlistItem>(_itemsBoxName);
      
      // Generate unique ID for the item
      final id = 'guest_item_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create item with generated ID
      final newItem = item.copyWith(
        id: id,
        wishlistId: wishlistId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await itemsBox.put(id, newItem);
      
      // Update wishlist's updatedAt timestamp
      final wishlist = await getWishlistById(wishlistId);
      if (wishlist != null) {
        await updateWishlist(wishlist);
      }
      
      debugPrint('✅ GuestDataRepository: Added item $id to wishlist $wishlistId');
      return id;
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error adding item: $e');
      rethrow;
    }
  }

  /// Update an existing wishlist item
  Future<void> updateWishlistItem(WishlistItem item) async {
    try {
      final box = await Hive.openBox<WishlistItem>(_itemsBoxName);
      
      final updatedItem = item.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await box.put(item.id, updatedItem);
      
      // Update parent wishlist's timestamp
      final wishlistBox = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      final wishlist = wishlistBox.get(item.wishlistId);
      if (wishlist != null) {
        await updateWishlist(wishlist);
      }
      
      debugPrint('✅ GuestDataRepository: Updated item ${item.id}');
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error updating item: $e');
      rethrow;
    }
  }

  /// Delete a wishlist item
  Future<void> deleteWishlistItem(String itemId) async {
    try {
      final itemsBox = await Hive.openBox<WishlistItem>(_itemsBoxName);
      final wishlistBox = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      
      // Get the item to find its wishlistId before deleting
      final item = itemsBox.get(itemId);
      if (item != null) {
        // Delete the item
        await itemsBox.delete(itemId);
        
        // Update parent wishlist's timestamp
        final wishlist = wishlistBox.get(item.wishlistId);
        if (wishlist != null) {
          await updateWishlist(wishlist);
        }
        
        debugPrint('✅ GuestDataRepository: Deleted item $itemId and updated wishlist ${item.wishlistId}');
      } else {
        debugPrint('⚠️ GuestDataRepository: Item $itemId not found');
      }
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error deleting item: $e');
      rethrow;
    }
  }

  /// Clear all guest data (used after migration to account)
  Future<void> clearAllGuestData() async {
    try {
      final wishlistBox = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      final itemsBox = await Hive.openBox<WishlistItem>(_itemsBoxName);
      
      await wishlistBox.clear();
      await itemsBox.clear();
      
      debugPrint('✅ GuestDataRepository: Cleared all guest data');
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error clearing data: $e');
      rethrow;
    }
  }

  /// Check if guest has any data
  Future<bool> hasGuestData() async {
    try {
      final box = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      return box.isNotEmpty;
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error checking guest data: $e');
      return false;
    }
  }

  /// Get count of guest wishlists
  Future<int> getWishlistCount() async {
    try {
      final box = await Hive.openBox<Wishlist>(_wishlistsBoxName);
      return box.length;
    } catch (e) {
      debugPrint('❌ GuestDataRepository: Error getting wishlist count: $e');
      return 0;
    }
  }
}

