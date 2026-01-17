import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Repository for managing guest user wishlist data in local Hive storage
class GuestDataRepository {
  static const String _wishlistsBoxName = 'guest_wishlists';
  static const String _itemsBoxName = 'guest_wishlist_items';

  /// Get all wishlists for guest user
  Future<List<Wishlist>> getAllWishlists() async {
    try {
      // Use Hive.box() instead of Hive.openBox() for better performance
      // Box is already opened in main.dart
      final box = Hive.box<Wishlist>(_wishlistsBoxName);
      return box.values.toList();
    } catch (e) {

      return [];
    }
  }

  /// Get a single wishlist by ID
  Future<Wishlist?> getWishlistById(String id) async {
    try {
      final box = Hive.box<Wishlist>(_wishlistsBoxName);
      return box.get(id);
    } catch (e) {

      return null;
    }
  }

  /// Create a new wishlist and return its ID
  Future<String> createWishlist(Wishlist wishlist) async {
    try {
      final box = Hive.box<Wishlist>(_wishlistsBoxName);

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

      return id;
    } catch (e) {

      rethrow;
    }
  }

  /// Update an existing wishlist
  Future<void> updateWishlist(Wishlist wishlist) async {
    try {
      final box = Hive.box<Wishlist>(_wishlistsBoxName);

      final updatedWishlist = wishlist.copyWith(updatedAt: DateTime.now());

      await box.put(wishlist.id, updatedWishlist);

    } catch (e) {

      rethrow;
    }
  }

  /// Delete a wishlist and all its items
  Future<void> deleteWishlist(String id) async {
    try {
      final wishlistBox = Hive.box<Wishlist>(_wishlistsBoxName);
      final itemsBox = Hive.box<WishlistItem>(_itemsBoxName);

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

    } catch (e) {

      rethrow;
    }
  }

  /// Get all items for a specific wishlist
  Future<List<WishlistItem>> getWishlistItems(String wishlistId) async {
    try {
      final box = Hive.box<WishlistItem>(_itemsBoxName);
      final items = box.values
          .where((item) => item.wishlistId == wishlistId)
          .toList();

      return items;
    } catch (e) {

      return [];
    }
  }

  /// Add a new item to a wishlist and return its ID
  Future<String> addWishlistItem(String wishlistId, WishlistItem item) async {
    try {
      final itemsBox = Hive.box<WishlistItem>(_itemsBoxName);

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

      return id;
    } catch (e) {

      rethrow;
    }
  }

  /// Update an existing wishlist item
  Future<void> updateWishlistItem(WishlistItem item) async {
    try {
      final box = Hive.box<WishlistItem>(_itemsBoxName);

      final updatedItem = item.copyWith(updatedAt: DateTime.now());

      await box.put(item.id, updatedItem);

      // Update parent wishlist's timestamp
      final wishlistBox = Hive.box<Wishlist>(_wishlistsBoxName);
      final wishlist = wishlistBox.get(item.wishlistId);
      if (wishlist != null) {
        await updateWishlist(wishlist);
      }

    } catch (e) {

      rethrow;
    }
  }

