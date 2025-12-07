import 'package:flutter/material.dart';
import 'package:wish_listy/features/auth/data/models/user_model.dart';
import 'package:wish_listy/features/wishlists/data/models/wish.dart';
import 'package:wish_listy/features/events/data/models/event.dart';
import 'app_colors.dart';

class MockData {
  static final User currentUser = User(
    id: '1',
    name: 'Ahmed Hassan',
    email: 'ahmed@example.com',
    profilePicture:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    privacySettings: PrivacySettings(
      publicWishlistVisibility: WishlistVisibility.friends,
      allowFriendRequests: true,
      showOnlineStatus: true,
      allowEventInvitations: true,
    ),
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  static List<Wish> get wishes => [
    Wish(
      id: '1',
      title: 'Noise Cancelling Headphones',
      description: 'Sony WH-1000XM4',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300&h=200&fit=crop',
      price: 299.99,
      priority: WishPriority.high,
      isFavorite: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Electronics',
    ),
    Wish(
      id: '2',
      title: 'Leather Wallet',
      description: 'Minimalist design with RFID protection',
      imageUrl:
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=300&h=200&fit=crop',
      price: 45.00,
      priority: WishPriority.medium,
      isFavorite: false,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Accessories',
    ),
    Wish(
      id: '3',
      title: 'Smart Watch',
      description: 'Apple Watch Series 9',
      imageUrl:
          'https://images.unsplash.com/photo-1544117519-31a4b719223d?w=300&h=200&fit=crop',
      price: 399.99,
      priority: WishPriority.high,
      isFavorite: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Electronics',
    ),
    Wish(
      id: '4',
      title: 'Running Shoes',
      description: 'Nike Air Zoom Pegasus 40',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&h=200&fit=crop',
      price: 129.99,
      priority: WishPriority.low,
      isFavorite: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      category: 'Sports',
    ),
  ];

  static List<Event> get events => [
    Event(
      id: '1',
      title: "Noha's Birthday",
      description: 'Birthday celebration with friends and family',
      date: DateTime.now().add(const Duration(days: 5)),
      icon: '🎂',
      iconColor: Colors.amber,
      participants: [
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=50&h=50&fit=crop&crop=face',
      ],
    ),
    Event(
      id: '2',
      title: 'My Graduation',
      description: 'University graduation ceremony',
      date: DateTime.now().add(const Duration(days: 12)),
      icon: '🎓',
      iconColor: Colors.blue,
      participants: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=50&h=50&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=50&h=50&fit=crop&crop=face',
      ],
    ),
    Event(
      id: '3',
      title: 'Summer Vacation',
      description: 'Family trip to the beach',
      date: DateTime.now().add(const Duration(days: 25)),
      icon: '🏖️',
      iconColor: Colors.orange,
      participants: [
        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
      ],
    ),
  ];

  static List<String> get categories => [
    'All',
    'Electronics',
    'Fashion',
    'Books',
    'Sports',
    'Home & Garden',
    'Beauty',
    'Toys & Games',
    'Automotive',
    'Health & Wellness',
  ];

  static List<Color> get categoryColors => [
    AppColors.primary,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.accent,
    AppColors.primaryLight,
    AppColors.successLight,
    AppColors.warning,
    AppColors.info,
    AppColors.accentLight,
  ];
}
