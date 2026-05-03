import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import 'demo_widgets.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final AnimationController _pulseController;
  final GlobalKey _featuresKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToFeatures() {
    final targetContext = _featuresKey.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void _requireAuth(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Débloquez votre espace PFE',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Inscrivez-vous pour télécharger, publier et collaborer avec d\'autres étudiants de licence, master et cycle ingénieur.',
          style: TextStyle(color: Colors.white.withOpacity(0.74), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Plus tard',
              style: TextStyle(color: Colors.white.withOpacity(0.55)),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('Se connecter'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/register');
            },
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 760;
    final horizontalPadding = width >= 1300 ? 56.0 : width >= 1000 ? 38.0 : 18.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
          const FloatingParticles(),
          FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 100),
                    child: _buildTopBar(context, isTablet, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 250),
                    child: _buildHeroSection(context, isDesktop, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 400),
                    child: _buildAudienceBand(isTablet, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 550),
                    child: _buildKeyBenefitsSection(context, isTablet, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      key: _featuresKey,
                      child: _buildPfeJourneySection(isTablet, horizontalPadding),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 850),
                    child: _buildTracksSection(context, isTablet, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 1000),
                    child: _buildContributionSection(context, isTablet, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 1150),
                    child: _buildFinalCta(context, horizontalPadding),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntry(
                    delay: const Duration(milliseconds: 1300),
                    child: _buildFooter(horizontalPadding),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -120 + pulse * 20,
                left: -100 + pulse * 15,
                child: _buildOrb(330 + pulse * 40, AppTheme.primaryColor.withOpacity(0.15 + pulse * 0.08)),
              ),
              Positioned(
                top: 320 - pulse * 25,
                right: -130 + pulse * 20,
                child: _buildOrb(400 + pulse * 30, AppTheme.secondaryColor.withOpacity(0.12 + pulse * 0.06)),
              ),
              Positioned(
                bottom: -140 + pulse * 30,
                left: 40 - pulse * 10,
                child: _buildOrb(360 + pulse * 35, AppTheme.accentColor.withOpacity(0.10 + pulse * 0.07)),
              ),
              Positioned(
                top: 600,
                right: 200,
                child: _buildOrb(200 + pulse * 25, const Color(0xFF0EA5E9).withOpacity(0.08 + pulse * 0.05)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isTablet,
    double horizontalPadding,
  ) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface.withOpacity(0.75),
                AppTheme.darkCard.withOpacity(0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo (2).png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'KHEDMAA.com',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (isTablet) ...[
              TextButton(
                onPressed: _scrollToFeatures,
                child: Text(
                  'Fonctionnalités',
                  style: TextStyle(color: Colors.white.withOpacity(0.72)),
                ),
              ),
              TextButton(
                onPressed: () => _requireAuth(context),
                child: Text(
                  'Parcours PFE',
                  style: TextStyle(color: Colors.white.withOpacity(0.72)),
                ),
              ),
            ],
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Se connecter'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => context.push('/register'),
              child: const Text('Commencer'),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    bool isDesktop,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 22),
      child: Hover3DCard(
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 28 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.94),
                AppTheme.darkSurface.withOpacity(0.85),
                AppTheme.darkCard.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 16)),
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 22, offset: const Offset(0, 14)),
            ],
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 5, child: _buildHeroText(context)),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: _buildHeroVisual(context)),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroText(context),
                    const SizedBox(height: 22),
                    _buildHeroVisual(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillLabel(text: 'Licence'),
            _PillLabel(text: 'Master'),
            _PillLabel(text: 'Cycle ingénieur'),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Réussis ton PFE\navec nous !',
          style: TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'La plateforme N°1 en Tunisie pour les étudiants en Licence, Master et Cycle Ingénieur. Accédez et téléchargez gratuitement des ressources (rapports, présentations, code) et tutoriels vidéos.\n\nEncouragez l\'intelligence collective : uploadez vos ressources pour débloquer des avantages exclusifs pour votre carrière !',
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 15,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Créer mon espace PFE'),
            ),
            OutlinedButton.icon(
              onPressed: _scrollToFeatures,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Explorer les fonctionnalités'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _AnimatedMiniMetric(value: '12k+', label: 'Ressources', icon: Icons.library_books_rounded, delay: 600),
            _AnimatedMiniMetric(value: '2.6k', label: 'Vidéos', icon: Icons.play_circle_rounded, delay: 750),
            _AnimatedMiniMetric(value: '98%', label: 'Satisfaits', icon: Icons.thumb_up_rounded, delay: 900),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = _pulseController.value;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.08 + glow * 0.04),
                AppTheme.primaryColor.withOpacity(0.03 + glow * 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15 + glow * 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.06 + glow * 0.08),
                blurRadius: 20 + glow * 15,
                spreadRadius: -2,
              ),
            ],
          ),
      child: Column(
        children: [
          _buildPreviewTile(
            icon: Icons.description_rounded,
            title: 'Rapport PFE - Vision par Ordinateur',
            subtitle: 'PDF • 48 pages • 4.8/5',
            gradient: AppTheme.primaryGradient,
          ),
          const SizedBox(height: 10),
          _buildPreviewTile(
            icon: Icons.slideshow_rounded,
            title: 'Présentation de soutenance',
            subtitle: 'PPTX • 32 slides • 1.2k téléchargements',
            gradient: AppTheme.accentGradient,
          ),
          const SizedBox(height: 10),
          _buildPreviewTile(
            icon: Icons.play_circle_fill_rounded,
            title: 'Tutoriel: méthodologie PFE',
            subtitle: 'Vidéo • 24 min • 5 chapitres',
            gradient: AppTheme.warmGradient,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBg.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.secondaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Publiez 3 ressources validées et débloquez des badges de contribution.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildPreviewTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.4),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceBand(bool isTablet, double horizontalPadding) {
    final items = [
      _BandItemData(
        icon: Icons.menu_book_rounded,
        title: 'Licence',
        subtitle: 'Cours fondamentaux, fiches méthodo, exemples de PFE.',
      ),
      _BandItemData(
        icon: Icons.school_rounded,
        title: 'Master',
        subtitle:
            'Rapports avancés, veille scientifique, modèles de soutenance.',
      ),
      _BandItemData(
        icon: Icons.precision_manufacturing_rounded,
        title: 'Cycle ingénieur',
        subtitle: 'Specs techniques, architecture, code source et benchmarks.',
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: isTablet
            ? Row(
                children: items
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildBandItem(item),
                        ),
                      ),
                    )
                    .toList(),
              )
            : Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildBandItem(item),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildBandItem(_BandItemData item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.22),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBenefitsSection(
    BuildContext context,
    bool isTablet,
    double horizontalPadding,
  ) {
    final benefits = [
      _FeatureData(
        icon: Icons.download_for_offline_rounded,
        title: 'Téléchargements multi-formats',
        description:
            'Accédez à des présentations, rapports et codes sources prêts à exploiter pour vos projets.',
        cta: 'Explorer la bibliothèque',
        gradient: AppTheme.primaryGradient,
        tags: const ['PDF', 'PPTX', 'DOCX', 'Code'],
      ),
      _FeatureData(
        icon: Icons.ondemand_video_rounded,
        title: 'Vidéos et tutoriels guidés',
        description:
            'Suivez des contenus explicatifs par niveau et thématique pour accélérer votre progression.',
        cta: 'Regarder des tutoriels',
        gradient: AppTheme.warmGradient,
        tags: const ['Cours filmés', 'Pas à pas', 'Méthodo'],
      ),
      _FeatureData(
        icon: Icons.groups_rounded,
        title: 'Partage et collaboration',
        description:
            'Publiez vos découvertes, échangez avec d\'autres filières et capitalisez sur l\'intelligence collective.',
        cta: 'Rejoindre la communauté',
        gradient: AppTheme.accentGradient,
        tags: const ['Feedback', 'Commentaires', 'Co-apprentissage'],
      ),
      _FeatureData(
        icon: Icons.cloud_upload_rounded,
        title: 'Upload avec avantages futurs',
        description:
            'Contribuez avec vos ressources validées pour gagner visibilité, badges et priorités sur la plateforme.',
        cta: 'Publier une ressource',
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
        ),
        tags: const ['Badges', 'Visibilité', 'Contributeur vérifié'],
      ),
    ];

    return Padding(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expérience complète pour réussir vos PFE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inspirée des meilleures plateformes EdTech, mais pensée pour les besoins réels des étudiants.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth >= 1400
                  ? 4
                  : maxWidth >= 1024
                      ? 3
                      : maxWidth >= 680
                          ? 2
                          : 1;
              final ratio = crossAxisCount == 1
                  ? 1.28
                  : crossAxisCount == 2
                      ? 1.32
                      : crossAxisCount == 3
                          ? 1.08
                          : 0.96;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: benefits.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (context, index) {
                  return _buildFeatureCard(context, benefits[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureData data) {
    return Hover3DCard(
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _requireAuth(context),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkSurface.withOpacity(0.86),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: data.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                data.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: data.tags
                    .take(3)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.73),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    data.cta,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.55),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPfeJourneySection(bool isTablet, double horizontalPadding) {
    final steps = [
      _StepData(
        number: '1',
        title: 'Définir le sujet',
        description:
            'Inspirez-vous des projets précédents et structurez votre problématique.',
        icon: Icons.lightbulb_rounded,
      ),
      _StepData(
        number: '2',
        title: 'Collecter les ressources',
        description:
            'Téléchargez rapports, slides, bibliographies et exemples de code source.',
        icon: Icons.inventory_2_rounded,
      ),
      _StepData(
        number: '3',
        title: 'Monter en compétence',
        description:
            'Suivez des vidéos ciblées et des tutoriels explicatifs selon votre niveau.',
        icon: Icons.auto_graph_rounded,
      ),
      _StepData(
        number: '4',
        title: 'Publier et valoriser',
        description:
            'Partagez votre production finale pour aider la communauté et gagner des avantages.',
        icon: Icons.workspace_premium_rounded,
      ),
    ];

    return Container(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 22),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.74),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcours guidé vers une soutenance réussie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Une progression claire de la recherche initiale jusqu\'à la publication de votre PFE.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isTablet && constraints.maxWidth >= 760) {
                return Row(
                  children: steps
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: entry.key == steps.length - 1 ? 0 : 10,
                            ),
                            child: _buildStepCard(entry.value),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Column(
                children: steps
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildStepCard(step),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(_StepData step) {
    return Hover3DCard(
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    step.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(step.icon, color: AppTheme.secondaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.64),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTracksSection(
    BuildContext context,
    bool isTablet,
    double horizontalPadding,
  ) {
    final tracks = [
      _TrackData(
        title: 'Pack Licence',
        subtitle: 'Consolider les fondamentaux',
        color: const Color(0xFF22C55E),
        items: const [
          'Méthodologie de rédaction',
          'Exemples de présentations',
          'Tutoriels d\'initiation',
        ],
      ),
      _TrackData(
        title: 'Pack Master',
        subtitle: 'Approche analytique et recherche',
        color: const Color(0xFF0EA5E9),
        items: const [
          'Templates de rapport avancé',
          'Veille bibliographique',
          'Études de cas appliquées',
        ],
      ),
      _TrackData(
        title: 'Pack Cycle ingénieur',
        subtitle: 'Conception et démonstration technique',
        color: const Color(0xFFF59E0B),
        items: const [
          'Architecture de solutions',
          'Référentiels code source',
          'Checklists de soutenance',
        ],
      ),
    ];

    return Padding(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 22, horizontalPadding, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcours adaptés à votre niveau',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Des contenus recommandés selon votre cycle pour aller plus vite sur votre PFE.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isTablet && constraints.maxWidth >= 840) {
                return Row(
                  children: tracks
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: entry.key == tracks.length - 1 ? 0 : 12,
                            ),
                            child: _buildTrackCard(context, entry.value),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Column(
                children: tracks
                    .map(
                      (track) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTrackCard(context, track),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(BuildContext context, _TrackData track) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            track.color.withOpacity(0.14),
            AppTheme.darkCard.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: track.color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: track.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                track.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            track.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...track.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: track.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _requireAuth(context),
              child: const Text('Voir le pack'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionSection(
    BuildContext context,
    bool isTablet,
    double horizontalPadding,
  ) {
    final values = [
      _ValuePoint(
        icon: Icons.workspace_premium_rounded,
        title: 'Badge contributeur',
        subtitle: 'Valorisez votre profil auprès de la communauté.',
      ),
      _ValuePoint(
        icon: Icons.campaign_rounded,
        title: 'Mise en avant des uploads',
        subtitle: 'Vos ressources pertinentes gagnent en visibilité.',
      ),
      _ValuePoint(
        icon: Icons.trending_up_rounded,
        title: 'Accès prioritaire',
        subtitle: 'Profitez de fonctionnalités futures en avant-première.',
      ),
    ];

    return Padding(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.86),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildContributionLeft(context, values),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: _buildContributionRight(context),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildContributionLeft(context, values),
                  const SizedBox(height: 12),
                  _buildContributionRight(context),
                ],
              ),
      ),
    );
  }

  Widget _buildContributionLeft(
      BuildContext context, List<_ValuePoint> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contribuez aujourd\'hui, récoltez demain',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'En uploadant vos ressources PFE, vous aidez les autres étudiants et vous cumulez des avantages concrets pour la suite.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        ...values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(value.icon, color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.63),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _requireAuth(context),
          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
          label: const Text('Uploader ma première ressource'),
        ),
      ],
    );
  }

  Widget _buildContributionRight(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.9),
            AppTheme.darkBg.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tableau de progression',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _buildProgressRow('Ressources uploadées', 3, 5),
          const SizedBox(height: 10),
          _buildProgressRow('Tutoriels terminés', 4, 6),
          const SizedBox(height: 10),
          _buildProgressRow('Avis publiés', 7, 10),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppTheme.secondaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plus que 2 uploads validés pour débloquer le niveau Expert PFE.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _requireAuth(context),
            icon: const Icon(Icons.dashboard_customize_rounded, size: 17),
            label: const Text('Accéder au dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int current, int target) {
    final progress = current / target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.74),
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '$current/$target',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalCta(BuildContext context, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.32),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Transformez votre PFE en réussite collective',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Rejoignez une communauté active, gagnez du temps avec les bonnes ressources et faites progresser les promotions suivantes grâce à vos contributions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/register'),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: const Text('Créer un compte gratuit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('J\'ai déjà un compte'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.65)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(double horizontalPadding) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KHEDMAA.com',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            '© 2026 KHEDMAA.com • La plateforme N°1 en Tunisie pour les étudiants.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.48),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String text;

  const _PillLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.secondaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AnimatedMiniMetric extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final int delay;

  const _AnimatedMiniMetric({required this.value, required this.label, required this.icon, this.delay = 0});

  @override
  State<_AnimatedMiniMetric> createState() => _AnimatedMiniMetricState();
}

class _AnimatedMiniMetricState extends State<_AnimatedMiniMetric> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = CurvedAnimation(parent: _c, curve: Curves.elasticOut).value;
        return Transform.scale(
          scale: v,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.04)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.08), blurRadius: 12)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, color: AppTheme.primaryColor, size: 16),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(widget.label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final String cta;
  final LinearGradient gradient;
  final List<String> tags;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.cta,
    required this.gradient,
    required this.tags,
  });
}

class _StepData {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  _StepData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _TrackData {
  final String title;
  final String subtitle;
  final Color color;
  final List<String> items;

  _TrackData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
  });
}

class _BandItemData {
  final IconData icon;
  final String title;
  final String subtitle;

  _BandItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ValuePoint {
  final IconData icon;
  final String title;
  final String subtitle;

  _ValuePoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
