import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/profile.dart';
import '../../models/resource.dart';
import '../../services/auth_service.dart';
import '../../services/resource_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _resourceService = ResourceService();
  Profile? _profile;
  List<Resource> _myResources = [];
  bool _isLoading = true;
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _uniCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final p = await _authService.getCurrentProfile();
    List<Resource> res = [];
    if (p != null) {
      res = await _resourceService.getResourcesByAuthor(p.id);
      _nameCtrl.text = p.fullName;
      _bioCtrl.text = p.bio;
      _uniCtrl.text = p.university;
    }
    if (mounted) {
      setState(() {
        _profile = p;
        _myResources = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    await _authService.updateProfile({
      'full_name': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'university': _uniCtrl.text.trim(),
    });
    setState(() => _isEditing = false);
    _load();
  }

  Future<void> _confirmAndSignOut() async {
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmer la déconnexion'),
            content: const Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSignOut) return;

    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👤 Mon Profil',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 24),

            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        (_profile?.fullName.isNotEmpty == true
                                ? _profile!.fullName
                                : '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _isEditing
                        ? _buildEditForm()
                        : _buildProfileInfo(email),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                _buildStat('Ressources', '${_myResources.length}',
                    AppTheme.primaryColor),
                const SizedBox(width: 12),
                _buildStat(
                    'Rôle',
                    _profile?.isAdmin == true ? 'Admin' : 'Étudiant',
                    AppTheme.secondaryColor),
              ],
            ),
            const SizedBox(height: 32),

            // My resources
            Row(
              children: [
                const Text('Mes Ressources',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/resources/upload'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_myResources.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: AppTheme.glassDecoration(),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 40, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 8),
                    Text('Aucune ressource encore',
                        style: TextStyle(color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              )
            else
              ...(_myResources.take(10).map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.06))),
                    child: Row(children: [
                      Text(r.type.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(r.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(r.status.label,
                                style: TextStyle(
                                  color: r.status == ResourceStatus.approved
                                      ? AppTheme.secondaryColor
                                      : r.status == ResourceStatus.rejected
                                          ? AppTheme.accentColor
                                          : Colors.amber,
                                  fontSize: 11,
                                )),
                          ])),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        color: Colors.white.withOpacity(0.3),
                        onPressed: () => context.go('/resources/${r.id}'),
                      ),
                    ]),
                  ))),

            const SizedBox(height: 28),
            // Logout
            OutlinedButton.icon(
              onPressed: _confirmAndSignOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                side: const BorderSide(color: AppTheme.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_profile?.fullName ?? '',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, size: 18),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        Text(email,
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        if (_profile?.university.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.school_rounded,
                size: 14, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 4),
            Text(_profile!.university,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ]),
        ],
        if (_profile?.bio.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(_profile!.bio,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Nom')),
        const SizedBox(height: 8),
        TextField(
            controller: _uniCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Université')),
        const SizedBox(height: 8),
        TextField(
            controller: _bioCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Bio')),
        const SizedBox(height: 12),
        Row(children: [
          ElevatedButton(onPressed: _save, child: const Text('Sauvegarder')),
          const SizedBox(width: 8),
          TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Annuler')),
        ]),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ]),
    );
  }
}
