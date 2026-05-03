import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/video.dart';

class VideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback? onTap;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.06),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play overlay
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    if (widget.video.thumbnailUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          widget.video.thumbnailUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? AppTheme.accentColor
                              : Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    if (widget.video.duration.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.video.duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!widget.video.isPublic)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Privée',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info area
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          child: Text(
                            (widget.video.authorName?.isNotEmpty == true ? widget.video.authorName! : '?')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.video.authorName ?? 'Anonyme',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.visibility_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.video.viewsCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    if (widget.video.category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.video.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondaryColor.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
