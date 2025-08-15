class User {
  final String id;
  final String name;
  final String profileImage;
  final int wishCount;
  final int reservedCount;
  final int friendsCount;
  final int eventsCount;

  User({
    required this.id,
    required this.name,
    required this.profileImage,
    this.wishCount = 0,
    this.reservedCount = 0,
    this.friendsCount = 0,
    this.eventsCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      profileImage: json['profileImage'],
      wishCount: json['wishCount'] ?? 0,
      reservedCount: json['reservedCount'] ?? 0,
      friendsCount: json['friendsCount'] ?? 0,
      eventsCount: json['eventsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'wishCount': wishCount,
      'reservedCount': reservedCount,
      'friendsCount': friendsCount,
      'eventsCount': eventsCount,
    };
  }
}
