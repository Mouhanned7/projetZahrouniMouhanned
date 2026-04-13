import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/profile.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
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
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _profile = null);
      }
    }
  }

  Future<void> _confirmAndSignOut() async {
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
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
            );
          },
        ) ??
        false;

    if (!shouldSignOut) return;

    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/resources')) return 0;
    if (location.startsWith('/videos')) return 1;
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/resources');
      case 1:
        context.go('/videos');
      case 2:
        context.go('/profile');
      case 3:
        context.go('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final isAdmin = _profile?.isAdmin ?? false;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1250;
    final isMedium = width >= 760;
    final showLabels = isWide && _isRailExtended;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061120), Color(0xFF0A1A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
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
                  isMedium ? 16 : 0,
                  isMedium ? 16 : 0,
                  isMedium ? 16 : 0,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg.withOpacity(isMedium ? 0.96 : 1),
                  borderRadius: BorderRadius.circular(isMedium ? 28 : 0),
                  border: isMedium
                      ? Border.all(color: Colors.white.withOpacity(0.06))
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.child,
              ),
            ),
          ],
        ),
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
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: showLabels ? 272 : 90,
      margin: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  showLabels ? 16 : 10, 14, showLabels ? 12 : 10, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo (2).png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  ),
                  if (showLabels) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KHEDMAA.com',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Formations & Freelance',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (canToggle)
                    IconButton(
                      onPressed: () =>
                          setState(() => _isRailExtended = !_isRailExtended),
                      icon: Icon(
                        _isRailExtended
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
            _buildQuickUploadButton(showLabels),
            const SizedBox(height: 12),
            _buildNavItem(
              0,
              Icons.library_books_rounded,
              'Ressources',
              selectedIndex,
              showLabels,
            ),
            _buildNavItem(
              1,
              Icons.play_circle_rounded,
              'Vidéos',
              selectedIndex,
              showLabels,
            ),
            _buildNavItem(
              2,
              Icons.person_rounded,
              'Profil',
              selectedIndex,
              showLabels,
            ),
            if (isAdmin)
              _buildNavItem(
                3,
                Icons.admin_panel_settings_rounded,
                'Admin',
                selectedIndex,
                showLabels,
              ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: EdgeInsets.all(showLabels ? 12 : 8),
                decoration: AppTheme.glassDecoration(opacity: 0.05),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.24),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
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
                                  _profile?.fullName ?? 'Utilisateur',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _profile?.isAdmin == true
                                      ? 'Administrateur'
                                      : 'Étudiant',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (showLabels)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmAndSignOut,
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Se déconnecter'),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: _confirmAndSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        color: Colors.white70,
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

  Widget _buildQuickUploadButton(bool showLabels) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/resources/upload'),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: showLabels ? 14 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: showLabels
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file_rounded, color: Colors.white),
                if (showLabels) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Déposer un PFE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavigationBar(bool isAdmin, int selectedIndex) {
    final maxIndex = isAdmin ? 3 : 2;
    final clampedIndex = selectedIndex > maxIndex ? 0 : selectedIndex;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: clampedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.library_books_rounded),
              label: 'Ressources',
            ),
            const NavigationDestination(
              icon: Icon(Icons.play_circle_rounded),
              label: 'Vidéos',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
            if (isAdmin)
              const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Admin',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      int selectedIndex, bool showLabel) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onItemTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 14 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.26),
                        AppTheme.primaryColor.withOpacity(0.12),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.45)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: showLabel
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.58),
                  size: 22,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white.withOpacity(0.72),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
