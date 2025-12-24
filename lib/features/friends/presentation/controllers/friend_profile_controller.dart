import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/features/friends/data/models/friend_event_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_profile_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_wishlist_model.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';

class FriendProfileController extends GetxController {
  final FriendsRepository _friendsRepository;
  final EventRepository _eventRepository;

  final String friendId;

  FriendProfileController({
    required this.friendId,
    FriendsRepository? friendsRepository,
    EventRepository? eventRepository,
  })  : _friendsRepository = friendsRepository ?? FriendsRepository(),
        _eventRepository = eventRepository ?? EventRepository();

  final RxList<FriendWishlistModel> wishlists = <FriendWishlistModel>[].obs;
  final RxList<FriendEventModel> events = <FriendEventModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<FriendProfileModel?> profile = Rx<FriendProfileModel?>(null);
  final RxBool isSendingFriendRequest = false.obs;
  final RxBool friendRequestSent = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Auto load when controller is created.
    loadAll();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final result = await _friendsRepository.getFriendProfile(friendId);
      profile.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWishlists() async {
    isLoading.value = true;
    try {
      final result = await _friendsRepository.getFriendWishlists(friendId);
      wishlists.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchEvents() async {
    isLoading.value = true;
    try {
      final result = await _friendsRepository.getFriendEvents(friendId);
      events.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _friendsRepository.getFriendProfile(friendId),
        _friendsRepository.getFriendWishlists(friendId),
        _friendsRepository.getFriendEvents(friendId),
      ]);
      profile.value = results[0] as FriendProfileModel;
      wishlists.assignAll(results[1] as List<FriendWishlistModel>);
      events.assignAll(results[2] as List<FriendEventModel>);
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper: Category icon + color for wishlists grid.
  ({IconData icon, Color color, Color background}) getCategoryIcon(String? category) {
    final c = (category ?? 'other').trim().toLowerCase();
    if (c == 'birthday') {
      return (
        icon: Icons.cake_rounded,
        color: Colors.orange.shade700,
        background: Colors.orange.shade50,
      );
    }
    if (c == 'wedding') {
      return (
        icon: Icons.favorite_rounded,
        color: Colors.teal.shade700,
        background: Colors.teal.shade50,
      );
    }
    if (c == 'graduation') {
      return (
        icon: Icons.school_rounded,
        color: Colors.lightBlue.shade700,
        background: Colors.lightBlue.shade50,
      );
    }
    return (
      icon: Icons.star_rounded,
      color: AppColors.primary,
      background: AppColors.cardPurple,
    );
  }

  IconData getPrivacyIcon(FriendWishlistPrivacy privacy) {
    switch (privacy) {
      case FriendWishlistPrivacy.private:
        return Icons.lock_outline_rounded;
      case FriendWishlistPrivacy.friends:
        return Icons.people_outline_rounded;
      case FriendWishlistPrivacy.public:
        return Icons.public_rounded;
      case FriendWishlistPrivacy.unknown:
      default:
        return Icons.public_rounded;
    }
  }

  /// Send friend request (no chat).
  Future<void> sendFriendRequest() async {
    if (isSendingFriendRequest.value) return;
    isSendingFriendRequest.value = true;
    try {
      await _friendsRepository.sendFriendRequest(toUserId: friendId);
      friendRequestSent.value = true;
    } finally {
      isSendingFriendRequest.value = false;
    }
  }

  /// RSVP from events list when invitation is pending.
  Future<void> respondToInvitation({
    required String eventId,
    required InvitationStatus status,
  }) async {
    // Optimistic update
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final current = events[idx];
      events[idx] = FriendEventModel(
        id: current.id,
        name: current.name,
        description: current.description,
        date: current.date,
        time: current.time,
        type: current.type,
        privacy: current.privacy,
        mode: current.mode,
        location: current.location,
        creator: current.creator,
        wishlist: current.wishlist,
        invitationStatus: status,
      );
    }

    final apiStatus = switch (status) {
      InvitationStatus.accepted => 'accepted',
      InvitationStatus.declined => 'declined',
      InvitationStatus.maybe => 'maybe',
      InvitationStatus.pending => 'pending',
      InvitationStatus.unknown => 'pending',
    };

    try {
      await _eventRepository.respondToEventInvitation(
        eventId: eventId,
        status: apiStatus,
      );
    } catch (_) {
      // Roll back by reloading events (keep it simple).
      await fetchEvents();
    }
  }
}


