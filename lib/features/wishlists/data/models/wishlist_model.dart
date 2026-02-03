// Import User model for reservedBy
import 'package:wish_listy/features/friends/data/models/user_model.dart' as friends;

class Wishlist {
  final String id;
  final String userId;
  final WishlistType type;
  final String? eventId;
  final String name;
  final String? description;
  final WishlistVisibility visibility;
  final String? category; // Added category field
  final List<WishlistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final friends.User? owner; // Owner of the wishlist (for nested parsing)
  final int? _itemCountFromApi; // Store itemCount from API if items array is not populated

  Wishlist({
    required this.id,
    required this.userId,
    required this.type,
    this.eventId,
    required this.name,
    this.description,
    required this.visibility,
    this.category,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.owner,
    int? itemCountFromApi,
  }) : _itemCountFromApi = itemCountFromApi;

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    // Parse owner if available (nested object)
    friends.User? owner;
    if (json['owner'] != null && json['owner'] is Map<String, dynamic>) {
      try {
        owner = friends.User.fromJson(json['owner'] as Map<String, dynamic>);
      } catch (e) {
        owner = null;
      }
    }
    
    // Parse items array
    final itemsList = (json['items'] as List<dynamic>?)
        ?.map((item) {
          try {
            return WishlistItem.fromJson(item);
          } catch (e) {
            return null;
          }
        })
        .whereType<WishlistItem>()
        .toList() ?? [];
    
    // Try to get itemCount from API response if items array is empty/null
    // This is useful for dashboard responses where items might be omitted for performance
    int? itemCountFromApi;
    if (itemsList.isEmpty) {
      final itemCountRaw = json['itemCount'] ?? json['item_count'] ?? json['totalItems'] ?? json['total_items'];
      if (itemCountRaw != null) {
        itemCountFromApi = (itemCountRaw is num) ? itemCountRaw.toInt() : int.tryParse(itemCountRaw.toString());
      }
    }
    
