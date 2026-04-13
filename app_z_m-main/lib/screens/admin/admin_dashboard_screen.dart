import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/admin_settings_service.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminSettingsService();
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
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
            const Text(
              '🛡️ Panel Admin',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tableau de bord et gestion de la plateforme',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 28),

            // Stats grid
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        title: 'Ressources totales',
                        value: '${_stats['totalResources'] ?? 0}',
                        icon: Icons.library_books_rounded,
                        gradient: AppTheme.primaryGradient,
                      ),
                      StatCard(
                        title: 'En attente',
                        value: '${_stats['pendingResources'] ?? 0}',
                        icon: Icons.pending_actions_rounded,
                        gradient: AppTheme.warmGradient,
                      ),
                      StatCard(
                        title: 'Utilisateurs',
                        value: '${_stats['totalUsers'] ?? 0}',
                        icon: Icons.people_rounded,
                        gradient: AppTheme.accentGradient,
                      ),
                      StatCard(
                        title: 'Vidéos',
                        value: '${_stats['totalVideos'] ?? 0}',
                        icon: Icons.play_circle_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 32),

            // Quick actions
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Ressources attente',
                  subtitle: '${_stats['pendingResources'] ?? 0} à valider',
                  color: AppTheme.accentColor,
                  onTap: () => context.go('/admin/resources'),
                ),
                _buildActionCard(
                  icon: Icons.settings_rounded,
                  title: 'Paramètres',
                  subtitle: 'Contrôle d\'accès',
                  color: AppTheme.primaryColor,
                  onTap: () => context.go('/admin/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
