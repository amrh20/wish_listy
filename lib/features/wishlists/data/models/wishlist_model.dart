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
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: WishlistType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WishlistType.public,
      ),
      eventId: json['event_id'],
      name: json['name'] ?? '',
      description: json['description'],
      visibility: WishlistVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['visibility'],
        orElse: () => WishlistVisibility.friends,
      ),
      category: json['category'],
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => WishlistItem.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
    );
  }

  int get totalItems => items.length;
  int get purchasedItems =>
      items.where((item) => item.status == ItemStatus.purchased).length;
  int get reservedItems =>
      items.where((item) => item.status == ItemStatus.reserved).length;
  int get availableItems =>
      items.where((item) => item.status == ItemStatus.desired).length;

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
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isPurchased => status == ItemStatus.purchased;
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
    this.purchasedBy,
    this.purchasedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (from API) and snake_case (from local storage)
    final id = json['id']?.toString() ?? 
               json['_id']?.toString() ?? 
               '';
    
    final wishlistId = json['wishlistId']?.toString() ?? 
                       json['wishlist_id']?.toString() ?? 
                       json['wishlist']?.toString() ?? 
                       '';
    
    // Parse status: support both isPurchased (boolean) and status (string)
    ItemStatus status = ItemStatus.desired;
    if (json['isPurchased'] == true) {
      status = ItemStatus.purchased;
    } else if (json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
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
    
    // Parse purchasedAt
    DateTime? purchasedAt;
    if (json['purchasedAt'] != null) {
      try {
        purchasedAt = DateTime.parse(json['purchasedAt'].toString());
      } catch (e) {
        purchasedAt = null;
      }
    } else if (json['purchased_at'] != null) {
      try {
        purchasedAt = DateTime.parse(json['purchased_at'].toString());
      } catch (e) {
        purchasedAt = null;
      }
    }
    
    // Parse link: support both 'url' and 'link'
    final link = json['link']?.toString() ?? 
                 json['url']?.toString();
    
    // Parse imageUrl: support both camelCase and snake_case
    final imageUrl = json['imageUrl']?.toString() ?? 
                     json['image_url']?.toString() ?? 
                     json['image']?.toString();
    
    // Parse purchasedBy: support both camelCase and snake_case
    final purchasedBy = json['purchasedBy']?.toString() ?? 
                        json['purchased_by']?.toString();
    
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
      purchasedBy: purchasedBy,
      purchasedAt: purchasedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
      'purchased_by': purchasedBy,
      'purchased_at': purchasedAt?.toIso8601String(),
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
    String? purchasedBy,
    DateTime? purchasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      purchasedBy: purchasedBy ?? this.purchasedBy,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
