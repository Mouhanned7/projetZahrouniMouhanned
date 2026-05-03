import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/video.dart';
import '../../services/cloudinary_service.dart';
import '../../services/video_service.dart';

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
  bool _isUploading = false;
  double _uploadProgress = 0;

  PlatformFile? _selectedFile;
  PlatformFile? _selectedThumbnail;

  final List<String> _categories = const [
    'Programmation',
    'Mathématiques',
    'Physique',
    'Design',
    'Marketing',
    'Langues',
    'Autre',
  ];

  static const Color _primary = Color(0xFF15196C);
  static const Color _primarySoft = Color(0xFFEDEEFF);
  static const Color _background = Color(0xFFF6F7FB);
  static const Color _text = Color(0xFF151725);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE4E7EC);
  static const Color _danger = Color(0xFFBA1A1A);
  static const Color _success = Color(0xFF12B76A);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _selectedFile = result.files.first);
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _selectedThumbnail = result.files.first);
  }

  Future<void> _upload() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _selectedFile == null) {
      if (_selectedFile == null) {
        _showMessage(
          'Veuillez sélectionner une vidéo.',
          color: _danger,
        );
      }
      return;
    }

    if (_selectedFile!.bytes == null) {
      _showMessage(
        'Le contenu du fichier vidéo est introuvable.',
        color: _danger,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.15;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      setState(() => _uploadProgress = 0.35);

      final videoUrl = await _cloudinaryService.uploadFile(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        folder: 'videos',
      );

      if (videoUrl == null) {
        throw Exception('Upload vidéo failed');
      }

      setState(() => _uploadProgress = 0.65);

      String thumbnailUrl = '';

      if (_selectedThumbnail != null) {
        if (_selectedThumbnail!.bytes == null) {
          throw Exception('Le contenu de la miniature est introuvable.');
        }

        thumbnailUrl = await _cloudinaryService.uploadFile(
              fileBytes: _selectedThumbnail!.bytes!,
              fileName: _selectedThumbnail!.name,
              folder: 'thumbnails',
            ) ??
            '';
      }

      setState(() => _uploadProgress = 0.85);

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

      setState(() => _uploadProgress = 1);

      if (!mounted) return;

      _showMessage(
        'Vidéo uploadée avec succès.',
        color: _success,
      );

      context.go('/videos');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur : $e',
        color: _danger,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _resetForm() {
    if (_isUploading) return;

    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _durationController.clear();
      _selectedFile = null;
      _selectedThumbnail = null;
      _isPublic = true;
      _uploadProgress = 0;
    });
  }

  void _showMessage(String message, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  String _fileSizeLabel(int size) {
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 32,
            18,
            compact ? 16 : 32,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(compact),
                  const SizedBox(height: 22),
                  compact
                      ? Column(
                          children: [
                            _buildFormCard(),
                            const SizedBox(height: 18),
                            _buildUploadCard(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _buildFormCard(),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              flex: 4,
                              child: _buildUploadCard(),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/videos'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajouter une vidéo',
                style: TextStyle(
                  color: _text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Publiez une vidéo pédagogique avec catégorie, durée et miniature.',
                style: TextStyle(
                  color: _muted,
                  fontSize: compact ? 13 : 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset'),
            style: _outlineButtonStyle(),
          ),
        ],
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(
              icon: Icons.edit_document,
              title: 'Informations vidéo',
            ),
            const SizedBox(height: 20),

            _styledTextField(
              controller: _titleController,
              label: 'Titre *',
              icon: Icons.title_rounded,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Titre requis' : null,
            ),

            const SizedBox(height: 16),

            _styledTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final small = constraints.maxWidth < 560;

                if (small) {
                  return Column(
                    children: [
                      _styledTextField(
                        controller: _categoryController,
                        label: 'Catégorie',
                        icon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 16),
                      _styledTextField(
                        controller: _durationController,
                        label: 'Durée ex: 12:30',
                        icon: Icons.timer_rounded,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _styledTextField(
                        controller: _categoryController,
                        label: 'Catégorie',
                        icon: Icons.category_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _styledTextField(
                        controller: _durationController,
                        label: 'Durée ex: 12:30',
                        icon: Icons.timer_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            _buildCategorySuggestions(),

            const SizedBox(height: 20),

            _buildVisibilityBox(),

            const SizedBox(height: 24),

            if (_isUploading) ...[
              _buildProgress(),
              const SizedBox(height: 16),
            ],

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded, size: 20),
                label: Text(
                  _isUploading ? 'Upload en cours...' : 'Publier la vidéo',
                ),
                style: _primaryButtonStyle(),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isUploading ? null : _resetForm,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Réinitialiser le formulaire'),
              style: _outlineButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySuggestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final selected =
            _categoryController.text.trim().toLowerCase() ==
                category.toLowerCase();

        return InkWell(
          onTap: () {
            setState(() => _categoryController.text = category);
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _primary : _background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _primary : _border,
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: selected ? Colors.white : _muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVisibilityBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isPublic ? _primarySoft : const Color(0xFFFFE4E8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _isPublic ? Icons.public_rounded : Icons.lock_rounded,
              color: _isPublic ? _primary : _danger,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Vidéo publique' : 'Vidéo privée',
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isPublic
                      ? 'Visible par tous les utilisateurs.'
                      : 'Visible uniquement selon vos règles d’accès.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            activeColor: _primary,
            onChanged: _isUploading
                ? null
                : (value) {
                    setState(() => _isPublic = value);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.cloud_upload_rounded,
            title: 'Fichiers',
          ),
          const SizedBox(height: 18),

          _buildVideoPicker(),

          const SizedBox(height: 16),

          _buildThumbnailPicker(),

          if (_selectedThumbnail?.bytes != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _selectedThumbnail!.bytes!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 20),

          _buildHelpBox(),
        ],
      ),
    );
  }

  Widget _buildVideoPicker() {
    return InkWell(
      onTap: _isUploading ? null : _pickVideo,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _selectedFile == null ? _background : _primarySoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _selectedFile == null ? _border : _primary,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile == null
                  ? Icons.videocam_rounded
                  : Icons.check_circle_rounded,
              size: 52,
              color: _selectedFile == null ? _muted : _primary,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFile == null
                  ? 'Sélectionner une vidéo'
                  : _selectedFile!.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFile == null
                  ? 'Formats vidéo acceptés selon votre navigateur.'
                  : _fileSizeLabel(_selectedFile!.size),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => setState(() => _selectedFile = null),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Retirer la vidéo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _danger,
                  side: const BorderSide(color: _danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    return InkWell(
      onTap: _isUploading ? null : _pickThumbnail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _selectedThumbnail == null ? Colors.white : _primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedThumbnail == null ? _border : _primary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedThumbnail == null
                  ? Icons.image_rounded
                  : Icons.check_circle_rounded,
              color: _selectedThumbnail == null ? _muted : _primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedThumbnail == null
                    ? 'Miniature optionnelle'
                    : _selectedThumbnail!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_selectedThumbnail != null)
              IconButton(
                onPressed: _isUploading
                    ? null
                    : () => setState(() => _selectedThumbnail = null),
                icon: const Icon(
                  Icons.close_rounded,
                  color: _danger,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _primary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ajoutez une miniature claire pour améliorer la visibilité de la vidéo. Si aucune miniature n’est ajoutée, une image par défaut sera affichée.',
              style: TextStyle(
                color: _muted,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: _primarySoft,
            color: _primary,
            minHeight: 7,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Upload ${(100 * _uploadProgress).round()}%',
          style: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: _text,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: _primary,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _danger),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _danger),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w900,
      ),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _primary,
      side: const BorderSide(color: _border),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}