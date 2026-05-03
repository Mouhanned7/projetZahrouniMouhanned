import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../services/cloudinary_service.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _videoService = VideoService();
  final _cloudinaryService = CloudinaryService();

  bool _isPublic = true;
  PlatformFile? _selectedFile;
  PlatformFile? _selectedThumbnail;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedThumbnail = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une vidéo'), backgroundColor: AppTheme.accentColor),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final videoUrl = await _cloudinaryService.uploadFile(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        folder: 'videos',
      );

      if (videoUrl == null) throw Exception('Upload vidéo failed');

      String thumbnailUrl = '';
      if (_selectedThumbnail != null) {
        thumbnailUrl = await _cloudinaryService.uploadFile(
          fileBytes: _selectedThumbnail!.bytes!,
          fileName: _selectedThumbnail!.name,
          folder: 'thumbnails',
        ) ?? '';
      }

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final video = Video(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        category: _categoryController.text.trim(),
        isPublic: _isPublic,
        authorId: userId,
        duration: _durationController.text.trim(),
      );

      await _videoService.createVideo(video);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Vidéo uploadée !'), backgroundColor: AppTheme.secondaryColor),
        );
        context.go('/videos');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.accentColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/videos'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
                ),
                const SizedBox(width: 16),
                const Text(
                  '🎬 Ajouter une Vidéo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 28),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Titre *', prefixIcon: Icon(Icons.title_rounded)),
                      validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded), alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoryController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category_rounded)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Durée (ex: 12:30)', prefixIcon: Icon(Icons.timer_rounded)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Public / Private toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassDecoration(),
                      child: Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public_rounded : Icons.lock_rounded,
                            color: _isPublic ? AppTheme.secondaryColor : AppTheme.accentColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPublic ? 'Vidéo publique' : 'Vidéo privée',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _isPublic ? 'Visible par tous' : 'Visible uniquement par vous et le destinataire',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublic,
                            onChanged: (v) => setState(() => _isPublic = v),
                            activeColor: AppTheme.secondaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Video file picker
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedFile != null ? AppTheme.secondaryColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.check_circle_rounded : Icons.videocam_rounded,
                              size: 48,
                              color: _selectedFile != null ? AppTheme.secondaryColor : Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile != null ? _selectedFile!.name : 'Sélectionner un fichier vidéo',
                              style: TextStyle(
                                color: _selectedFile != null ? Colors.white : Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thumbnail picker
                    GestureDetector(
                      onTap: _pickThumbnail,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedThumbnail != null ? Icons.check_circle_rounded : Icons.image_rounded,
                              color: _selectedThumbnail != null ? AppTheme.secondaryColor : Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedThumbnail != null ? _selectedThumbnail!.name : 'Miniature (optionnel)',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _upload,
                        icon: _isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_rounded, size: 20),
                        label: Text(_isUploading ? 'Upload en cours...' : 'Publier la vidéo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
