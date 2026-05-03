import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/admin_settings.dart';
import '../../services/admin_settings_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _adminService = AdminSettingsService();
  final _freeResourceLimitController = TextEditingController();
  AdminSettings _settings = AdminSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _freeResourceLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _adminService.getSettings();
    if (mounted) {
      _freeResourceLimitController.text = '${settings.freeResourceLimit}';
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final success = await _adminService.updateSettings(_settings);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? '✅ Paramètres sauvegardés' : '❌ Erreur de sauvegarde'),
          backgroundColor:
              success ? AppTheme.secondaryColor : AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '⚙️ Paramètres Ressources',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Sauvegarder'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  // Setting 1 — Free resource limit
                  _buildSettingCard(
                    icon: Icons.visibility_rounded,
                    title: 'Limite de ressources gratuites',
                    description:
                        'Limiter le nombre de ressources visibles gratuitement.',
                    isEnabled: _settings.freeResourceLimitEnabled,
                    onToggle: (v) => setState(() => _settings =
                        _settings.copyWith(freeResourceLimitEnabled: v)),
                    child: _settings.freeResourceLimitEnabled
                        ? Row(
                            children: [
                              Text('Limite : ',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6))),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _freeResourceLimitController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                  ),
                                  onChanged: (v) {
                                    final n = int.tryParse(v);
                                    if (n != null) {
                                      setState(() {
                                        _settings = _settings.copyWith(
                                            freeResourceLimit: n);
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text(' ressources',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6))),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Setting 2 — Partial view
                  _buildSettingCard(
                    icon: Icons.blur_on_rounded,
                    title: 'Vue partielle des PDFs',
                    description:
                        'N\'afficher qu\'un certain pourcentage des premières pages.',
                    isEnabled: _settings.partialViewEnabled,
                    onToggle: (v) => setState(() =>
                        _settings = _settings.copyWith(partialViewEnabled: v)),
                    child: _settings.partialViewEnabled
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Afficher : ',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withValues(alpha: 0.6))),
                                  Text(
                                    '${_settings.partialViewPercentage}%',
                                    style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                              Slider(
                                value:
                                    _settings.partialViewPercentage.toDouble(),
                                min: 10,
                                max: 90,
                                divisions: 8,
                                activeColor: AppTheme.primaryColor,
                                onChanged: (v) => setState(() => _settings =
                                    _settings.copyWith(
                                        partialViewPercentage: v.round())),
                              ),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Setting 3 — Exchange required
                  _buildSettingCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Système d\'échange (Give to Get)',
                    description:
                        'Les utilisateurs doivent uploader une ressource pour accéder à une nouvelle.',
                    isEnabled: _settings.exchangeRequired,
                    onToggle: (v) => setState(() =>
                        _settings = _settings.copyWith(exchangeRequired: v)),
                  ),
                  const SizedBox(height: 16),

                  // Setting 4 — Who can upload
                  _buildSettingCard(
                    icon: Icons.upload_file_rounded,
                    title: 'Uploads par les utilisateurs',
                    description:
                        'Permettre aux utilisateurs (non-admin) d\'uploader des ressources.',
                    isEnabled: _settings.allowUserUploads,
                    onToggle: (v) => setState(() =>
                        _settings = _settings.copyWith(allowUserUploads: v)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isEnabled
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child,
          ],
        ],
      ),
    );
  }
}
