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
  final RxBool isFriend = false.obs;
  final Rx<FriendRelationshipStatus> relationshipStatus =
      FriendRelationshipStatus.none.obs;
  final RxString incomingRequestId = ''.obs;
  final RxString outgoingRequestId = ''.obs;
  final RxBool hasIncomingRequest = false.obs;
  final RxBool hasOutgoingRequest = false.obs;
  final RxBool isBlockedByMe = false.obs;

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
      _syncRelationshipFromProfile();
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
      _syncRelationshipFromProfile();
    } finally {
      isLoading.value = false;
    }
  }

  void _syncRelationshipFromProfile() {
    final p = profile.value;
    isBlockedByMe.value = p?.isBlockedByMe ?? false;

    final rel = p?.relationship;
    if (rel != null) {
      relationshipStatus.value = rel.status;
      isFriend.value = rel.isFriend;
      incomingRequestId.value = rel.incomingRequestId ?? '';
      outgoingRequestId.value = rel.outgoingRequestId ?? '';
      hasIncomingRequest.value =
          rel.status == FriendRelationshipStatus.incomingRequest &&
              (rel.incomingRequestId?.isNotEmpty ?? false);
      hasOutgoingRequest.value =
          rel.status == FriendRelationshipStatus.outgoingRequest &&
              (rel.outgoingRequestId?.isNotEmpty ?? false);
      return;
    }

    // Backwards-compatible fallback if relationship isn't provided.
    final legacyIsFriend = p?.friendshipStatus.isFriend ?? false;
    isFriend.value = legacyIsFriend;
    relationshipStatus.value =
        legacyIsFriend ? FriendRelationshipStatus.friends : FriendRelationshipStatus.none;
    incomingRequestId.value = '';
    outgoingRequestId.value = '';
    hasIncomingRequest.value = false;
    hasOutgoingRequest.value = false;
  }

  Future<void> acceptIncomingRequest() async {
    final requestId = incomingRequestId.value.trim();
    if (requestId.isEmpty) return;
    await _friendsRepository.acceptFriendRequest(requestId: requestId);

    // Optimistic update (UI instant)
    relationshipStatus.value = FriendRelationshipStatus.friends;
    isFriend.value = true;
    incomingRequestId.value = '';
    outgoingRequestId.value = '';
    hasIncomingRequest.value = false;
    hasOutgoingRequest.value = false;

    // Refresh from profile (source of truth now contains relationship)
    await fetchProfile();
  }

  Future<void> declineIncomingRequest() async {
    final requestId = incomingRequestId.value.trim();
    if (requestId.isEmpty) return;
    await _friendsRepository.rejectFriendRequest(requestId: requestId);
    relationshipStatus.value = FriendRelationshipStatus.none;
    isFriend.value = false;
    incomingRequestId.value = '';
    hasIncomingRequest.value = false;
    await fetchProfile();
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
      final res = await _friendsRepository.sendFriendRequest(toUserId: friendId);
      // Try to capture requestId for outgoing state (best effort)
      final id = (res['_id'] ?? res['id'] ?? res['requestId'] ?? res['request_id'])?.toString();
      outgoingRequestId.value = (id != null && id.isNotEmpty) ? id : outgoingRequestId.value;
      relationshipStatus.value = FriendRelationshipStatus.outgoingRequest;
      hasOutgoingRequest.value = true;
    } finally {
      isSendingFriendRequest.value = false;
    }
  }

  /// Cancel outgoing friend request.
  Future<void> cancelFriendRequest() async {
    final requestId = outgoingRequestId.value.trim();
    if (requestId.isEmpty) return;

    await _friendsRepository.cancelFriendRequest(requestId: requestId);

    // Update state to reflect cancellation
    relationshipStatus.value = FriendRelationshipStatus.none;
    hasOutgoingRequest.value = false;
    outgoingRequestId.value = '';

    // Refresh profile to get latest state
    await fetchProfile();
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

extension _FirstWhereOrNullExt<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}


