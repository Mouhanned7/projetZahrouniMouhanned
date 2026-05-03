import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({
    super.key,
    required this.child,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _QuickAction {
  resource,
  video,
  social,
}

class _HomeShellState extends State<HomeShell> {
  final _authService = AuthService();

  Profile? _profile;
  bool _isRailExtended = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getCurrentProfile();

      if (!mounted) return;

      setState(() => _profile = profile);
    } catch (_) {
      if (!mounted) return;

      setState(() => _profile = null);
    }
  }

  Future<void> _confirmAndSignOut() async {
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: _ShellColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: const Text(
                'Voulez-vous vraiment vous déconnecter de votre compte ?',
                style: TextStyle(
                  color: _ShellColors.muted,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Se déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ShellColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSignOut) return;

    await _authService.signOut();

    if (!mounted) return;

    context.go('/login');
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/social')) return 0;
    if (location.startsWith('/resources')) return 1;
    if (location.startsWith('/videos')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/admin')) return 4;

    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/social');
        return;
      case 1:
        context.go('/resources');
        return;
      case 2:
        context.go('/videos');
        return;
      case 3:
        context.go('/profile');
        return;
      case 4:
        context.go('/admin');
        return;
    }
  }

  void _handleQuickAction(_QuickAction action) {
    switch (action) {
      case _QuickAction.resource:
        context.go('/resources/upload');
        return;
      case _QuickAction.video:
        context.go('/videos/upload');
        return;
      case _QuickAction.social:
        context.go('/social');
        return;
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Créer',
                    style: TextStyle(
                      color: _ShellColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _sheetActionTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Ajouter une ressource',
                  subtitle: 'Rapport, présentation ou code',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/resources/upload');
                  },
                ),
                const SizedBox(height: 10),
                _sheetActionTile(
                  icon: Icons.video_call_rounded,
                  title: 'Ajouter une vidéo',
                  subtitle: 'Tutoriel ou cours vidéo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/videos/upload');
                  },
                ),
                const SizedBox(height: 10),
                _sheetActionTile(
                  icon: Icons.forum_rounded,
                  title: 'Nouvelle publication',
                  subtitle: 'Partager un lien, une idee ou une ressource',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/social');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final isAdmin = _profile?.isAdmin ?? false;

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1180;
    final isMedium = width >= 760;
    final showLabels = isWide && _isRailExtended;

    return Scaffold(
      backgroundColor: _ShellColors.background,
      body: Row(
        children: [
          if (isMedium)
            _buildSidebar(
              isAdmin: isAdmin,
              selectedIndex: selectedIndex,
              showLabels: showLabels,
              canToggle: isWide,
            ),
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(
                isMedium ? 0 : 0,
                isMedium ? 14 : 0,
                isMedium ? 14 : 0,
                isMedium ? 14 : 0,
              ),
              decoration: BoxDecoration(
                color: _ShellColors.background,
                borderRadius: BorderRadius.circular(isMedium ? 24 : 0),
                border: isMedium
                    ? Border.all(color: _ShellColors.border)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.child,
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          !isMedium ? _buildMobileNavigationBar(isAdmin, selectedIndex) : null,
    );
  }

  Widget _buildSidebar({
    required bool isAdmin,
    required int selectedIndex,
    required bool showLabels,
    required bool canToggle,
  }) {
    final name = _profile?.fullName.trim();
    final initial =
        (name != null && name.isNotEmpty ? name[0] : '?').toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: showLabels ? 264 : 86,
      margin: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ShellColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildBrandHeader(
              showLabels: showLabels,
              canToggle: canToggle,
            ),
            if (canToggle && !showLabels)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() => _isRailExtended = !_isRailExtended);
                  },
                  icon: const Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: _ShellColors.muted,
                    size: 19,
                  ),
                  tooltip: 'Etendre',
                ),
              ),
            const SizedBox(height: 8),
            _buildQuickCreateButton(showLabels),
            const SizedBox(height: 14),
            _buildNavGroup(
              selectedIndex: selectedIndex,
              showLabels: showLabels,
              isAdmin: isAdmin,
            ),
            const Spacer(),
            _buildUserCard(
              showLabels: showLabels,
              initial: initial,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader({
    required bool showLabels,
    required bool canToggle,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        showLabels ? 16 : 10,
        14,
        showLabels ? 10 : 10,
        8,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _ShellColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _ShellColors.primary.withOpacity(0.10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo (2).png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school_rounded,
                    color: _ShellColors.primary,
                    size: 24,
                  );
                },
              ),
            ),
          ),
          if (showLabels) ...[
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KHEDMAA',
                    style: TextStyle(
                      color: _ShellColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Academic workspace',
                    style: TextStyle(
                      color: _ShellColors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canToggle && showLabels)
            IconButton(
              onPressed: () {
                setState(() => _isRailExtended = !_isRailExtended);
              },
              icon: Icon(
                _isRailExtended
                    ? Icons.keyboard_double_arrow_left_rounded
                    : Icons.keyboard_double_arrow_right_rounded,
                color: _ShellColors.muted,
              ),
              tooltip: _isRailExtended ? 'Réduire' : 'Étendre',
            ),
        ],
      ),
    );
  }

  Widget _buildQuickCreateButton(bool showLabels) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: PopupMenuButton<_QuickAction>(
        tooltip: 'Créer',
        onSelected: _handleQuickAction,
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        itemBuilder: (context) => [
          _quickMenuItem(
            action: _QuickAction.resource,
            icon: Icons.upload_file_rounded,
            label: 'Ajouter une ressource',
          ),
          _quickMenuItem(
            action: _QuickAction.video,
            icon: Icons.video_call_rounded,
            label: 'Ajouter une video',
          ),
          _quickMenuItem(
            action: _QuickAction.social,
            icon: Icons.forum_rounded,
            label: 'Ouvrir Social',
          ),
        ],
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: showLabels ? 14 : 0,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: _ShellColors.primary,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _ShellColors.primary.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
                showLabels ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 21,
              ),
              if (showLabels) ...[
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Créer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_QuickAction> _quickMenuItem({
    required _QuickAction action,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(
            icon,
            color: _ShellColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: _ShellColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGroup({
    required int selectedIndex,
    required bool showLabels,
    required bool isAdmin,
  }) {
    return Column(
      children: [
        _buildNavItem(
          index: 0,
          icon: Icons.forum_rounded,
          label: 'Social',
          selectedIndex: selectedIndex,
          showLabel: showLabels,
        ),
        _buildNavItem(
          index: 1,
          icon: Icons.library_books_rounded,
          label: 'Ressources',
          selectedIndex: selectedIndex,
          showLabel: showLabels,
        ),
        _buildNavItem(
          index: 2,
          icon: Icons.play_circle_rounded,
          label: 'Vidéos',
          selectedIndex: selectedIndex,
          showLabel: showLabels,
        ),
        _buildNavItem(
          index: 3,
          icon: Icons.person_rounded,
          label: 'Profil',
          selectedIndex: selectedIndex,
          showLabel: showLabels,
        ),
        if (isAdmin)
          _buildNavItem(
            index: 4,
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin',
            selectedIndex: selectedIndex,
            showLabel: showLabels,
          ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required int selectedIndex,
    required bool showLabel,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      child: Tooltip(
        message: showLabel ? '' : label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _onItemTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 11 : 0,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _ShellColors.primarySoft : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? _ShellColors.primary.withOpacity(0.18)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? _ShellColors.primary : _ShellColors.surface,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : _ShellColors.muted,
                      size: 19,
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? _ShellColors.primary
                              : _ShellColors.muted,
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _ShellColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required bool showLabels,
    required String initial,
  }) {
    final name = _profile?.fullName.trim();
    final displayName = name != null && name.isNotEmpty ? name : 'Utilisateur';
    final role = _profile?.isAdmin == true ? 'Administrateur' : 'Étudiant';

    return Container(
      margin: const EdgeInsets.all(10),
      padding: EdgeInsets.all(showLabels ? 12 : 8),
      decoration: BoxDecoration(
        color: _ShellColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ShellColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment:
                  showLabels ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _ShellColors.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ShellColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: const TextStyle(
                            color: _ShellColors.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (showLabels)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmAndSignOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ShellColors.danger,
                  side: BorderSide(
                    color: _ShellColors.danger.withOpacity(0.25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _confirmAndSignOut,
              icon: const Icon(Icons.logout_rounded),
              color: _ShellColors.danger,
              tooltip: 'Se déconnecter',
            ),
        ],
      ),
    );
  }

  Widget _buildMobileNavigationBar(bool isAdmin, int selectedIndex) {
    final maxIndex = isAdmin ? 4 : 3;
    final clampedIndex = selectedIndex > maxIndex ? 0 : selectedIndex;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _ShellColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: clampedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.white,
            indicatorColor: _ShellColors.primarySoft,
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _mobileDestination(
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum_rounded,
                label: 'Social',
              ),
              _mobileDestination(
                icon: Icons.library_books_outlined,
                selectedIcon: Icons.library_books_rounded,
                label: 'Ressources',
              ),
              _mobileDestination(
                icon: Icons.play_circle_outline_rounded,
                selectedIcon: Icons.play_circle_rounded,
                label: 'Vidéos',
              ),
              _mobileDestination(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profil',
              ),
              if (isAdmin)
                _mobileDestination(
                  icon: Icons.admin_panel_settings_outlined,
                  selectedIcon: Icons.admin_panel_settings_rounded,
                  label: 'Admin',
                ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _mobileDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(
        selectedIcon,
        color: _ShellColors.primary,
      ),
      label: label,
    );
  }

  Widget _sheetActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _ShellColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ShellColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _ShellColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: _ShellColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ShellColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _ShellColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _ShellColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellColors {
  static const primary = Color(0xFF15196C);
  static const primarySoft = Color(0xFFEDEEFF);
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFF9FAFB);
  static const text = Color(0xFF151725);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const danger = Color(0xFFBA1A1A);
}

