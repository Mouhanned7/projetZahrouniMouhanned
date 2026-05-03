import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../widgets/web_iframe_viewer.dart';
import 'package:timeago/timeago.dart' as timeago;

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({super.key, required this.videoId});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final _videoService = VideoService();
  Video? _video;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final video = await _videoService.getVideoById(widget.videoId);
    if (mounted) setState(() { _video = video; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_video == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('Vidéo introuvable', style: TextStyle(color: Colors.white54)),
            TextButton(onPressed: () => context.go('/videos'), child: const Text('Retour')),
          ],
        ),
      );
    }

    final video = _video!;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/videos'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
                ),
                const Spacer(),
                if (!video.isPublic)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: AppTheme.accentColor, size: 14),
                        SizedBox(width: 4),
                        Text('Vidéo privée', style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Embedded Video Player
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: WebIframeViewer(url: video.videoUrl),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(video.videoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, webOnlyWindowName: '_blank');
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Ouvrir dans un nouvel onglet', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 24),

            // Video info
            Text(
              video.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    (video.authorName?.isNotEmpty == true ? video.authorName! : '?')[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.authorName ?? 'Anonyme',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      timeago.format(video.createdAt, locale: 'fr'),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 16, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text('${video.viewsCount} vues', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            if (video.category.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(video.category, style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
            if (video.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(),
                child: Text(
                  video.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
