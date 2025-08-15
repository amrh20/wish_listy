class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final PrivacySettings privacySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.privacySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profile_picture'],
      privacySettings: PrivacySettings.fromJson(json['privacy_settings'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'privacy_settings': privacySettings.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicture,
    PrivacySettings? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PrivacySettings {
  final WishlistVisibility publicWishlistVisibility;
  final bool allowFriendRequests;
  final bool showOnlineStatus;
  final bool allowEventInvitations;

  PrivacySettings({
    required this.publicWishlistVisibility,
    this.allowFriendRequests = true,
    this.showOnlineStatus = true,
    this.allowEventInvitations = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      publicWishlistVisibility: WishlistVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['public_wishlist_visibility'],
        orElse: () => WishlistVisibility.friends,
      ),
      allowFriendRequests: json['allow_friend_requests'] ?? true,
      showOnlineStatus: json['show_online_status'] ?? true,
      allowEventInvitations: json['allow_event_invitations'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_wishlist_visibility': publicWishlistVisibility.toString().split('.').last,
      'allow_friend_requests': allowFriendRequests,
      'show_online_status': showOnlineStatus,
      'allow_event_invitations': allowEventInvitations,
    };
  }

  PrivacySettings copyWith({
    WishlistVisibility? publicWishlistVisibility,
    bool? allowFriendRequests,
    bool? showOnlineStatus,
    bool? allowEventInvitations,
  }) {
    return PrivacySettings(
      publicWishlistVisibility: publicWishlistVisibility ?? this.publicWishlistVisibility,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowEventInvitations: allowEventInvitations ?? this.allowEventInvitations,
    );
  }
}

enum WishlistVisibility {
  public,
  friends,
  private,
}