    return Wishlist(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      type: WishlistType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type']?.toString(),
        orElse: () => WishlistType.public,
      ),
      eventId: json['event_id']?.toString() ?? json['eventId']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      visibility: WishlistVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['visibility']?.toString(),
        orElse: () => WishlistVisibility.friends,
      ),
      category: json['category']?.toString(),
      items: itemsList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'].toString())
              : DateTime.now()),
      owner: owner,
      itemCountFromApi: itemCountFromApi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'event_id': eventId,
      'name': name,
      'description': description,
      'visibility': visibility.toString().split('.').last,
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Wishlist copyWith({
    String? id,
    String? userId,
    WishlistType? type,
    String? eventId,
    String? name,
    String? description,
    WishlistVisibility? visibility,
    String? category,
    List<WishlistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    friends.User? owner,
    int? itemCountFromApi,
  }) {
    return Wishlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      category: category ?? this.category,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      itemCountFromApi: itemCountFromApi ?? this._itemCountFromApi,
    );
  }

  int get totalItems {
    // If items array is populated, use its length (most accurate)
    if (items.isNotEmpty) {
      return items.length;
    }
    // Otherwise, fall back to itemCount from API if available
    if (_itemCountFromApi != null) {
      return _itemCountFromApi!;
    }
    // Default to 0 if neither is available
    return 0;
  }
  int get purchasedItems =>
      items.where((item) => item.isPurchasedValue).length;
  int get reservedItems =>
      items.where((item) => item.isReservedValue).length;
  int get availableItems =>
      items.where((item) => !item.isPurchasedValue && !item.isReservedValue).length;

  @override
  String toString() {
    return 'Wishlist(id: $id, name: $name, type: $type, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wishlist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class WishlistItem {
  final String id;
  final String wishlistId;
  final String name;
  final String? description;
  final String? link;
  final PriceRange? priceRange;
  final String? imageUrl;
  final ItemPriority priority;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReceived; // Whether the item has been received
  final friends.User? reservedBy; // User who reserved the item (nullable)
  final Wishlist? wishlist; // Nested wishlist object (for reservations API)
  
  // Direct API fields (with fallback to computed values)
  final bool? isPurchased; // Whether the item is purchased (from API)
  final bool? isReservedByMe; // Whether the item is reserved by current user (from API)
  final bool? isReserved; // Whether the item is reserved (from API)
  final int? availableQuantity; // Available quantity (from API)

  // Computed properties (fallback if API fields are null)
  bool get isPurchasedValue => isPurchased ?? isReceived;
  bool get isReservedValue => isReserved ?? (reservedBy != null);
  String get price => priceRange?.toString() ?? 'Price not specified';

  WishlistItem({
    required this.id,
    required this.wishlistId,
    required this.name,
    this.description,
    this.link,
    this.priceRange,
    this.imageUrl,
    this.priority = ItemPriority.medium,
    this.status = ItemStatus.desired,
    required this.createdAt,
    required this.updatedAt,
    this.isReceived = false,
    this.reservedBy,
    this.wishlist,
    this.isPurchased,
    this.isReservedByMe,
    this.isReserved,
    this.availableQuantity,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (from API) and snake_case (from local storage)
    final id = json['id']?.toString() ?? 
               json['_id']?.toString() ?? 
               '';
    
    // Parse wishlistId - handle both string ID and object with _id/id field
    String wishlistId = '';
    if (json['wishlistId'] != null) {
      wishlistId = json['wishlistId'].toString();
    } else if (json['wishlist_id'] != null) {
      wishlistId = json['wishlist_id'].toString();
    } else if (json['wishlist'] != null) {
      // Handle case where wishlist is an object (Map) instead of string ID
      if (json['wishlist'] is Map<String, dynamic>) {
        final wishlistObj = json['wishlist'] as Map<String, dynamic>;
        wishlistId = wishlistObj['_id']?.toString() ?? 
                     wishlistObj['id']?.toString() ?? 
                     '';
      } else {
        wishlistId = json['wishlist'].toString();
      }
    }
    
    // Parse status - support both 'status' and 'itemStatus' fields
    ItemStatus status = ItemStatus.desired;
    final statusStr = (json['itemStatus']?.toString() ?? 
                      json['status']?.toString() ?? 
                      '').toLowerCase();
    
    // Check if item is reserved using isReserved field or totalReserved > 0
    final isReserved = json['isReserved'] as bool? ?? 
                      (json['totalReserved'] as int? ?? 0) > 0;
    
    // If isReserved is true, set status to reserved
    if (isReserved) {
      status = ItemStatus.reserved;
    } else if (statusStr.isNotEmpty) {
      status = ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == statusStr,
        orElse: () => ItemStatus.desired,
      );
    }
    
    // Parse priority
    final priorityStr = json['priority']?.toString().toLowerCase() ?? 'medium';
    final priority = ItemPriority.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == priorityStr,
      orElse: () => ItemPriority.medium,
    );
    
    // Parse dates: support both camelCase and snake_case
    DateTime createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime updatedAt;
    if (json['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(json['updatedAt'].toString());
      } catch (e) {
        updatedAt = DateTime.now();
      }
    } else if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'].toString());
      } catch (e) {
        updatedAt = DateTime.now();
      }
    } else {
      updatedAt = DateTime.now();
    }
    
    // Parse link: support both 'url' and 'link'
    final link = json['link']?.toString() ?? 
                 json['url']?.toString();
    
    // Parse imageUrl: support both camelCase and snake_case
    final imageUrl = json['imageUrl']?.toString() ?? 
                     json['image_url']?.toString() ?? 
                     json['image']?.toString();
    
    // Parse priceRange: support both camelCase and snake_case
    PriceRange? priceRange;
    if (json['priceRange'] != null) {
      try {
        priceRange = PriceRange.fromJson(json['priceRange'] as Map<String, dynamic>);
      } catch (e) {
        priceRange = null;
      }
    } else if (json['price_range'] != null) {
      try {
        priceRange = PriceRange.fromJson(json['price_range'] as Map<String, dynamic>);
      } catch (e) {
        priceRange = null;
      }
    }
    
    // Parse isReceived: support both camelCase and snake_case
    final isReceived = json['isReceived'] as bool? ?? 
                      json['is_received'] as bool? ?? 
                      false;
    
    // Parse isPurchased: direct from API, fallback to isReceived
    final isPurchased = json['isPurchased'] as bool? ?? 
                       json['is_purchased'] as bool?;
    
    // Parse isReservedByMe: direct from API
    final isReservedByMe = json['isReservedByMe'] as bool? ?? 
                          json['is_reserved_by_me'] as bool?;
    
    // Parse isReserved: direct from API (already parsed above, but store separately)
    final isReservedFromApi = json['isReserved'] as bool? ?? 
                             json['is_reserved'] as bool?;
    
    // Parse availableQuantity: direct from API
    final availableQuantity = json['availableQuantity'] as int? ?? 
                            json['available_quantity'] as int?;
    
    // Parse reservedBy: support both camelCase and snake_case
    friends.User? reservedBy;
    if (json['reservedBy'] != null && json['reservedBy'] is Map) {
      try {
        reservedBy = friends.User.fromJson(json['reservedBy'] as Map<String, dynamic>);
      } catch (e) {
        reservedBy = null;
      }
    } else if (json['reserved_by'] != null && json['reserved_by'] is Map) {
      try {
        reservedBy = friends.User.fromJson(json['reserved_by'] as Map<String, dynamic>);
      } catch (e) {
        reservedBy = null;
      }
    }
    
    // Parse nested wishlist object (for reservations API)
    Wishlist? wishlist;
    if (json['wishlist'] != null && json['wishlist'] is Map<String, dynamic>) {
      try {
        wishlist = Wishlist.fromJson(json['wishlist'] as Map<String, dynamic>);
      } catch (e) {
        wishlist = null;
      }
    }
    
    return WishlistItem(
      id: id,
      wishlistId: wishlistId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      link: link,
      priceRange: priceRange,
      imageUrl: imageUrl,
      priority: priority,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isReceived: isReceived,
      reservedBy: reservedBy,
      wishlist: wishlist,
      isPurchased: isPurchased,
      isReservedByMe: isReservedByMe,
      isReserved: isReservedFromApi,
      availableQuantity: availableQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wishlist_id': wishlistId,
      'name': name,
      'description': description,
      'link': link,
      'price_range': priceRange?.toJson(),
      'image_url': imageUrl,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WishlistItem copyWith({
    String? id,
    String? wishlistId,
    String? name,
    String? description,
    String? link,
    PriceRange? priceRange,
    String? imageUrl,
    ItemPriority? priority,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReceived,
    friends.User? reservedBy,
    Wishlist? wishlist,
    bool? isPurchased,
    bool? isReservedByMe,
    bool? isReserved,
    int? availableQuantity,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      wishlistId: wishlistId ?? this.wishlistId,
      name: name ?? this.name,
      description: description ?? this.description,
      link: link ?? this.link,
      priceRange: priceRange ?? this.priceRange,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReceived: isReceived ?? this.isReceived,
      reservedBy: reservedBy ?? this.reservedBy,
      wishlist: wishlist ?? this.wishlist,
      isPurchased: isPurchased ?? this.isPurchased,
      isReservedByMe: isReservedByMe ?? this.isReservedByMe,
      isReserved: isReserved ?? this.isReserved,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  @override
  String toString() {
    return 'WishlistItem(id: $id, name: $name, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PriceRange {
  final double? minPrice;
  final double? maxPrice;
  final String currency;

  PriceRange({this.minPrice, this.maxPrice, this.currency = 'USD'});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      minPrice: json['min_price']?.toDouble(),
      maxPrice: json['max_price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {'min_price': minPrice, 'max_price': maxPrice, 'currency': currency};
  }

  @override
  String toString() {
    if (minPrice != null && maxPrice != null) {
      return '${minPrice!.toStringAsFixed(0)} - ${maxPrice!.toStringAsFixed(0)} $currency';
    } else if (minPrice != null) {
      return 'From ${minPrice!.toStringAsFixed(0)} $currency';
    } else if (maxPrice != null) {
      return 'Up to ${maxPrice!.toStringAsFixed(0)} $currency';
    } else {
      return 'Price not specified';
    }
  }

  String get displayPrice {
    if (minPrice != null && maxPrice != null) {
      return '\$$minPrice - \$$maxPrice';
    } else if (minPrice != null) {
      return 'From \$$minPrice';
    } else if (maxPrice != null) {
      return 'Up to \$$maxPrice';
    }
    return 'Price not specified';
  }
}

enum WishlistType { public, event }

enum WishlistVisibility { public, friends, private }

enum ItemPriority { low, medium, high, urgent }

enum ItemStatus { desired, reserved, purchased }
