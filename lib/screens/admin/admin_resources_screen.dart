import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/resource.dart';
import '../../services/auth_service.dart';
import '../../services/resource_service.dart';
import '../../services/resource_storage_service.dart';
import '../../widgets/web_iframe_viewer.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminResourcesScreen extends StatefulWidget {
  const AdminResourcesScreen({super.key});

  @override
  State<AdminResourcesScreen> createState() => _AdminResourcesScreenState();
}

class _AdminResourcesScreenState extends State<AdminResourcesScreen> {
  final _authService = AuthService();
  final _resourceService = ResourceService();
  final _resourceStorageService = ResourceStorageService();
  List<Resource> _pending = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.getCurrentProfile();
      if (profile == null || !profile.isAdmin) {
        if (!mounted) return;
        setState(() {
          _pending = [];
          _isLoading = false;
          _errorMessage =
              'Accès refusé: seul un compte admin peut voir les ressources en attente.';
        });
        return;
      }

      final r = await _resourceService.getPendingResources();
      if (!mounted) return;

      setState(() {
        _pending = r;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pending = [];
        _isLoading = false;
        _errorMessage =
            'Impossible de charger les ressources en attente. Détail: ${e.toString()}';
      });
    }
  }

  Future<void> _act(String id, ResourceStatus s) async {
    final success = await _resourceService.updateResourceStatus(id, s);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (s == ResourceStatus.approved
                  ? '✅ Ressource approuvée'
                  : '❌ Ressource rejetée')
              : '❌ Action refusée. Vérifiez les permissions admin.',
        ),
        backgroundColor: success
            ? (s == ResourceStatus.approved
                ? AppTheme.secondaryColor
                : AppTheme.accentColor)
            : Colors.orange,
      ),
    );

    if (success) {
      _load();
    }
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

  Future<void> _openPreviewDialog(Resource resource) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool showPreview = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkSurface,
              title: Text(
                resource.title,
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 900,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type: ${resource.type.label} • Spécialité: ${resource.subject.isEmpty ? "-" : resource.subject}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aucun téléchargement automatique. Activez l\'aperçu manuellement.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ext = _extractFileExtension(resource.fileUrl);

                            if (!_supportsInlinePreview(ext, resource)) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Aperçu intégré non supporté pour .$ext. Utilisez "Ouvrir".',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            if (!kIsWeb) {
                              final uri = Uri.parse(
                                  _buildPreviewUrl(resource.fileUrl, resource));
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.inAppBrowserView);
                              }
                              return;
                            }

                            setDialogState(() => showPreview = !showPreview);
                          },
                          icon: Icon(
                            showPreview
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                          ),
                          label: Text(showPreview
                              ? 'Masquer aperçu'
                              : 'Afficher aperçu'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(resource.fileUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, webOnlyWindowName: '_blank');
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Ouvrir'),
                        ),
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
                    if (showPreview) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 420,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: WebIframeViewer(
                            url: _buildPreviewUrl(resource.fileUrl, resource)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 16),
              const Text('📋 Ressources en attente',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                  onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 20),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_pending.isEmpty)
              Expanded(
                  child: Center(
                      child: Text('Aucune ressource en attente 🎉',
                          style:
                              TextStyle(color: Colors.white.withValues(alpha: 0.5)))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _pending.length,
                  itemBuilder: (ctx, i) {
                    final r = _pending[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.amber.withValues(alpha: 0.2))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(r.type.icon,
                                    style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r.type.label} • ${r.authorName ?? "?"} • ${timeago.format(r.createdAt, locale: 'fr')}',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Spécialité: ${r.subject.isEmpty ? "-" : r.subject}  |  Université: ${r.university.isEmpty ? "-" : r.university}',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'Aperçu',
                                onPressed: () => _openPreviewDialog(r),
                                icon: const Icon(Icons.visibility_rounded),
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              IconButton(
                                tooltip: 'Approuver',
                                onPressed: () =>
                                    _act(r.id, ResourceStatus.approved),
                                icon: const Icon(Icons.check_circle_rounded),
                                color: AppTheme.secondaryColor,
                              ),
                              IconButton(
                                tooltip: 'Rejeter',
                                onPressed: () =>
                                    _act(r.id, ResourceStatus.rejected),
                                icon: const Icon(Icons.cancel_rounded),
                                color: AppTheme.accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
