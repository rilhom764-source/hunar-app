enum UserRole { client, worker }

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final UserRole role;
  final double latitude;
  final double longitude;
  final String city;
  final double rating;
  final int tasksCompleted;
  final int reviewsCount;
  final List<String> skills;
  final List<String> portfolioImages; // Фото-портфолио пользователя
  final DateTime createdAt;
  final bool isVerified;
  final bool isMasterVerified;
  final DateTime? masterVerifiedAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.bio,
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.rating = 0.0,
    this.tasksCompleted = 0,
    this.reviewsCount = 0,
    this.skills = const [],
    this.portfolioImages = const [],
    required this.createdAt,
    this.isVerified = false,
    this.isMasterVerified = false,
    this.masterVerifiedAt,
  });

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? bio,
    UserRole? role,
    double? latitude,
    double? longitude,
    String? city,
    double? rating,
    int? tasksCompleted,
    int? reviewsCount,
    List<String>? skills,
    List<String>? portfolioImages,
    bool? isVerified,
    bool? isMasterVerified,
    DateTime? masterVerifiedAt,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      skills: skills ?? this.skills,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
      isMasterVerified: isMasterVerified ?? this.isMasterVerified,
      masterVerifiedAt: masterVerifiedAt ?? this.masterVerifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'role': role.name,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'rating': rating,
    'tasksCompleted': tasksCompleted,
    'reviewsCount': reviewsCount,
    'skills': skills,
    'portfolioImages': portfolioImages,
    'createdAt': createdAt.toIso8601String(),
    'isVerified': isVerified,
    'isMasterVerified': isMasterVerified,
    'masterVerifiedAt': masterVerifiedAt?.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    role: UserRole.values.firstWhere((e) => e.name == json['role']),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    city: json['city'] as String,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    tasksCompleted: json['tasksCompleted'] as int? ?? 0,
    reviewsCount: json['reviewsCount'] as int? ?? 0,
    skills: (json['skills'] as List?)?.cast<String>() ?? [],
    portfolioImages: (json['portfolioImages'] as List?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    isVerified: json['isVerified'] as bool? ?? false,
    isMasterVerified: json['isMasterVerified'] as bool? ?? false,
    masterVerifiedAt: json['masterVerifiedAt'] != null
        ? DateTime.parse(json['masterVerifiedAt'] as String)
        : null,
  );
}
