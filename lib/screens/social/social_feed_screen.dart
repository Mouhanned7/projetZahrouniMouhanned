import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../models/resource.dart';
import '../../models/social_post.dart';
import '../../models/video.dart';
import '../../services/auth_service.dart';
import '../../services/resource_service.dart';
import '../../services/resource_storage_service.dart';
import '../../services/social_service.dart';
import '../../services/video_service.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final _socialService = SocialService();
  final _authService = AuthService();
  final _resourceService = ResourceService();
  final _resourceStorageService = ResourceStorageService();
  final _videoService = VideoService();

  final Map<String, TextEditingController> _commentControllers = {};

  List<SocialPost> _posts = [];
  List<Resource> _ownResources = [];
  List<Video> _ownVideos = [];
  List<SocialContact> _contacts = [];

  bool _isLoading = true;
  bool _isPublishing = false;

  String? get _currentUserId => _authService.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final posts = await _socialService.getFeed(currentUserId: userId);
      final ownResources = await _resourceService.getResourcesByAuthor(userId);
      final ownVideos = await _videoService.getVideosByAuthor(userId);
      final contacts = await _socialService.getContacts(currentUserId: userId);

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _ownResources = ownResources;
        _ownVideos = ownVideos;
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger la section sociale.'),
          backgroundColor: _SocialColors.danger,
        ),
      );
    }
  }

  TextEditingController _commentControllerFor(String postId) {
    return _commentControllers.putIfAbsent(postId, TextEditingController.new);
  }

  Future<List<PlatformFile>> _pickFilesForMode(_QuickShareMode mode) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensionsForMode(mode),
      withData: true,
    );

    if (result == null) return const [];

    return result.files.where((file) => file.bytes != null).toList();
  }

  Future<void> _startQuickShare(_QuickShareMode mode) async {
    if (mode == _QuickShareMode.link) {
      await _openCreatePostDialog(mode: mode, autofocusLink: true);
      return;
    }

    final initialAttachments = await _pickFilesForMode(mode);
    if (!mounted) return;

    await _openCreatePostDialog(
      mode: mode,
      initialAttachments: initialAttachments,
    );
  }

  Future<void> _openCreatePostDialog({
    _QuickShareMode mode = _QuickShareMode.any,
    List<PlatformFile> initialAttachments = const [],
    bool autofocusLink = false,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final contentController = TextEditingController();
    final linkController = TextEditingController();
    String selectedResourceId = '';
    String selectedVideoId = '';
    final attachments = List<PlatformFile>.from(initialAttachments);

    Future<void> pickFiles(StateSetter setSheetState) async {
      final result = await _pickFilesForMode(mode);
      if (result.isEmpty) return;

      setSheetState(() {
        attachments.addAll(result);
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, 18 + bottomInset),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nouvelle publication',
                        style: TextStyle(
                          color: _SocialColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _composerDescription(mode),
                        style: const TextStyle(
                          color: _SocialColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: contentController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: _inputDecoration(
                          hint: 'Ecris ton post, ton projet ou ton besoin...',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: linkController,
                        autofocus: autofocusLink,
                        keyboardType: TextInputType.url,
                        decoration: _inputDecoration(
                          hint: mode == _QuickShareMode.link
                              ? 'Colle rapidement ton lien'
                              : 'Lien externe optionnel',
                          icon: Icons.link_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedResourceId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Aucune ressource liee'),
                          ),
                          ..._ownResources.map(
                            (resource) => DropdownMenuItem<String>(
                              value: resource.id,
                              child: Text(
                                resource.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            selectedResourceId = value ?? '';
                          });
                        },
                        decoration: _inputDecoration(
                          hint: 'Associer une de mes ressources',
                          icon: Icons.library_books_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedVideoId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Aucune video liee'),
                          ),
                          ..._ownVideos.map(
                            (video) => DropdownMenuItem<String>(
                              value: video.id,
                              child: Text(
                                video.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            selectedVideoId = value ?? '';
                          });
                        },
                        decoration: _inputDecoration(
                          hint: 'Associer une de mes videos',
                          icon: Icons.play_circle_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => pickFiles(setSheetState),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _SocialColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _SocialColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                color: _SocialColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pickerLabel(mode),
                                  style: const TextStyle(
                                    color: _SocialColors.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                color: _SocialColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (attachments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(attachments.length, (index) {
                            final file = attachments[index];
                            return _AttachmentDraftChip(
                              file: file,
                              onRemove: () {
                                setSheetState(() => attachments.removeAt(index));
                              },
                            );
                          }),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isPublishing
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _SocialColors.primary,
                                side: const BorderSide(
                                  color: _SocialColors.border,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isPublishing
                                  ? null
                                  : () async {
                                      final text = contentController.text.trim();
                                      final link = linkController.text.trim();

                                      if (text.isEmpty &&
                                          link.isEmpty &&
                                          selectedResourceId.isEmpty &&
                                          selectedVideoId.isEmpty &&
                                          attachments.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ajoute au moins un texte, un lien, une ressource ou un fichier.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.pop(sheetContext);

                                      await _publishPost(
                                        content: text.isEmpty
                                            ? 'Nouvelle publication'
                                            : text,
                                        externalUrl: link,
                                          linkedResourceId: selectedResourceId,
                                          linkedVideoId: selectedVideoId,
                                          attachments: attachments,
                                        );
                                      },
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Publier'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _SocialColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    contentController.dispose();
    linkController.dispose();
  }

  Future<void> _publishPost({
    required String content,
    required List<PlatformFile> attachments,
    String? externalUrl,
    String? linkedResourceId,
    String? linkedVideoId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    setState(() => _isPublishing = true);

    try {
      final profile = await _authService.getCurrentProfile();
      final post = await _socialService.createPost(
        authorId: userId,
        content: content,
        externalUrl: _normalizeUrl(externalUrl),
        linkedResourceId: linkedResourceId != null && linkedResourceId.isNotEmpty
            ? linkedResourceId
            : null,
        linkedVideoId: linkedVideoId != null && linkedVideoId.isNotEmpty
            ? linkedVideoId
            : null,
      );

      if (post == null) {
        throw Exception('create_post_failed');
      }

      final createdResourceIds = <String>[];

      for (final file in attachments) {
        final bytes = file.bytes;
        if (bytes == null) continue;

        final resourceType = _resourceTypeForAttachment(file);
        final fileUrl = await _resourceStorageService.uploadResourceFile(
          fileBytes: bytes,
          fileName: file.name,
          type: resourceType,
          userId: userId,
        );

        final createdResource = await _resourceService.createResource(
          Resource(
            id: '',
            title: file.name,
            description: 'Piece jointe de publication sociale',
            type: resourceType,
            subject: '',
            university: profile?.university ?? '',
            fileUrl: fileUrl,
            thumbnailUrl: _thumbnailForAttachment(file, fileUrl),
            fileSize: file.size,
            authorId: userId,
            status: profile?.isAdmin == true
                ? ResourceStatus.approved
                : ResourceStatus.pending,
          ),
        );

        if (createdResource != null) {
          createdResourceIds.add(createdResource.id);
        }
      }

      if (createdResourceIds.isNotEmpty) {
        await _socialService.attachResourcesToPost(
          postId: post.id,
          resourceIds: createdResourceIds,
        );
      }

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication ajoutee avec succes.'),
          backgroundColor: _SocialColors.primary,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de publier pour le moment.'),
          backgroundColor: _SocialColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  ResourceType _resourceTypeForAttachment(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      return ResourceType.presentation;
    }
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return ResourceType.presentation;
    }
    return ResourceType.report;
  }

  String _thumbnailForAttachment(PlatformFile file, String fileUrl) {
    final ext = (file.extension ?? '').toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      return fileUrl;
    }
    return '';
  }

  Future<void> _toggleLike(SocialPost post) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final updated = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likesCount: post.isLikedByMe ? post.likesCount - 1 : post.likesCount + 1,
    );

    setState(() {
      _posts = _posts.map((item) => item.id == post.id ? updated : item).toList();
    });

    final success = await _socialService.toggleLike(
      postId: post.id,
      userId: userId,
    );

    if (success || !mounted) return;

    setState(() {
      _posts = _posts.map((item) => item.id == post.id ? post : item).toList();
    });
  }

  Future<void> _addComment(SocialPost post) async {
    final userId = _currentUserId;
    final controller = _commentControllerFor(post.id);
    final text = controller.text.trim();

    if (userId == null || text.isEmpty) return;

    final comment = await _socialService.addComment(
      postId: post.id,
      userId: userId,
      content: text,
    );

    if (comment == null || !mounted) return;

    controller.clear();

    setState(() {
      _posts = _posts.map((item) {
        if (item.id != post.id) return item;
        final comments = [...item.comments, comment];
        return item.copyWith(
          comments: comments,
          commentsCount: comments.length,
        );
      }).toList();
    });
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final text = _normalizeUrl(rawUrl);
    if (text == null) return;

    final uri = Uri.tryParse(text);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _normalizeUrl(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    return 'https://$text';
  }

  Future<void> _openConversation(SocialContact contact) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final messageController = TextEditingController();
    List<SocialMessage> messages = [];
    bool loading = true;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (dialogContext) {
        Future<void> loadMessages(StateSetter setDialogState) async {
          final data = await _socialService.getConversation(
            currentUserId: userId,
            otherUserId: contact.id,
          );

          setDialogState(() {
            messages = data;
            loading = false;
          });
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (loading) {
              loadMessages(setDialogState);
            }

            Future<void> sendCurrentMessage() async {
              final text = messageController.text.trim();
              if (text.isEmpty) return;

              final sent = await _socialService.sendMessage(
                senderId: userId,
                recipientId: contact.id,
                content: text,
              );

              if (sent == null) return;

              messageController.clear();

              setDialogState(() {
                messages = [...messages, sent];
              });

              setState(() {
                _contacts = _contacts.map((item) {
                  if (item.id != contact.id) return item;
                  return item.copyWith(
                    lastMessagePreview: sent.content,
                    lastMessageAt: sent.createdAt,
                    isRecentlyActive: true,
                  );
                }).toList();
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _SocialColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: _SocialColors.primary,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        child: Row(
                          children: [
                            _AvatarBadge(
                              label: contact.initial,
                              avatarUrl: contact.avatarUrl,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    contact.university.isEmpty
                                        ? 'Etudiant'
                                        : contact.university,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFFBFCFE),
                          padding: const EdgeInsets.all(16),
                          child: loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: _SocialColors.primary,
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: messages.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isMe = message.senderId == userId;
                                    return _MessageBubble(
                                      text: message.content,
                                      timeLabel: timeago.format(
                                        message.createdAt,
                                        locale: 'en_short',
                                      ),
                                      isMe: isMe,
                                    );
                                  },
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: _inputDecoration(
                                  hint: 'Ecrire un message...',
                                  dense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: sendCurrentMessage,
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _SocialColors.primary,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
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
          },
        );
      },
    );

    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;

    final horizontalPadding = width >= 1280
        ? 40.0
        : width >= 900
            ? 28.0
            : 16.0;

    final feed = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(compact),
        const SizedBox(height: 18),
        _buildComposerCard(compact),
        const SizedBox(height: 18),
        if (_isLoading)
          const _LoadingState()
        else if (_posts.isEmpty)
          _buildEmptyState()
        else
          ..._posts.map(_buildPostCard),
      ],
    );

    return Scaffold(
      backgroundColor: _SocialColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _SocialColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              120,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            feed,
                            const SizedBox(height: 18),
                            _ContactsPanel(
                              contacts: _contacts,
                              compact: true,
                              onTapContact: _openConversation,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: feed,
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 330,
                              child: _ContactsPanel(
                                contacts: _contacts,
                                compact: false,
                                onTapContact: _openConversation,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Social',
                style: TextStyle(
                  color: _SocialColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Publie tes avancees, partage des liens et retrouve les etudiants actifs du workspace.',
                style: TextStyle(
                  color: _SocialColors.muted,
                  fontSize: compact ? 13 : 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (!compact)
          ElevatedButton.icon(
            onPressed: _openCreatePostDialog,
            icon: const Icon(Icons.edit_square, size: 18),
            label: const Text('Publier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _SocialColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComposerCard(bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _SocialColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarBadge(label: _currentInitial()),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _openCreatePostDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _SocialColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _SocialColors.border),
                    ),
                    child: const Text(
                      'Partager un projet, un lien ou une ressource...',
                      style: TextStyle(
                        color: _SocialColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TinyFeature(
                icon: Icons.photo_library_rounded,
                label: 'Photo',
                onTap: () => _startQuickShare(_QuickShareMode.photo),
              ),
              _TinyFeature(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                onTap: () => _startQuickShare(_QuickShareMode.pdf),
              ),
              _TinyFeature(
                icon: Icons.play_circle_rounded,
                label: 'Video',
                onTap: () => _startQuickShare(_QuickShareMode.video),
              ),
              _TinyFeature(
                icon: Icons.link_rounded,
                label: 'Lien',
                onTap: () => _startQuickShare(_QuickShareMode.link),
              ),
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCreatePostDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Creer une publication'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _SocialColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostCard(SocialPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _SocialColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarBadge(
                label: _initialFrom(post.authorName),
                avatarUrl: post.authorAvatar,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName.isEmpty ? 'Etudiant' : post.authorName,
                      style: const TextStyle(
                        color: _SocialColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (post.authorUniversity.isNotEmpty)
                          post.authorUniversity,
                        timeago.format(post.createdAt, locale: 'en_short'),
                      ].join('  •  '),
                      style: const TextStyle(
                        color: _SocialColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.content,
            style: const TextStyle(
              color: _SocialColors.text,
              height: 1.55,
            ),
          ),
          if (post.externalUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openExternalUrl(post.externalUrl),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _SocialColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _SocialColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: _SocialColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.externalUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _SocialColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (post.linkedResourceId != null && post.linkedResourceTitle != null) ...[
            const SizedBox(height: 12),
            _LinkedResourceCard(
              title: post.linkedResourceTitle!,
              subtitle: [
                post.linkedResourceType?.label ?? 'Ressource',
                if (post.linkedResourceSubject.isNotEmpty)
                  post.linkedResourceSubject,
              ].join('  •  '),
              onTap: () => context.go('/resources/${post.linkedResourceId}'),
            ),
          ],
          if (post.linkedVideoId != null && post.linkedVideoTitle != null) ...[
            const SizedBox(height: 12),
            _LinkedVideoCard(
              title: post.linkedVideoTitle!,
              thumbnailUrl: post.linkedVideoThumbnailUrl,
              subtitle: post.linkedVideoCategory.isEmpty
                  ? 'Video liee'
                  : post.linkedVideoCategory,
              onTap: () => context.go('/videos/${post.linkedVideoId}'),
            ),
          ],
          if (post.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: post.attachments
                  .map(
                    (resource) => _AttachedResourceCard(
                      resource: resource,
                      onTap: () => context.go('/resources/${resource.id}'),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricButton(
                icon: post.isLikedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.likesCount}',
                active: post.isLikedByMe,
                onTap: () => _toggleLike(post),
              ),
              const SizedBox(width: 10),
              _MetricButton(
                icon: Icons.mode_comment_outlined,
                label: '${post.commentsCount}',
                active: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _SocialColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _SocialColors.border),
            ),
            child: Column(
              children: [
                if (post.comments.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Aucun commentaire pour le moment.',
                      style: TextStyle(
                        color: _SocialColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  )
                else
                  ...post.comments.map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CommentTile(comment: comment),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentControllerFor(post.id),
                        minLines: 1,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          hint: 'Ajouter un commentaire',
                          dense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _addComment(post),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _SocialColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _SocialColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _SocialColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: _SocialColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Le fil social est encore vide',
            style: TextStyle(
              color: _SocialColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sois le premier a publier un projet, un besoin ou une ressource utile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _SocialColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    bool dense = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: _SocialColors.surface,
      isDense: dense,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 13 : 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _SocialColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: _SocialColors.primary,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  String _currentInitial() {
    final fullName =
        _authService.currentUser?.userMetadata?['full_name'] as String? ?? '';
    return _initialFrom(fullName);
  }

  String _initialFrom(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  List<String> _allowedExtensionsForMode(_QuickShareMode mode) {
    switch (mode) {
      case _QuickShareMode.photo:
        return const ['jpg', 'jpeg', 'png', 'webp'];
      case _QuickShareMode.pdf:
        return const ['pdf'];
      case _QuickShareMode.video:
        return const ['mp4', 'mov', 'avi', 'mkv'];
      case _QuickShareMode.link:
      case _QuickShareMode.any:
        return const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
          'mp4',
          'mov',
          'avi',
          'mkv',
        ];
    }
  }

  String _composerDescription(_QuickShareMode mode) {
    switch (mode) {
      case _QuickShareMode.photo:
        return 'Partage rapidement une photo avec texte, lien ou contenu deja publie.';
      case _QuickShareMode.pdf:
        return 'Partage rapidement un PDF avec texte, lien ou contenu deja publie.';
      case _QuickShareMode.video:
        return 'Partage rapidement une video, ou relie une video deja publiee.';
      case _QuickShareMode.link:
        return 'Partage rapidement un lien externe avec un petit contexte.';
      case _QuickShareMode.any:
        return 'Publie du texte, un lien externe, une ressource existante ou de nouveaux fichiers.';
    }
  }

  String _pickerLabel(_QuickShareMode mode) {
    switch (mode) {
      case _QuickShareMode.photo:
        return 'Ajouter une ou plusieurs photos';
      case _QuickShareMode.pdf:
        return 'Ajouter un ou plusieurs PDF';
      case _QuickShareMode.video:
        return 'Ajouter une ou plusieurs videos';
      case _QuickShareMode.link:
        return 'Ajouter media optionnel';
      case _QuickShareMode.any:
        return 'Ajouter photo, PDF ou video';
    }
  }
}

enum _QuickShareMode { any, photo, pdf, video, link }

class _ContactsPanel extends StatelessWidget {
  final List<SocialContact> contacts;
  final bool compact;
  final ValueChanged<SocialContact> onTapContact;

  const _ContactsPanel({
    required this.contacts,
    required this.compact,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _SocialColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personnes a contacter',
            style: TextStyle(
              color: _SocialColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${contacts.length} profils dynamiques depuis la base',
            style: const TextStyle(
              color: _SocialColors.muted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          if (contacts.isEmpty)
            const Text(
              'Aucun contact disponible.',
              style: TextStyle(color: _SocialColors.muted),
            )
          else if (compact)
            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return _CompactContactCard(
                    contact: contact,
                    onTap: () => onTapContact(contact),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: contacts.length,
              ),
            )
          else
            ...contacts.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContactCard(
                  contact: contact,
                  onTap: () => onTapContact(contact),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final SocialContact contact;
  final VoidCallback onTap;

  const _ContactCard({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _SocialColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _SocialColors.border),
          ),
          child: Row(
            children: [
              _AvatarBadge(
                label: contact.initial,
                avatarUrl: contact.avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SocialColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contact.university.isEmpty
                          ? contact.role
                          : contact.university,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SocialColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.lastMessagePreview.isEmpty
                          ? 'Aucun message pour le moment'
                          : contact.lastMessagePreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: contact.lastMessagePreview.isEmpty
                            ? _SocialColors.muted
                            : _SocialColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chat_bubble_rounded,
                color: contact.isRecentlyActive
                    ? _SocialColors.primary
                    : _SocialColors.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactContactCard extends StatelessWidget {
  final SocialContact contact;
  final VoidCallback onTap;

  const _CompactContactCard({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            _AvatarBadge(label: contact.initial, avatarUrl: contact.avatarUrl),
            const SizedBox(height: 8),
            Text(
              contact.fullName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SocialColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              contact.isRecentlyActive ? 'Actif' : 'Profil',
              style: TextStyle(
                color: contact.isRecentlyActive
                    ? const Color(0xFF12C88A)
                    : _SocialColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String label;
  final String avatarUrl;

  const _AvatarBadge({
    required this.label,
    this.avatarUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: _SocialColors.primarySoft,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              label,
              style: const TextStyle(
                color: _SocialColors.primary,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _CommentTile extends StatelessWidget {
  final SocialComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarBadge(
          label: comment.authorName.isEmpty ? '?' : comment.authorName[0],
          avatarUrl: comment.authorAvatar,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _SocialColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName.isEmpty
                            ? 'Etudiant'
                            : comment.authorName,
                        style: const TextStyle(
                          color: _SocialColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: const TextStyle(
                        color: _SocialColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: _SocialColors.text,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkedResourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkedResourceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _SocialColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _SocialColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.library_books_rounded,
                color: _SocialColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SocialColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SocialColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedVideoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final VoidCallback onTap;

  const _LinkedVideoCard({
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _SocialColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      width: 64,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SocialColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SocialColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.play_circle_fill_rounded,
              color: _SocialColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 52,
      color: _SocialColors.primarySoft,
      child: const Icon(
        Icons.play_circle_fill_rounded,
        color: _SocialColors.primary,
      ),
    );
  }
}

class _AttachedResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const _AttachedResourceCard({
    required this.resource,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageLike = resource.thumbnailUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _SocialColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageLike)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Image.network(
                  resource.thumbnailUrl,
                  height: 108,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _attachmentHeader(resource),
                ),
              )
            else
              _attachmentHeader(resource),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SocialColors.text,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${resource.type.label}  •  ${resource.fileSizeFormatted}',
                    style: const TextStyle(
                      color: _SocialColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentHeader(Resource resource) {
    return Container(
      height: 108,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _SocialColors.primarySoft,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Center(
        child: Text(
          resource.type.icon,
          style: const TextStyle(
            color: _SocialColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MetricButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MetricButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _SocialColors.primarySoft : _SocialColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? _SocialColors.primary.withOpacity(0.18)
                : _SocialColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? _SocialColors.primary : _SocialColors.muted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: active ? _SocialColors.primary : _SocialColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String timeLabel;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.timeLabel,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isMe ? _SocialColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: _SocialColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : _SocialColors.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(
                color: isMe ? Colors.white70 : _SocialColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentDraftChip extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const _AttachmentDraftChip({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _SocialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SocialColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isImage(file) && file.bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                file.bytes!,
                height: 82,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 82,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _SocialColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForFile(file),
                color: _SocialColors.primary,
                size: 28,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _SocialColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _sizeLabel(file.size),
            style: const TextStyle(
              color: _SocialColors.muted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onRemove,
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: _SocialColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImage(PlatformFile file) {
    return ['jpg', 'jpeg', 'png', 'webp']
        .contains((file.extension ?? '').toLowerCase());
  }

  IconData _iconForFile(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.play_circle_rounded;
    }
    if (ext == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    }
    return Icons.attach_file_rounded;
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _TinyFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TinyFeature({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _SocialColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _SocialColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: _SocialColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _SocialColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _SocialColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _SocialColors.primary),
          ),
        ),
      ),
    );
  }
}

class _SocialColors {
  static const primary = Color(0xFF15196C);
  static const primarySoft = Color(0xFFEDEEFF);
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFF9FAFB);
  static const text = Color(0xFF151725);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const danger = Color(0xFFBA1A1A);
}
