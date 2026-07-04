class ChatParticipant {
  final String id;
  final String fullName;
  final String username;
  final String? handle;
  final String? profileImage;
  final bool isOnline;

  const ChatParticipant({
    required this.id,
    required this.fullName,
    required this.username,
    this.handle,
    this.profileImage,
    this.isOnline = false,
  });

  static String _toStringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    if (json['user'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(json['user'] as Map<String, dynamic>);
    }
    return json;
  }

  static String _resolveFullName(Map<String, dynamic> json) {
    final direct = _toStringValue(
      json['fullName'] ?? json['name'] ?? json['displayName'],
    ).trim();
    if (direct.isNotEmpty) return direct;

    final firstName = _toStringValue(
      json['firstName'] ?? json['first_name'],
    ).trim();
    final lastName = _toStringValue(
      json['lastName'] ?? json['last_name'],
    ).trim();
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;

    return '';
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeJson(json);

    return ChatParticipant(
      id: _toStringValue(
        normalized['_id'] ??
            normalized['id'] ??
            normalized['userId'] ??
            normalized['participantId'],
      ),
      fullName: _resolveFullName(normalized),
      username: _toStringValue(normalized['username']),
      handle: normalized['handle']?.toString(),
      profileImage:
          (normalized['profileImage'] ??
                  normalized['profile_image'] ??
                  normalized['avatarUrl'] ??
                  normalized['avatar'])
              ?.toString(),
      isOnline: normalized['isOnline'] == true || normalized['online'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'username': username,
      if (handle != null) 'handle': handle,
      if (profileImage != null) 'profileImage': profileImage,
      'isOnline': isOnline,
    };
  }

  ChatParticipant copyWith({
    String? id,
    String? fullName,
    String? username,
    String? handle,
    String? profileImage,
    bool? isOnline,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      profileImage: profileImage ?? this.profileImage,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    if (handle != null && handle!.trim().isNotEmpty) {
      final normalized = handle!.trim();
      return normalized.startsWith('@') ? normalized : '@$normalized';
    }
    return 'User';
  }

  bool get hasResolvedName => displayName != 'User';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
