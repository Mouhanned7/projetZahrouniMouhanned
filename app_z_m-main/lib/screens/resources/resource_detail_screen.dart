import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/resource.dart';
import '../../models/resource_rating.dart';
import '../../services/auth_service.dart';
import '../../services/resource_service.dart';
import '../../services/resource_storage_service.dart';
import '../../services/rating_service.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/web_iframe_viewer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final _authService = AuthService();
  final _resourceService = ResourceService();
  final _resourceStorageService = ResourceStorageService();
  final _ratingService = RatingService();
  Resource? _resource;
  List<ResourceRating> _ratings = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isAdmin = false;
  double _userRating = 0;
  bool _showPreview = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResource();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadResource() async {
    setState(() => _isLoading = true);
    final resource = await _resourceService.getResourceById(widget.resourceId);
    final ratings = await _ratingService.getRatings(widget.resourceId);
    final profile = await _authService.getCurrentProfile();

    // Check if user already rated
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final userRating =
          await _ratingService.getUserRating(widget.resourceId, userId);
      if (userRating != null) {
        _userRating = userRating.rating.toDouble();
        _commentController.text = userRating.comment;
      }
    }

    if (mounted) {
      setState(() {
        _resource = resource;
        _ratings = ratings;
        _isAdmin = profile?.isAdmin ?? false;
        _isLoading = false;
        _showPreview = false;
      });
    }
  }

  Future<void> _confirmAndDeleteResource(Resource resource) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Supprimer la ressource ?'),
            content: Text(
              'Cette action est irréversible.\n\n${resource.title}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() => _isDeleting = true);
    final success = await _resourceService.deleteResource(resource.id);

    if (!mounted) return;

    setState(() => _isDeleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '🗑️ Ressource supprimée avec succès.'
              : '❌ Suppression impossible. Vérifiez les permissions admin.',
        ),
        backgroundColor:
            success ? AppTheme.secondaryColor : AppTheme.accentColor,
      ),
    );

    if (success) {
      context.go('/resources');
    }
  }

  Future<void> _submitRating() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _userRating == 0) return;

    final success = await _ratingService.submitRating(
      resourceId: widget.resourceId,
      userId: userId,
      rating: _userRating.round(),
      comment: _commentController.text,
    );

    if (success && mounted) {
      _loadResource();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Évaluation soumise !'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  String _buildDownloadUrl(Resource resource) {
    final ext = _extractFileExtension(resource.fileUrl);
    final safeTitle =
        resource.title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final preferredName = ext.isEmpty ? safeTitle : '$safeTitle.$ext';

    return _resourceStorageService.buildDownloadUrl(
      resource.fileUrl,
      preferredFileName: preferredName,
    );
  }

  String _extractFileExtension(String fileUrl) {
    final path =
        Uri.tryParse(fileUrl)?.path.toLowerCase() ?? fileUrl.toLowerCase();
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1);
  }

  bool _supportsInlinePreview(String ext, Resource resource) {
    if (const {'pdf', 'ppt', 'pptx', 'doc', 'docx'}.contains(ext)) {
      return true;
    }

    // Some Cloudinary URLs may lose visible extension in path for raw files.
    if (ext.isEmpty &&
        (resource.type == ResourceType.presentation ||
            resource.type == ResourceType.report)) {
      return true;
    }

    return false;
  }

  String _buildPreviewUrl(String rawUrl, Resource resource) {
    final ext = _extractFileExtension(rawUrl);
    final encoded = Uri.encodeComponent(rawUrl);

    if (ext == 'pdf') {
      // PDF from Cloudinary can fail in iframe due delivery headers, gview is safer.
      if (rawUrl.contains('res.cloudinary.com')) {
        return 'https://docs.google.com/gview?embedded=1&url=$encoded';
      }
      return rawUrl;
    }

    // Office Online viewer is generally more reliable for doc/ppt formats.
    if (const {'ppt', 'pptx', 'doc', 'docx'}.contains(ext)) {
      return 'https://view.officeapps.live.com/op/embed.aspx?src=$encoded';
    }

    // Fallback when extension is hidden but resource type expects document preview.
    if (ext.isEmpty &&
        (resource.type == ResourceType.presentation ||
            resource.type == ResourceType.report)) {
      return 'https://docs.google.com/gview?embedded=1&url=$encoded';
    }

    return rawUrl;
  }

  Future<void> _togglePreview(Resource resource) async {
    final ext = _extractFileExtension(resource.fileUrl);
    if (!_supportsInlinePreview(ext, resource)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aperçu intégré non supporté pour .$ext. Utilisez "Ouvrir dans un nouvel onglet".',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // On non-web platforms, use browser preview instead of iframe.
    if (!kIsWeb) {
      final uri = Uri.parse(_buildPreviewUrl(resource.fileUrl, resource));
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _showPreview = !_showPreview);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_resource == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('Ressource introuvable',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => context.go('/resources'),
                child: const Text('Retour')),
          ],
        ),
      );
    }

    final resource = _resource!;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button & actions
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/resources'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const Spacer(),
                if (_isAdmin) ...[
                  OutlinedButton.icon(
                    onPressed: _isDeleting
                        ? null
                        : () => _confirmAndDeleteResource(resource),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accentColor,
                            ),
                          )
                        : const Icon(Icons.delete_rounded, size: 18),
                    label: Text(_isDeleting ? 'Suppression...' : 'Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: const BorderSide(color: AppTheme.accentColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_buildDownloadUrl(resource));
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Télécharger'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resource header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(resource.type.icon,
                      style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          resource.type.label,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.2),
                            child: Text(
                              (resource.authorName?.isNotEmpty == true
                                      ? resource.authorName!
                                      : '?')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            resource.authorName ?? 'Anonyme',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(resource.createdAt, locale: 'fr'),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _buildStatBadge(Icons.star_rounded,
                    resource.avgRating.toStringAsFixed(1), Colors.amber),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.rate_review_rounded,
                    '${resource.ratingsCount} avis', AppTheme.primaryColor),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.download_rounded,
                    '${resource.downloadsCount}', AppTheme.secondaryColor),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.data_saver_on_rounded,
                    resource.fileSizeFormatted, AppTheme.accentColor),
              ],
            ),
            const SizedBox(height: 28),

            // Description
            if (resource.description.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(),
                child: Text(
                  resource.description,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), height: 1.6),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // File actions (manual only)
            const Text(
              '📎 Fichier',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.glassDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aperçu manuel disponible pour les formats compatibles (PDF, DOC/DOCX, PPT/PPTX).',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spécialité: ${resource.subject.isEmpty ? "-" : resource.subject}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 13),
                  ),
                  Text(
                    'Université: ${resource.university.isEmpty ? "-" : resource.university}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _togglePreview(resource),
                  icon: Icon(
                    _showPreview
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 16,
                  ),
                  label:
                      Text(_showPreview ? 'Masquer aperçu' : 'Afficher aperçu'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(resource.fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, webOnlyWindowName: '_blank');
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Ouvrir dans un nouvel onglet'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_buildDownloadUrl(resource));
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, webOnlyWindowName: '_blank');
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Télécharger'),
                ),
              ],
            ),
            if (_showPreview) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                clipBehavior: Clip.antiAlias,
                child: WebIframeViewer(
                  url: _buildPreviewUrl(resource.fileUrl, resource),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aperçu manuel activé. Si le rendu est vide, utilisez "Ouvrir dans un nouvel onglet".',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Rating section
            const Text(
              '⭐ Évaluer cette ressource',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(),
              child: Column(
                children: [
                  RatingWidget(
                    initialRating: _userRating,
                    size: 32,
                    onRatingUpdate: (r) => setState(() => _userRating = r),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire (optionnel)...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _userRating > 0 ? _submitRating : null,
                      child: const Text('Soumettre'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Reviews list
            if (_ratings.isNotEmpty) ...[
              Text(
                'Avis (${_ratings.length})',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              ..._ratings.map((rating) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              child: Text(
                                (rating.userName?.isNotEmpty == true
                                        ? rating.userName!
                                        : '?')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rating.userName ?? 'Anonyme',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                            RatingWidget(
                              initialRating: rating.rating.toDouble(),
                              readOnly: true,
                              size: 14,
                            ),
                          ],
                        ),
                        if (rating.comment.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              rating.comment,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
