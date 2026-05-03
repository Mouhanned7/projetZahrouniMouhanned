enum ResourceType {
  presentation,
  report,
  code;

  String get label {
    switch (this) {
      case ResourceType.presentation:
        return 'Presentation';
      case ResourceType.report:
        return 'Rapport';
      case ResourceType.code:
        return 'Code';
    }
  }

  String get icon {
    switch (this) {
      case ResourceType.presentation:
        return 'P';
      case ResourceType.report:
        return 'R';
      case ResourceType.code:
        return 'C';
    }
  }
}

enum ResourceStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ResourceStatus.pending:
        return 'En attente';
      case ResourceStatus.approved:
        return 'Approuve';
      case ResourceStatus.rejected:
        return 'Rejete';
    }
  }
}

class Resource {
  final String id;
  final String title;
  final String description;
  final ResourceType type;
  final String subject;
  final String university;
  final String fileUrl;
  final String thumbnailUrl;
  final int fileSize;
  final String authorId;
  final ResourceStatus status;
  final double avgRating;
  final int ratingsCount;
  final int downloadsCount;
  final int viewsCount;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;

  Resource({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    this.subject = '',
    this.university = '',
    required this.fileUrl,
    this.thumbnailUrl = '',
    this.fileSize = 0,
    required this.authorId,
    this.status = ResourceStatus.pending,
    this.avgRating = 0,
    this.ratingsCount = 0,
    this.downloadsCount = 0,
    this.viewsCount = 0,
    DateTime? createdAt,
    this.authorName,
    this.authorAvatar,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Resource.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;

    return Resource(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: ResourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ResourceType.report,
      ),
      subject: json['subject'] as String? ?? '',
      university: json['university'] as String? ?? '',
      fileUrl: json['file_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      authorId: json['author_id'] as String,
      status: ResourceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ResourceStatus.pending,
      ),
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      downloadsCount: json['downloads_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      authorName: profileData?['full_name'] as String?,
      authorAvatar: profileData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'subject': subject,
      'university': university,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'file_size': fileSize,
      'author_id': authorId,
      'status': status.name,
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
