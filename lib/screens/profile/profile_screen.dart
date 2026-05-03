import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../models/resource.dart';
import '../../models/video.dart';
import '../../services/auth_service.dart';
import '../../services/resource_service.dart';
import '../../services/video_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileTab { resources, videos, saved }

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _resourcesService = ResourceService();
  final _videoService = VideoService();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  Profile? _profile;
  List<Resource> _resources = [];
  List<Video> _videos = [];

  final Set<String> _savedResources = {};
  final Set<String> _savedVideos = {};

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  _ProfileTab _tab = _ProfileTab.resources;

  static const _primary = Color(0xFF15196C);
  static const _soft = Color(0xFFEDEEFF);
  static const _bg = Color(0xFFF6F7FB);
  static const _text = Color(0xFF151725);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE4E7EC);
  static const _danger = Color(0xFFBA1A1A);
  static const _success = Color(0xFF12B76A);
  static const _warning = Color(0xFFF79009);

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _uniCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final profile = await _auth.getCurrentProfile();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final resources =
          profile == null ? <Resource>[] : await _resourcesService.getResourcesByAuthor(profile.id);

      final allVideos = await _videoService.getPublicVideos();
      final myVideos =
          userId == null ? <Video>[] : allVideos.where((v) => v.authorId == userId).toList();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _resources = resources;
        _videos = myVideos;
        _nameCtrl.text = profile?.fullName ?? '';
        _bioCtrl.text = profile?.bio ?? '';
        _uniCtrl.text = profile?.university ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Erreur de chargement: $e', _danger);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    try {
      await _auth.updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'university': _uniCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() => _editing = false);
      _snack('Profil mis à jour.', _success);
      await _load();
    } catch (e) {
      _snack('Erreur: $e', _danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    await _auth.signOut();
    if (mounted) context.go('/login');
  }

  void _copyEmail() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    if (email.isEmpty) return;

    Clipboard.setData(ClipboardData(text: email));
    _snack('Email copié.', _primary);
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  String get _email => Supabase.instance.client.auth.currentUser?.email ?? '';

  String get _initial {
    final name = _profile?.fullName.trim();
    return name == null || name.isEmpty ? '?' : name[0].toUpperCase();
  }

  List<Resource> get _filteredResources {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _resources.where((r) => q.isEmpty || r.title.toLowerCase().contains(q)).toList();
  }

  List<Video> get _filteredVideos {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _videos.where((v) => q.isEmpty || v.title.toLowerCase().contains(q)).toList();
  }

  List<Resource> get _savedResourceList =>
      _resources.where((r) => _savedResources.contains(r.id.toString())).toList();

  List<Video> get _savedVideoList =>
      _videos.where((v) => _savedVideos.contains(v.id.toString())).toList();

  int get _approved =>
      _resources.where((r) => r.status == ResourceStatus.approved).length;

  int get _pending =>
      _resources.where((r) => r.status == ResourceStatus.pending).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 32,
              18,
              compact ? 16 : 32,
              120,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    _profileCard(compact),
                    const SizedBox(height: 18),
                    _stats(compact),
                    const SizedBox(height: 18),
                    _libraryCard(compact),
                    // const SizedBox(height: 18),
                    // OutlinedButton.icon(
                    //   onPressed: _signOut,
                    //   icon: const Icon(Icons.logout_rounded),
                    //   label: const Text('Se déconnecter'),
                    //   style: OutlinedButton.styleFrom(
                    //     foregroundColor: _danger,
                    //     side: const BorderSide(color: _danger),
                    //     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon profil',
                style: TextStyle(
                  color: _text,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Gérez votre compte, vos publications et vos éléments sauvegardés.',
                style: TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        _iconButton(Icons.refresh_rounded, _load),
      ],
    );
  }

  Widget _profileCard(bool compact) {
    return _card(
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarBlock(),
                const SizedBox(height: 18),
                _editing ? _editForm() : _profileInfo(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarBlock(),
                const SizedBox(width: 22),
                Expanded(child: _editing ? _editForm() : _profileInfo()),
              ],
            ),
    );
  }

  Widget _avatarBlock() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              _initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _pill(_profile?.isAdmin == true ? 'Admin' : 'Étudiant', _primary),
      ],
    );
  }

  Widget _profileInfo() {
    final name = _profile?.fullName.trim();
    final bio = _profile?.bio.trim();
    final university = _profile?.university.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name == null || name.isEmpty ? 'Utilisateur' : name,
                style: const TextStyle(
                  color: _text,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _iconButton(Icons.edit_rounded, () => setState(() => _editing = true)),
          ],
        ),
        const SizedBox(height: 8),
        _line(Icons.email_rounded, _email.isEmpty ? 'Email non disponible' : _email,
            trailing: IconButton(
              onPressed: _copyEmail,
              icon: const Icon(Icons.copy_rounded, size: 17, color: _muted),
            )),
        if (university != null && university.isNotEmpty)
          _line(Icons.school_rounded, university),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _box(),
          child: Text(
            bio == null || bio.isEmpty ? 'Aucune bio pour le moment.' : bio,
            style: const TextStyle(
              color: _muted,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _editForm() {
    return Column(
      children: [
        _input(_nameCtrl, 'Nom complet', Icons.person_rounded),
        const SizedBox(height: 12),
        _input(_uniCtrl, 'Université', Icons.school_rounded),
        const SizedBox(height: 12),
        _input(_bioCtrl, 'Bio', Icons.notes_rounded, maxLines: 3),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Sauvegarde...' : 'Sauvegarder'),
                style: _primaryBtn(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() => _editing = false);
                        _nameCtrl.text = _profile?.fullName ?? '';
                        _bioCtrl.text = _profile?.bio ?? '';
                        _uniCtrl.text = _profile?.university ?? '';
                      },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Annuler'),
                style: _outlineBtn(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stats(bool compact) {
    final items = [
      _stat(Icons.folder_rounded, 'Ressources', '${_resources.length}', _primary),
      _stat(Icons.play_circle_rounded, 'Vidéos', '${_videos.length}', _primary),
      _stat(Icons.check_circle_rounded, 'Approuvées', '$_approved', _success),
      _stat(Icons.pending_rounded, 'En attente', '$_pending', _warning),
      _stat(Icons.bookmark_rounded, 'Saved',
          '${_savedResources.length + _savedVideos.length}', _primary),
    ];

    return GridView.count(
      crossAxisCount: compact ? 2 : 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: compact ? 1.28 : 1.75,
      children: items,
    );
  }

  Widget _libraryCard(bool compact) {
    return _card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _libraryTop(compact),
          const SizedBox(height: 14),
          _search(),
          const SizedBox(height: 14),
          _tabs(),
          const SizedBox(height: 14),
          _content(),
        ],
      ),
    );
  }

  Widget _libraryTop(bool compact) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Bibliothèque',
            style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        if (!compact)
          PopupMenuButton<String>(
          tooltip: 'Ajouter',
          onSelected: (v) => context.go(v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: '/resources/upload', child: Text('Ajouter ressource')),
            PopupMenuItem(value: '/videos/upload', child: Text('Ajouter vidéo')),
          ],
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter'),
            style: _primaryBtn(),
          ),
        ),
      ],
    );
  }

  Widget _search() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Rechercher...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () => _searchCtrl.clear(),
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _tabs() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _tabBtn('Ressources', _ProfileTab.resources),
          const SizedBox(width: 8),
          _tabBtn('Mes vidéos', _ProfileTab.videos),
          const SizedBox(width: 8),
          _tabBtn('Saved', _ProfileTab.saved),
        ],
      ),
    );
  }

  Widget _content() {
    switch (_tab) {
      case _ProfileTab.resources:
        final list = _filteredResources;
        return list.isEmpty
            ? _empty('Aucune ressource trouvée.')
            : Column(children: list.map(_resourceItem).toList());

      case _ProfileTab.videos:
        final list = _filteredVideos;
        return list.isEmpty
            ? _empty('Aucune vidéo trouvée.')
            : Column(children: list.map(_videoItem).toList());

      case _ProfileTab.saved:
        final empty = _savedResourceList.isEmpty && _savedVideoList.isEmpty;

        if (empty) return _empty('Aucun élément sauvegardé.');

        return Column(
          children: [
            ..._savedResourceList.map(_resourceItem),
            ..._savedVideoList.map(_videoItem),
          ],
        );
    }
  }

  Widget _resourceItem(Resource r) {
    final saved = _savedResources.contains(r.id.toString());
    final color = _statusColor(r.status);

    return _item(
      icon: Text(r.type.icon, style: const TextStyle(fontSize: 22)),
      title: r.title,
      subtitle: r.status.label,
      subtitleColor: color,
      saved: saved,
      onSave: () {
        setState(() {
          saved ? _savedResources.remove(r.id.toString()) : _savedResources.add(r.id.toString());
        });
      },
      onTap: () => context.go('/resources/${r.id}'),
    );
  }

  Widget _videoItem(Video v) {
    final saved = _savedVideos.contains(v.id.toString());

    return _item(
      icon: const Icon(Icons.play_circle_fill_rounded, color: _primary, size: 30),
      title: v.title,
      subtitle: v.category.isEmpty ? 'Vidéo' : v.category,
      subtitleColor: _muted,
      saved: saved,
      onSave: () {
        setState(() {
          saved ? _savedVideos.remove(v.id.toString()) : _savedVideos.add(v.id.toString());
        });
      },
      onTap: () => context.go('/videos/${v.id}'),
    );
  }

  Widget _item({
    required Widget icon,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required bool saved,
    required VoidCallback onSave,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: _box(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: icon),
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
                    style: const TextStyle(color: _text, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSave,
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? _primary : _muted,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: _muted, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, _ProfileTab tab) {
    final selected = _tab == tab;

    return InkWell(
      onTap: () => setState(() => _tab = tab),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? _primary : _border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _muted,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: _box(),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: _primary, size: 42),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: _border),
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, color: _primary, size: 20),
    );
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
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
      ),
      child: child,
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    );
  }

  Color _statusColor(ResourceStatus status) {
    if (status == ResourceStatus.approved) return _success;
    if (status == ResourceStatus.rejected) return _danger;
    return _warning;
  }

  ButtonStyle _primaryBtn() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  ButtonStyle _outlineBtn() {
    return OutlinedButton.styleFrom(
      foregroundColor: _primary,
      side: const BorderSide(color: _border),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}


