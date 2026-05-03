import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../widgets/web_iframe_viewer.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final _videoService = VideoService();

  Video? _video;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final video = await _videoService.getVideoById(widget.videoId);

      if (!mounted) return;

      setState(() {
        _video = video;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _openVideo() async {
    final video = _video;
    if (video == null) return;

    final uri = _playableVideoUri(video.videoUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: _isYouTubeUrl(video.videoUrl)
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }
  }

  Future<void> _copyVideoLink() async {
    final video = _video;
    if (video == null) return;

    await Clipboard.setData(
      ClipboardData(text: video.videoUrl),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié.'),
        backgroundColor: _AppColors.success,
      ),
    );
  }

  Future<void> _openFullscreenPlayer() async {
    final video = _video;
    if (video == null) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer le plein ecran',
      barrierColor: Colors.black.withOpacity(0.88),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: WebIframeViewer(url: _playerUrlFor(video.videoUrl)),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _fullscreenActionButton(
                        icon: Icons.open_in_new_rounded,
                        tooltip: 'Ouvrir a part',
                        onTap: _openVideo,
                      ),
                      const SizedBox(width: 10),
                      _fullscreenActionButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Fermer',
                        onTap: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  void _toggleSaved() {
    setState(() => _isSaved = !_isSaved);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved ? 'Vidéo ajoutée aux favoris.' : 'Vidéo retirée des favoris.',
        ),
        backgroundColor: _AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: _AppColors.primary,
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(
          child: _stateCard(
            icon: Icons.wifi_off_rounded,
            title: 'Erreur de chargement',
            message: 'Impossible de charger cette vidéo. Vérifiez votre connexion.',
            buttonLabel: 'Réessayer',
            onPressed: _loadVideo,
          ),
        ),
      );
    }

    if (_video == null) {
      return Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(
          child: _stateCard(
            icon: Icons.error_outline_rounded,
            title: 'Vidéo introuvable',
            message: 'Cette vidéo n’existe pas ou a été supprimée.',
            buttonLabel: 'Retour',
            onPressed: () => context.go('/videos'),
          ),
        ),
      );
    }

    final video = _video!;

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final compact = width < 900;

            final horizontalPadding = width >= 1280
                ? 40.0
                : width >= 900
                    ? 28.0
                    : 16.0;

            return RefreshIndicator(
              color: _AppColors.primary,
              onRefresh: _loadVideo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  120 + MediaQuery.of(context).padding.bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(video, compact),
                        const SizedBox(height: 18),
                        _buildPlayerCard(video, compact),
                        const SizedBox(height: 18),
                        compact
                            ? Column(
                                children: [
                                  _buildMainInfoCard(video),
                                  const SizedBox(height: 16),
                                  _buildSideInfoCard(video),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildMainInfoCard(video),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 4,
                                    child: _buildSideInfoCard(video),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(Video video, bool compact) {
    return Row(
      children: [
        _iconAction(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Retour',
          onTap: () => context.go('/videos'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            compact ? 'Détail vidéo' : 'Détail de la vidéo',
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (!video.isPublic) ...[
          const SizedBox(width: 8),
          _statusBadge(
            icon: Icons.lock_rounded,
            text: 'Privée',
            color: _AppColors.danger,
          ),
        ],
        const SizedBox(width: 8),
        _iconAction(
          icon: Icons.refresh_rounded,
          tooltip: 'Actualiser',
          onTap: _loadVideo,
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Video video, bool compact) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: compact ? 260 : 520,
            width: double.infinity,
            color: Colors.black,
            child: WebIframeViewer(url: _playerUrlFor(video.videoUrl)),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: _AppColors.border),
              ),
            ),
            child: compact
                ? Column(
                    children: [
                      _primaryActionButton(
                        icon: Icons.open_in_new_rounded,
                        text: 'Ouvrir la vidéo',
                        onPressed: _openVideo,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _outlineActionButton(
                              icon: Icons.fullscreen_rounded,
                              text: 'Plein ecran',
                              onPressed: _openFullscreenPlayer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _outlineActionButton(
                              icon: Icons.copy_rounded,
                              text: 'Copier',
                              onPressed: _copyVideoLink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _outlineActionButton(
                              icon: _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              text: _isSaved ? 'Sauvé' : 'Favori',
                              onPressed: _toggleSaved,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _primaryActionButton(
                        icon: Icons.open_in_new_rounded,
                        text: 'Ouvrir dans un nouvel onglet',
                        onPressed: _openVideo,
                      ),
                      const SizedBox(width: 10),
                      _outlineActionButton(
                        icon: Icons.fullscreen_rounded,
                        text: 'Plein ecran',
                        onPressed: _openFullscreenPlayer,
                      ),
                      const SizedBox(width: 10),
                      _outlineActionButton(
                        icon: Icons.copy_rounded,
                        text: 'Copier le lien',
                        onPressed: _copyVideoLink,
                      ),
                      const SizedBox(width: 10),
                      _outlineActionButton(
                        icon: _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        text: _isSaved ? 'Favori ajouté' : 'Ajouter aux favoris',
                        onPressed: _toggleSaved,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(Video video) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (video.category.isNotEmpty) ...[
            _categoryChip(video.category),
            const SizedBox(height: 14),
          ],
          Text(
            video.title,
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: _AppColors.primarySoft,
                child: Text(
                  _authorInitial(video),
                  style: const TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.authorName ?? 'Anonyme',
                      style: const TextStyle(
                        color: _AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(video.createdAt, locale: 'fr'),
                      style: const TextStyle(
                        color: _AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.notes_rounded,
            title: 'Description',
          ),
          const SizedBox(height: 12),
          Text(
            video.description.isEmpty
                ? 'Aucune description disponible pour cette vidéo.'
                : video.description,
            style: const TextStyle(
              color: _AppColors.muted,
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideInfoCard(Video video) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.info_outline_rounded,
            title: 'Informations',
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.visibility_rounded,
            label: 'Vues',
            value: '${video.viewsCount}',
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.category_rounded,
            label: 'Catégorie',
            value: video.category.isEmpty ? 'Non définie' : video.category,
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: video.isPublic ? Icons.public_rounded : Icons.lock_rounded,
            label: 'Visibilité',
            value: video.isPublic ? 'Publique' : 'Privée',
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.schedule_rounded,
            label: 'Publication',
            value: timeago.format(video.createdAt, locale: 'fr'),
          ),
          // const SizedBox(height: 18),
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.all(14),
          //   decoration: BoxDecoration(
          //     color: _AppColors.primarySoft,
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(
          //       color: _AppColors.primary.withOpacity(0.10),
          //     ),
          //   ),
          //   child: const Text(
          //     'Astuce : utilisez le bouton “Copier le lien” pour partager rapidement cette vidéo.',
          //     style: TextStyle(
          //       color: _AppColors.primary,
          //       fontSize: 12.5,
          //       height: 1.45,
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _AppColors.primary, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _AppColors.primary.withOpacity(0.10),
        ),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: _AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AppColors.border),
          ),
          child: Icon(
            icon,
            color: _AppColors.primary,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _primaryActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: _AppColors.primary,
        side: const BorderSide(color: _AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _fullscreenActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _authorInitial(Video video) {
    final name = video.authorName;

    if (name == null || name.trim().isEmpty) return '?';

    return name.trim()[0].toUpperCase();
  }

  bool _isYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  Uri _playableVideoUri(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Uri.parse(url);

    final videoId = _extractYouTubeId(url);
    if (videoId == null) return uri;

    return Uri.parse('https://www.youtube.com/watch?v=$videoId');
  }

  String _playerUrlFor(String url) {
    final videoId = _extractYouTubeId(url);
    if (videoId == null) return url;

    return 'https://www.youtube-nocookie.com/embed/$videoId?rel=0&modestbranding=1';
  }

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.first.isNotEmpty) {
        return segments.first;
      }
    }

    if (host.contains('youtube.com')) {
      final watchId = uri.queryParameters['v'];
      if (watchId != null && watchId.isNotEmpty) {
        return watchId;
      }

      final segments = uri.pathSegments;
      final embedIndex = segments.indexOf('embed');
      if (embedIndex != -1 && embedIndex + 1 < segments.length) {
        return segments[embedIndex + 1];
      }
    }

    return null;
  }

  static Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 430,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _AppColors.primary,
            size: 54,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AppColors.muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppColors {
  static const primary = Color(0xFF15196C);
  static const primarySoft = Color(0xFFEDEEFF);
  static const background = Color(0xFFF6F7FB);
  static const text = Color(0xFF151725);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const danger = Color(0xFFBA1A1A);
  static const success = Color(0xFF12B76A);
}
