import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../models/resource.dart';
import '../../models/resource_rating.dart';
import '../../services/auth_service.dart';
import '../../services/rating_service.dart';
import '../../services/resource_service.dart';
import '../../services/resource_storage_service.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/web_iframe_viewer.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({
    super.key,
    required this.resourceId,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final _authService = AuthService();
  final _resourceService = ResourceService();
  final _resourceStorageService = ResourceStorageService();
  final _ratingService = RatingService();
  final _commentController = TextEditingController();

  Resource? _resource;
  List<ResourceRating> _ratings = [];

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isAdmin = false;
  bool _showPreview = false;

  double _userRating = 0;

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

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      final userRating =
          await _ratingService.getUserRating(widget.resourceId, userId);

      if (userRating != null) {
        _userRating = userRating.rating.toDouble();
        _commentController.text = userRating.comment;
      }
    }

    if (!mounted) return;

    setState(() {
      _resource = resource;
      _ratings = ratings;
      _isAdmin = profile?.isAdmin ?? false;
      _isLoading = false;
      _showPreview = false;
    });
  }

  Future<void> _confirmAndDeleteResource(Resource resource) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Supprimer la ressource ?',
              style: TextStyle(
                color: _ProColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Cette action est irréversible.\n\n${resource.title}',
              style: const TextStyle(
                color: _ProColors.secondary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Supprimer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ProColors.danger,
                  foregroundColor: Colors.white,
                ),
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
        backgroundColor: success ? _ProColors.green : _ProColors.danger,
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

    if (!mounted) return;

    if (success) {
      await _loadResource();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Évaluation soumise !'),
          backgroundColor: _ProColors.green,
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
      if (rawUrl.contains('res.cloudinary.com')) {
        return 'https://docs.google.com/gview?embedded=1&url=$encoded';
      }

      return rawUrl;
    }

    if (const {'ppt', 'pptx', 'doc', 'docx'}.contains(ext)) {
      return 'https://view.officeapps.live.com/op/embed.aspx?src=$encoded';
    }

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
      return const Scaffold(
        backgroundColor: _ProColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: _ProColors.primary,
          ),
        ),
      );
    }

    if (_resource == null) {
      return Scaffold(
        backgroundColor: _ProColors.background,
        body: Center(
          child: _buildNotFound(),
        ),
      );
    }

    final resource = _resource!;

    return Scaffold(
      backgroundColor: _ProColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding =
              width >= 1280 ? 42.0 : width >= 900 ? 28.0 : 16.0;
          final isDesktop = width >= 1050;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              28,
              horizontalPadding,
              34,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(resource),
                    const SizedBox(height: 22),
                    _buildHero(resource, isDesktop),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                _buildDescriptionCard(resource),
                                const SizedBox(height: 18),
                                _buildFileCard(resource),
                                if (_showPreview) ...[
                                  const SizedBox(height: 18),
                                  _buildPreviewCard(resource),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildRatingCard(),
                                const SizedBox(height: 18),
                                _buildReviewsCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildDescriptionCard(resource),
                          const SizedBox(height: 18),
                          _buildFileCard(resource),
                          if (_showPreview) ...[
                            const SizedBox(height: 18),
                            _buildPreviewCard(resource),
                          ],
                          const SizedBox(height: 18),
                          _buildRatingCard(),
                          const SizedBox(height: 18),
                          _buildReviewsCard(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(Resource resource) {
    return Row(
      children: [
        _proIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => context.go('/resources'),
        ),
        const SizedBox(width: 12),
        const Text(
          'Détail de la ressource',
          style: TextStyle(
            color: _ProColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (_isAdmin) ...[
          OutlinedButton.icon(
            onPressed:
                _isDeleting ? null : () => _confirmAndDeleteResource(resource),
            icon: _isDeleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _ProColors.danger,
                    ),
                  )
                : const Icon(Icons.delete_rounded, size: 18),
            label: Text(_isDeleting ? 'Suppression...' : 'Supprimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ProColors.danger,
              side: const BorderSide(color: _ProColors.danger),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        ElevatedButton.icon(
          onPressed: () async {
            final uri = Uri.parse(_buildDownloadUrl(resource));

            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Télécharger'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _ProColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(Resource resource, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _ProColors.primary,
            _ProColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _ProColors.primary.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            right: 100,
            bottom: -120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResourceIcon(resource),
                    const SizedBox(width: 22),
                    Expanded(child: _buildHeroText(resource)),
                    const SizedBox(width: 24),
                    _buildHeroStats(resource),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResourceIcon(resource),
                    const SizedBox(height: 18),
                    _buildHeroText(resource),
                    const SizedBox(height: 22),
                    _buildHeroStats(resource),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildResourceIcon(Resource resource) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Center(
        child: Text(
          resource.type.icon,
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }

  Widget _buildHeroText(Resource resource) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 5,
          decoration: BoxDecoration(
            color: _ProColors.green,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Text(
            resource.type.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          resource.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _buildMetaItem(
              icon: Icons.person_rounded,
              value: resource.authorName ?? 'Anonyme',
            ),
            _buildMetaItem(
              icon: Icons.access_time_rounded,
              value: timeago.format(resource.createdAt, locale: 'fr'),
            ),
            _buildMetaItem(
              icon: Icons.school_rounded,
              value: resource.subject.isEmpty ? '-' : resource.subject,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.65), size: 17),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStats(Resource resource) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        _buildStatBadge(
          icon: Icons.star_rounded,
          label: 'Note',
          value: resource.avgRating.toStringAsFixed(1),
          color: Colors.amber,
        ),
        _buildStatBadge(
          icon: Icons.rate_review_rounded,
          label: 'Avis',
          value: '${resource.ratingsCount}',
          color: _ProColors.green,
        ),
        _buildStatBadge(
          icon: Icons.download_rounded,
          label: 'Downloads',
          value: '${resource.downloadsCount}',
          color: Colors.white,
        ),
        _buildStatBadge(
          icon: Icons.data_saver_on_rounded,
          label: 'Taille',
          value: resource.fileSizeFormatted,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Resource resource) {
    return _proCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.description_rounded,
            title: 'Description',
          ),
          const SizedBox(height: 14),
          Text(
            resource.description.isEmpty
                ? 'Aucune description disponible pour cette ressource.'
                : resource.description,
            style: const TextStyle(
              color: _ProColors.secondary,
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _smallInfoChip(
                icon: Icons.category_rounded,
                label: resource.type.label,
              ),
              _smallInfoChip(
                icon: Icons.school_rounded,
                label: resource.subject.isEmpty ? '-' : resource.subject,
              ),
              _smallInfoChip(
                icon: Icons.apartment_rounded,
                label: resource.university.isEmpty ? '-' : resource.university,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(Resource resource) {
    return _proCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.attach_file_rounded,
            title: 'Fichier',
          ),
          const SizedBox(height: 14),
          const Text(
            'Aperçu manuel disponible pour les formats compatibles : PDF, DOC, DOCX, PPT et PPTX.',
            style: TextStyle(
              color: _ProColors.secondary,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _togglePreview(resource),
                icon: Icon(
                  _showPreview
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                ),
                label: Text(
                  _showPreview ? 'Masquer aperçu' : 'Afficher aperçu',
                ),
                style: _primaryButtonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(resource.fileUrl);

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, webOnlyWindowName: '_blank');
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Ouvrir'),
                style: _outlineButtonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(_buildDownloadUrl(resource));

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, webOnlyWindowName: '_blank');
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Télécharger'),
                style: _outlineButtonStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(Resource resource) {
    return _proCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: _SectionTitle(
              icon: Icons.visibility_rounded,
              title: 'Aperçu du fichier',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 560,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _ProColors.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: WebIframeViewer(
              url: _buildPreviewUrl(resource.fileUrl, resource),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Si le rendu est vide, utilisez le bouton "Ouvrir".',
              style: TextStyle(
                color: _ProColors.secondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return _proCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.star_rounded,
            title: 'Évaluer cette ressource',
          ),
          const SizedBox(height: 18),
          Center(
            child: RatingWidget(
              initialRating: _userRating,
              size: 34,
              onRatingUpdate: (rating) {
                setState(() => _userRating = rating);
              },
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(
              color: _ProColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Ajouter un commentaire optionnel...',
              hintStyle: const TextStyle(color: _ProColors.secondary),
              filled: true,
              fillColor: _ProColors.background,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _ProColors.outline),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: _ProColors.primary,
                  width: 1.4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _userRating > 0 ? _submitRating : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Soumettre'),
              style: _primaryButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard() {
    return _proCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.reviews_rounded,
            title: 'Avis (${_ratings.length})',
          ),
          const SizedBox(height: 16),
          if (_ratings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _ProColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ProColors.outline),
              ),
              child: const Text(
                'Aucun avis pour le moment.',
                style: TextStyle(
                  color: _ProColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ..._ratings.map(_buildReviewItem),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ResourceRating rating) {
    final username = rating.userName ?? 'Anonyme';
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _ProColors.primary.withOpacity(0.08),
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: _ProColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    color: _ProColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              RatingWidget(
                initialRating: rating.rating.toDouble(),
                readOnly: true,
                size: 15,
              ),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rating.comment,
              style: const TextStyle(
                color: _ProColors.secondary,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      width: 460,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ProColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: _ProColors.danger,
          ),
          const SizedBox(height: 14),
          const Text(
            'Ressource introuvable',
            style: TextStyle(
              color: _ProColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cette ressource n’existe pas ou a été supprimée.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProColors.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go('/resources'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Widget _proCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _smallInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _ProColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ProColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _ProColors.primary, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: _ProColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _proIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ProColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: _ProColors.primary),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _ProColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ProColors.primary,
      side: const BorderSide(color: _ProColors.outline),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
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
            color: _ProColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _ProColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ProColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProColors {
  static const primary = Color(0xFF15196C);
  static const primaryLight = Color(0xFF2D3282);
  static const background = Color(0xFFF7F9FB);
  static const textDark = Color(0xFF191C1E);
  static const secondary = Color(0xFF505F76);
  static const outline = Color(0xFFE0E3E5);
  static const green = Color(0xFF4EDEA3);
  static const danger = Color(0xFFBA1A1A);
}