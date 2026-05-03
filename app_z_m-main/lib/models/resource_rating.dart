class ResourceRating {
  final String id;
  final String resourceId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  // Joined
  final String? userName;
  final String? userAvatar;

  ResourceRating({
    required this.id,
    required this.resourceId,
    required this.userId,
    required this.rating,
    this.comment = '',
    DateTime? createdAt,
    this.userName,
    this.userAvatar,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ResourceRating.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    return ResourceRating(
      id: json['id'] as String,
      resourceId: json['resource_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      userName: profileData?['full_name'] as String?,
      userAvatar: profileData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'resource_id': resourceId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
    };
  }
}
