import 'resource.dart';
import 'video.dart';

class SocialComment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String authorAvatar;

  SocialComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName = '',
    this.authorAvatar = '',
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return SocialComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      authorName: profileData?['full_name'] as String? ?? '',
      authorAvatar: profileData?['avatar_url'] as String? ?? '',
    );
  }
}

class SocialMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;

  const SocialMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
  });

  factory SocialMessage.fromJson(Map<String, dynamic> json) {
    return SocialMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class SocialContact {
  final String id;
  final String fullName;
  final String university;
  final String role;
  final String avatarUrl;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final bool isRecentlyActive;

  const SocialContact({
    required this.id,
    required this.fullName,
    this.university = '',
    this.role = 'Etudiant',
    this.avatarUrl = '',
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.isRecentlyActive = false,
  });

  String get initial {
    final text = fullName.trim();
    if (text.isEmpty) return '?';
    return text[0].toUpperCase();
  }

  SocialContact copyWith({
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    bool? isRecentlyActive,
  }) {
    return SocialContact(
      id: id,
      fullName: fullName,
      university: university,
      role: role,
      avatarUrl: avatarUrl,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isRecentlyActive: isRecentlyActive ?? this.isRecentlyActive,
    );
  }
}

class SocialPost {
  final String id;
  final String authorId;
  final String content;
  final String externalUrl;
  final String? linkedResourceId;
  final String? linkedVideoId;
  final DateTime createdAt;
  final String authorName;
  final String authorAvatar;
  final String authorUniversity;
  final String? linkedResourceTitle;
  final ResourceType? linkedResourceType;
  final String linkedResourceSubject;
  final String? linkedVideoTitle;
  final String linkedVideoThumbnailUrl;
  final String linkedVideoCategory;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final List<SocialComment> comments;
  final List<Resource> attachments;

  SocialPost({
    required this.id,
    required this.authorId,
    required this.content,
    this.externalUrl = '',
    this.linkedResourceId,
    this.linkedVideoId,
    required this.createdAt,
    this.authorName = '',
    this.authorAvatar = '',
    this.authorUniversity = '',
    this.linkedResourceTitle,
    this.linkedResourceType,
    this.linkedResourceSubject = '',
    this.linkedVideoTitle,
    this.linkedVideoThumbnailUrl = '',
    this.linkedVideoCategory = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
    this.comments = const [],
    this.attachments = const [],
  });

  factory SocialPost.fromJson(
    Map<String, dynamic> json, {
    int likesCount = 0,
    int commentsCount = 0,
    bool isLikedByMe = false,
    List<SocialComment> comments = const [],
    List<Resource> attachments = const [],
  }) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    final resourceData = json['resources'] as Map<String, dynamic>?;
    final videoData = json['videos'] as Map<String, dynamic>?;
    final resourceTypeName = resourceData?['type'] as String?;

    return SocialPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String? ?? '',
      externalUrl: json['external_url'] as String? ?? '',
      linkedResourceId: json['linked_resource_id'] as String?,
      linkedVideoId: json['linked_video_id'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      authorName: profileData?['full_name'] as String? ?? '',
      authorAvatar: profileData?['avatar_url'] as String? ?? '',
      authorUniversity: profileData?['university'] as String? ?? '',
      linkedResourceTitle: resourceData?['title'] as String?,
      linkedResourceType: resourceTypeName == null
          ? null
          : ResourceType.values.firstWhere(
              (type) => type.name == resourceTypeName,
              orElse: () => ResourceType.report,
            ),
      linkedResourceSubject: resourceData?['subject'] as String? ?? '',
      linkedVideoTitle: videoData?['title'] as String?,
      linkedVideoThumbnailUrl: videoData?['thumbnail_url'] as String? ?? '',
      linkedVideoCategory: videoData?['category'] as String? ?? '',
      likesCount: likesCount,
      commentsCount: commentsCount,
      isLikedByMe: isLikedByMe,
      comments: comments,
      attachments: attachments,
    );
  }

  SocialPost copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    List<SocialComment>? comments,
    List<Resource>? attachments,
  }) {
    return SocialPost(
      id: id,
      authorId: authorId,
      content: content,
      externalUrl: externalUrl,
      linkedResourceId: linkedResourceId,
      linkedVideoId: linkedVideoId,
      createdAt: createdAt,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorUniversity: authorUniversity,
      linkedResourceTitle: linkedResourceTitle,
      linkedResourceType: linkedResourceType,
      linkedResourceSubject: linkedResourceSubject,
      linkedVideoTitle: linkedVideoTitle,
      linkedVideoThumbnailUrl: linkedVideoThumbnailUrl,
      linkedVideoCategory: linkedVideoCategory,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
    );
  }
}