  /// Delete a wishlist item
  Future<void> deleteWishlistItem(String itemId) async {
    try {
      final itemsBox = Hive.box<WishlistItem>(_itemsBoxName);
      final wishlistBox = Hive.box<Wishlist>(_wishlistsBoxName);

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

      } else {

      }
    } catch (e) {

      rethrow;
    }
  }

  /// Clear all guest data (used after migration to account)
  Future<void> clearAllGuestData() async {
    try {
      final wishlistBox = Hive.box<Wishlist>(_wishlistsBoxName);
      final itemsBox = Hive.box<WishlistItem>(_itemsBoxName);

      await wishlistBox.clear();
      await itemsBox.clear();

    } catch (e) {

      rethrow;
    }
  }

  /// Check if guest has any data
  Future<bool> hasGuestData() async {
    try {
      final box = Hive.box<Wishlist>(_wishlistsBoxName);
      return box.isNotEmpty;
    } catch (e) {

      return false;
    }
  }

  /// Get count of guest wishlists
  Future<int> getWishlistCount() async {
    try {
      final box = Hive.box<Wishlist>(_wishlistsBoxName);
      return box.length;
    } catch (e) {

      return 0;
    }
  }

  /// Initialize dummy data for guest users (in both English and Arabic)
  /// This method creates sample wishlists with items to demonstrate the app
  Future<void> initializeDummyData(String languageCode) async {
    try {
      // Check if data already exists
      final box = Hive.box<Wishlist>(_wishlistsBoxName);
      if (box.isNotEmpty) {
        return; // Data already exists, don't overwrite
      }

      final now = DateTime.now();
      final itemsBox = Hive.box<WishlistItem>(_itemsBoxName);

      // Wishlist 1: Graduation Goals
      final graduationWishlistId = 'guest_graduation_${now.millisecondsSinceEpoch}';
      final graduationWishlist = Wishlist(
        id: graduationWishlistId,
        userId: 'guest',
        type: WishlistType.public,
        name: languageCode == 'ar' ? 'أهداف التخرج' : 'Graduation Goals',
        description: languageCode == 'ar' 
          ? 'الأجهزة التي أحتاجها لبدء مسيرتي المهنية'
          : 'Tech essentials for starting my career',
        visibility: WishlistVisibility.friends,
        category: 'Graduation',
        items: [],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
      );
      await box.put(graduationWishlistId, graduationWishlist);

      // Items for Graduation Wishlist
      final macBookItem = WishlistItem(
        id: '${graduationWishlistId}_item1',
        wishlistId: graduationWishlistId,
        name: 'MacBook',
        description: languageCode == 'ar' ? 'شريحة M2، شاشة 13 بوصة' : 'M2 chip, 13-inch display',
        link: 'https://apple.com',
        priority: ItemPriority.high,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 25)),
      );
      await itemsBox.put(macBookItem.id, macBookItem);

      final monitorItem = WishlistItem(
        id: '${graduationWishlistId}_item2',
        wishlistId: graduationWishlistId,
        name: 'Monitor',
        description: languageCode == 'ar' ? 'شاشة 4K IPS مقاس 27 بوصة' : '27" 4K IPS display',
        link: 'https://amazon.com',
        priority: ItemPriority.medium,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
      );
      await itemsBox.put(monitorItem.id, monitorItem);

      final headsetItem = WishlistItem(
        id: '${graduationWishlistId}_item3',
        wishlistId: graduationWishlistId,
        name: 'Headset',
        description: languageCode == 'ar' ? 'سماعات لاسلكية بإلغاء الضوضاء' : 'Wireless noise-cancelling',
        priority: ItemPriority.medium,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      );
      await itemsBox.put(headsetItem.id, headsetItem);

      // Wishlist 2: My 25th Birthday
      final birthdayWishlistId = 'guest_birthday_${now.millisecondsSinceEpoch}';
      final birthdayWishlist = Wishlist(
        id: birthdayWishlistId,
        userId: 'guest',
        type: WishlistType.public,
        name: languageCode == 'ar' ? 'عيد ميلادي الخامس والعشرون' : 'My 25th Birthday',
        description: languageCode == 'ar'
          ? 'هدايا عيد ميلادي المميز'
          : 'Special gifts for my birthday',
        visibility: WishlistVisibility.friends,
        category: 'Birthday',
        items: [],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 3)),
      );
      await box.put(birthdayWishlistId, birthdayWishlist);

      // Items for Birthday Wishlist
      final watchItem = WishlistItem(
        id: '${birthdayWishlistId}_item1',
        wishlistId: birthdayWishlistId,
        name: 'Watch',
        description: languageCode == 'ar' ? 'ساعة ذكية مع تتبع اللياقة البدنية' : 'Smartwatch with fitness tracking',
        link: 'https://apple.com',
        priority: ItemPriority.high,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 18)),
      );
      await itemsBox.put(watchItem.id, watchItem);

      final cakeItem = WishlistItem(
        id: '${birthdayWishlistId}_item2',
        wishlistId: birthdayWishlistId,
        name: 'Cake',
        description: languageCode == 'ar' ? 'كعكة عيد ميلاد مخصصة' : 'Custom birthday cake',
        priority: ItemPriority.medium,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 12)),
      );
      await itemsBox.put(cakeItem.id, cakeItem);

      final perfumeItem = WishlistItem(
        id: '${birthdayWishlistId}_item3',
        wishlistId: birthdayWishlistId,
        name: 'Perfume',
        description: languageCode == 'ar' ? 'عطر مميز' : 'Signature fragrance',
        priority: ItemPriority.low,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      );
      await itemsBox.put(perfumeItem.id, perfumeItem);

      // Wishlist 3: Dream Wedding
      final weddingWishlistId = 'guest_wedding_${now.millisecondsSinceEpoch}';
      final weddingWishlist = Wishlist(
        id: weddingWishlistId,
        userId: 'guest',
        type: WishlistType.public,
        name: languageCode == 'ar' ? 'حلم الزفاف' : 'Dream Wedding',
        description: languageCode == 'ar'
          ? 'كل ما نحتاجه لحفل زفاف مثالي'
          : 'Everything we need for the perfect wedding',
        visibility: WishlistVisibility.friends,
        category: 'Wedding',
        items: [],
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 2)),
      );
      await box.put(weddingWishlistId, weddingWishlist);

      // Items for Wedding Wishlist
      final mixerItem = WishlistItem(
        id: '${weddingWishlistId}_item1',
        wishlistId: weddingWishlistId,
        name: 'Mixer',
        description: languageCode == 'ar' ? 'خلاط وقوف للخبز' : 'Stand mixer for baking',
        priority: ItemPriority.high,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 12)),
      );
      await itemsBox.put(mixerItem.id, mixerItem);

      final coffeeItem = WishlistItem(
        id: '${weddingWishlistId}_item2',
        wishlistId: weddingWishlistId,
        name: 'Coffee',
        description: languageCode == 'ar' ? 'آلة إسبريسو' : 'Espresso machine',
        link: 'https://amazon.com',
        priority: ItemPriority.medium,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      );
      await itemsBox.put(coffeeItem.id, coffeeItem);

      final decorItem = WishlistItem(
        id: '${weddingWishlistId}_item3',
        wishlistId: weddingWishlistId,
        name: 'Decor',
        description: languageCode == 'ar' ? 'زينة مركزية لحفل الزفاف' : 'Wedding centerpieces',
        priority: ItemPriority.medium,
        status: ItemStatus.desired,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      );
      await itemsBox.put(decorItem.id, decorItem);

    } catch (e) {
      debugPrint('Error initializing dummy data: $e');
    }
  }
}
