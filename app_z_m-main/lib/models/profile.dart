class Profile {
  final String id;
  final String fullName;
  final String university;
  final String role;
  final String avatarUrl;
  final String bio;
  final int resourcesUploaded;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.fullName,
    this.university = '',
    this.role = 'user',
    this.avatarUrl = '',
    this.bio = '',
    this.resourcesUploaded = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      university: json['university'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      avatarUrl: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      resourcesUploaded: json['resources_uploaded'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'university': university,
      'role': role,
      'avatar_url': avatarUrl,
      'bio': bio,
      'resources_uploaded': resourcesUploaded,
    };
  }
}
