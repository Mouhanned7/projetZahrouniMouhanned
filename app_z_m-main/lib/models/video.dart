class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String category;
  final bool isPublic;
  final String authorId;
  final String? targetUserId;
  final int viewsCount;
  final String duration;
  final DateTime createdAt;
  // Joined
  final String? authorName;
  final String? authorAvatar;

  Video({
    required this.id,
    required this.title,
    this.description = '',
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.category = '',
    this.isPublic = true,
    required this.authorId,
    this.targetUserId,
    this.viewsCount = 0,
    this.duration = '',
    DateTime? createdAt,
    this.authorName,
    this.authorAvatar,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Video.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    return Video(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isPublic: json['is_public'] as bool? ?? true,
      authorId: json['author_id'] as String,
      targetUserId: json['target_user_id'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      duration: json['duration'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      authorName: profileData?['full_name'] as String?,
      authorAvatar: profileData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'is_public': isPublic,
      'author_id': authorId,
      'target_user_id': targetUserId,
      'duration': duration,
    };
  }
}
