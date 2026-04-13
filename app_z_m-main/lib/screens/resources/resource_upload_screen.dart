import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../services/resource_storage_service.dart';
import '../../services/auth_service.dart';

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

  static const List<String> _specialities = ['IOT', 'GLSI', 'SIOT', 'Réseaux'];
  static const String _customUniversityValue = '__custom__';

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
        return 'Formats acceptés: .pdf, .pptx';
      case ResourceType.report:
        return 'Formats acceptés: .latex/.tex, .doc/.docx, .pdf';
      case ResourceType.code:
        return 'Format libre (zip recommandé pour plusieurs fichiers)';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le fichier sélectionné ne correspond pas au type choisi. ${_formatsHintForType(type)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

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

  String _resolveUniversity() {
    if (_knownUniversities.isEmpty || _useCustomUniversity) {
      return _universityController.text.trim();
    }
    return (_selectedUniversity ?? '').trim();
  }

  Future<void> _pickFile() async {
    final allowed = _allowedExtensionsForType(_selectedType);
    final result = await FilePicker.platform.pickFiles(
      type: allowed.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowed.isEmpty ? null : allowed,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final candidate = result.files.first;
      if (!_isFileAllowedForType(candidate.name, _selectedType)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Format non valide pour ${_selectedType.label}. ${_formatsHintForType(_selectedType)}',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        return;
      }
      setState(() => _selectedFile = candidate);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez sélectionner un fichier'),
              backgroundColor: AppTheme.accentColor),
        );
      }
      return;
    }

    if (!_isFileAllowedForType(_selectedFile!.name, _selectedType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Format non valide pour ${_selectedType.label}. ${_formatsHintForType(_selectedType)}',
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      if (_selectedFile!.bytes == null) {
        throw Exception('Le contenu du fichier est introuvable');
      }

      // Upload to Supabase Storage
      setState(() => _uploadProgress = 0.4);
      final fileUrl = await _resourceStorageService.uploadResourceFile(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        type: _selectedType,
        userId: userId,
      );

      setState(() => _uploadProgress = 0.7);

      // Create resource record
      final profile = await _authService.getCurrentProfile();
      final isAdmin = profile?.role == 'admin';
      final selectedUniversity = _resolveUniversity();

      if (selectedUniversity.isNotEmpty &&
          (profile?.university.toLowerCase() ?? '') !=
              selectedUniversity.toLowerCase()) {
        await _authService.updateProfile({'university': selectedUniversity});
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

      await _resourceService.createResource(resource);
      setState(() => _uploadProgress = 1.0);

      if (selectedUniversity.isNotEmpty &&
          !_knownUniversities.any(
              (u) => u.toLowerCase() == selectedUniversity.toLowerCase())) {
        _knownUniversities = [..._knownUniversities, selectedUniversity]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdmin
                ? '✅ Ressource uploadée et publiée avec succès !'
                : '✅ Ressource uploadée ! En attente de validation.'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        context.go('/resources');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.accentColor),
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
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/resources'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05)),
                ),
                const SizedBox(width: 16),
                const Text(
                  '📤 Ajouter une Ressource',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Form
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type selection
                    const Text('Type de ressource',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ResourceType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return GestureDetector(
                          onTap: () => _onTypeSelected(type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white.withOpacity(0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(type.icon,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatsHintForType(_selectedType),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Specialty
                    DropdownButtonFormField<String>(
                      value: _selectedSpeciality,
                      items: _specialities
                          .map(
                            (speciality) => DropdownMenuItem<String>(
                              value: speciality,
                              child: Text(speciality),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSpeciality = value),
                      decoration: const InputDecoration(
                        labelText: 'Spécialité *',
                        prefixIcon: Icon(Icons.auto_awesome_rounded),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Veuillez choisir une spécialité (IOT, GLSI ou SIOT)'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // University list + custom value
                    if (_knownUniversities.isEmpty)
                      TextFormField(
                        controller: _universityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Université',
                          prefixIcon: Icon(Icons.school_rounded),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _useCustomUniversity
                            ? _customUniversityValue
                            : _selectedUniversity,
                        items: [
                          ..._knownUniversities.map(
                            (university) => DropdownMenuItem<String>(
                              value: university,
                              child: Text(university),
                            ),
                          ),
                          const DropdownMenuItem<String>(
                            value: _customUniversityValue,
                            child: Text('Autre (saisir manuellement)'),
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
                        decoration: const InputDecoration(
                          labelText: 'Université',
                          prefixIcon: Icon(Icons.school_rounded),
                        ),
                      ),
                    if (_knownUniversities.isNotEmpty &&
                        _useCustomUniversity) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _universityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nouvelle université',
                          prefixIcon: Icon(Icons.edit_rounded),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // File picker
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedFile != null
                                ? AppTheme.secondaryColor.withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_upload_rounded,
                              size: 48,
                              color: _selectedFile != null
                                  ? AppTheme.secondaryColor
                                  : Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile != null
                                  ? _selectedFile!.name
                                  : 'Cliquez pour sélectionner un fichier',
                              style: TextStyle(
                                color: _selectedFile != null
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Upload progress
                    if (_isUploading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: AppTheme.primaryColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Submit button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _upload,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_rounded, size: 20),
                        label: Text(_isUploading
                            ? 'Upload en cours...'
                            : 'Publier la ressource'),
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
