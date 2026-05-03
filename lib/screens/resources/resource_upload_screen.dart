import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/resource.dart';
import '../../services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/resource_service.dart';
import '../../services/resource_storage_service.dart';

class ResourceUploadScreen extends StatefulWidget {
  const ResourceUploadScreen({super.key});

  @override
  State<ResourceUploadScreen> createState() => _ResourceUploadScreenState();
}

class _ResourceUploadScreenState extends State<ResourceUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _universityController = TextEditingController();

  final _resourceService = ResourceService();
  final _resourceStorageService = ResourceStorageService();
  final _authService = AuthService();

  ResourceType _selectedType = ResourceType.report;
  String? _selectedSpeciality;
  PlatformFile? _selectedFile;

  bool _isUploading = false;
  double _uploadProgress = 0;

  List<String> _knownUniversities = [];
  String? _selectedUniversity;
  bool _useCustomUniversity = false;

  static const List<String> _specialities = [
    'IOT',
    'GLSI',
    'SIOT',
    'Réseaux',
  ];

  static const String _customUniversityValue = '__custom__';

  static const Color _primary = Color(0xFF15196C);
  static const Color _primarySoft = Color(0xFFEDEEFF);
  static const Color _background = Color(0xFFF6F7FB);
  static const Color _text = Color(0xFF151725);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE4E7EC);
  static const Color _danger = Color(0xFFBA1A1A);
  static const Color _success = Color(0xFF12B76A);

  @override
  void initState() {
    super.initState();
    _loadKnownUniversities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _loadKnownUniversities() async {
    final universities = await _resourceService.getKnownUniversities();

    if (!mounted) return;

    setState(() {
      _knownUniversities = universities;

      if (_knownUniversities.isNotEmpty && _selectedUniversity == null) {
        _selectedUniversity = _knownUniversities.first;
      }
    });
  }

  List<String> _allowedExtensionsForType(ResourceType type) {
    switch (type) {
      case ResourceType.presentation:
        return ['pdf', 'pptx'];
      case ResourceType.report:
        return ['latex', 'tex', 'doc', 'docx', 'pdf'];
      case ResourceType.code:
        return [];
    }
  }

  String _formatsHintForType(ResourceType type) {
    switch (type) {
      case ResourceType.presentation:
        return 'Formats acceptés : .pdf, .pptx';
      case ResourceType.report:
        return 'Formats acceptés : .latex, .tex, .doc, .docx, .pdf';
      case ResourceType.code:
        return 'Format libre. ZIP recommandé pour plusieurs fichiers.';
    }
  }

  bool _isFileAllowedForType(String fileName, ResourceType type) {
    final allowed = _allowedExtensionsForType(type);

    if (allowed.isEmpty) return true;

    final dot = fileName.lastIndexOf('.');

    if (dot < 0 || dot == fileName.length - 1) return false;

    final ext = fileName.substring(dot + 1).toLowerCase();

    return allowed.contains(ext);
  }

  void _onTypeSelected(ResourceType type) {
    final shouldClearCurrent = _selectedFile != null &&
        !_isFileAllowedForType(_selectedFile!.name, type);

    setState(() {
      _selectedType = type;

      if (shouldClearCurrent) {
        _selectedFile = null;
      }
    });

    if (shouldClearCurrent) {
      _showMessage(
        'Le fichier sélectionné ne correspond pas au type choisi. ${_formatsHintForType(type)}',
        color: Colors.orange,
      );
    }
  }

  String _resolveUniversity() {
    if (_knownUniversities.isEmpty || _useCustomUniversity) {
      return _universityController.text.trim();
    }

    return (_selectedUniversity ?? '').trim();
  }

  Future<void> _pickFile() async {
    final allowed = _allowedExtensionsForType(_selectedType);

   final FilePickerResult? result = await FilePicker.pickFiles(
  type: allowed.isEmpty ? FileType.any : FileType.custom,
  allowedExtensions: allowed.isEmpty
      ? null
      : allowed.map((e) => e.replaceAll('.', '')).toList(),
  withData: true,
);
    if (result == null || result.files.isEmpty) return;

    final candidate = result.files.first;

    if (!_isFileAllowedForType(candidate.name, _selectedType)) {
      if (!mounted) return;

      _showMessage(
        'Format non valide pour ${_selectedType.label}. ${_formatsHintForType(_selectedType)}',
        color: _danger,
      );

      return;
    }

    setState(() => _selectedFile = candidate);
  }

  Future<void> _upload() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _selectedFile == null) {
      if (_selectedFile == null) {
        _showMessage(
          'Veuillez sélectionner un fichier.',
          color: _danger,
        );
      }

      return;
    }

    if (!_isFileAllowedForType(_selectedFile!.name, _selectedType)) {
      _showMessage(
        'Format non valide pour ${_selectedType.label}. ${_formatsHintForType(_selectedType)}',
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

      if (_selectedFile!.bytes == null) {
        throw Exception('Le contenu du fichier est introuvable.');
      }

      setState(() => _uploadProgress = 0.35);

      final fileUrl = await _resourceStorageService.uploadResourceFile(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        type: _selectedType,
        userId: userId,
      );

      setState(() => _uploadProgress = 0.65);

      final profile = await _authService.getCurrentProfile();
      final isAdmin = profile?.role == 'admin';
      final selectedUniversity = _resolveUniversity();

      if (selectedUniversity.isNotEmpty &&
          (profile?.university.toLowerCase() ?? '') !=
              selectedUniversity.toLowerCase()) {
        await _authService.updateProfile({
          'university': selectedUniversity,
        });
      }

      final resource = Resource(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        subject: (_selectedSpeciality ?? '').trim(),
        university: selectedUniversity,
        fileUrl: fileUrl,
        fileSize: _selectedFile!.size,
        authorId: userId,
        status: isAdmin ? ResourceStatus.approved : ResourceStatus.pending,
      );

      setState(() => _uploadProgress = 0.85);

      await _resourceService.createResource(resource);

      setState(() => _uploadProgress = 1);

      if (selectedUniversity.isNotEmpty &&
          !_knownUniversities.any(
            (u) => u.toLowerCase() == selectedUniversity.toLowerCase(),
          )) {
        _knownUniversities = [..._knownUniversities, selectedUniversity]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }

      if (!mounted) return;

      _showMessage(
        isAdmin
            ? 'Ressource uploadée et publiée avec succès.'
            : 'Ressource uploadée. En attente de validation.',
        color: _success,
      );

      context.go('/resources');
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

  void _showMessage(String message, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _clearFile() {
    setState(() => _selectedFile = null);
  }

  String _fileSizeLabel(int size) {
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 860;

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
                            _buildFileCard(),
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
                              child: _buildFileCard(),
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
          onTap: () => context.go('/resources'),
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
                'Ajouter une ressource',
                style: TextStyle(
                  color: _text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Publiez un rapport, une présentation ou un fichier de code.',
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
              title: 'Informations',
            ),
            const SizedBox(height: 20),
            const Text(
              'Type de ressource',
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _buildTypeSelector(),
            const SizedBox(height: 8),
            Text(
              _formatsHintForType(_selectedType),
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
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
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpeciality,
              items: _specialities
                  .map(
                    (speciality) => DropdownMenuItem<String>(
                      value: speciality,
                      child: Text(speciality),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSpeciality = value);
              },
              decoration: _inputDecoration(
                label: 'Spécialité *',
                icon: Icons.auto_awesome_rounded,
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez choisir une spécialité.'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildUniversityField(),
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
                  _isUploading ? 'Upload en cours...' : 'Publier la ressource',
                ),
                style: _primaryButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ResourceType.values.map((type) {
        final isSelected = _selectedType == type;

        return InkWell(
          onTap: () => _onTypeSelected(type),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? _primary : _background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _primary : _border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.icon,
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _muted,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUniversityField() {
    if (_knownUniversities.isEmpty) {
      return _styledTextField(
        controller: _universityController,
        label: 'Université',
        icon: Icons.school_rounded,
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue:
              _useCustomUniversity ? _customUniversityValue : _selectedUniversity,
          items: [
            ..._knownUniversities.map(
              (university) => DropdownMenuItem<String>(
                value: university,
                child: Text(university),
              ),
            ),
            const DropdownMenuItem<String>(
              value: _customUniversityValue,
              child: Text('Autre'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              if (value == _customUniversityValue) {
                _useCustomUniversity = true;
                _selectedUniversity = null;
                _universityController.clear();
              } else {
                _useCustomUniversity = false;
                _selectedUniversity = value;
              }
            });
          },
          decoration: _inputDecoration(
            label: 'Université',
            icon: Icons.school_rounded,
          ),
        ),
        if (_useCustomUniversity) ...[
          const SizedBox(height: 16),
          _styledTextField(
            controller: _universityController,
            label: 'Nouvelle université',
            icon: Icons.edit_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildFileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.cloud_upload_rounded,
            title: 'Fichier',
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: _isUploading ? null : _pickFile,
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
                        ? Icons.upload_file_rounded
                        : Icons.check_circle_rounded,
                    size: 52,
                    color: _selectedFile == null ? _muted : _primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile == null
                        ? 'Sélectionner un fichier'
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
                        ? _formatsHintForType(_selectedType)
                        : _fileSizeLabel(_selectedFile!.size),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _clearFile,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Retirer le fichier'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                side: const BorderSide(color: _danger),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _infoBox(),
        ],
      ),
    );
  }

  Widget _infoBox() {
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
              'Les ressources publiées par un utilisateur normal seront en attente de validation. Les admins publient directement.',
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
}
