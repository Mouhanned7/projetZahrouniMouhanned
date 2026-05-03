import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _primary = Color(0xFF070963);
const _accent = Color(0xFF12C88A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE4EAF2);
const _surface = Color(0xFFF7F9FC);
const _soft = Color(0xFFEFF6FF);
const _dark = Color(0xFF081225);
const _white = Colors.white;

extension _X on BuildContext {
  double get w => MediaQuery.sizeOf(this).width;
  bool get isMobile => w < 700;
  bool get isTablet => w >= 700 && w < 1100;

  double get pad => isMobile
      ? 20
      : isTablet
          ? 42
          : 70;

  double get maxW => 1280;

  double get heroSize => isMobile
      ? 34
      : isTablet
          ? 46
          : 60;
}

void _go(BuildContext context, String path) {
  try {
    context.push(path);
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Route غير موجودة: $path'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _surface,
        body: SafeArea(
          child: ListView(
            children: const [
              _NavBar(),
              _HeroSection(),
              _StatsSection(),
              _ServicesSection(),
              _ResourcesSection(),
              _HowItWorksSection(),
              _UniversitiesSection(),
              _FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= NAVBAR ================= */

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.isMobile ? 68 : 76,
      padding: EdgeInsets.symmetric(horizontal: context.pad),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.school_rounded, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'TuniShare',
            style: TextStyle(
              color: _primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!context.isMobile) ...[
            const SizedBox(width: 44),
            const _NavText('الرئيسية'),
            const _NavText('الخدمات'),
            const _NavText('المكتبة'),
            const _NavText('الفيديوهات'),
            const _NavText('الأسعار'),
          ],
          const Spacer(),
          if (!context.isMobile) ...[
            _SmallButton(
              text: 'دخول',
              outlined: true,
              onTap: () => _go(context, '/login'),
            ),
            const SizedBox(width: 12),
            _SmallButton(
              text: 'إبدا توا',
              onTap: () => _go(context, '/register'),
            ),
          ] else
            IconButton(
              onPressed: () => _go(context, '/menu'),
              icon: const Icon(Icons.menu_rounded, color: _primary),
            ),
        ],
      ),
    );
  }
}

class _NavText extends StatelessWidget {
  final String text;

  const _NavText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Text(
        text,
        style: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/* ================= HERO ================= */

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: context.isMobile ? 48 : 90,
      bottom: context.isMobile ? 70 : 110,
      child: context.isMobile
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroText(),
                SizedBox(height: 42),
                _HeroPhoto(),
              ],
            )
          : const Row(
              children: [
                Expanded(flex: 6, child: _HeroText()),
                SizedBox(width: 70),
                Expanded(flex: 5, child: _HeroPhoto()),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Pill('منصّة تونسية للطلبة'),
        const SizedBox(height: 28),
        Text.rich(
          TextSpan(
            text: 'كود، عروض، تقارير\nوفيديوهات ',
            children: const [
              TextSpan(
                text: 'في بلاصة وحدة',
                style: TextStyle(color: _accent),
              ),
            ],
          ),
          style: TextStyle(
            color: _primary,
            fontSize: context.heroSize,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'TuniShare تعاون الطلبة في تونس يلقاو موارد جاهزة ومنظّمة: code، présentations، rapports، videos، وشرح واضح للمشاريع الجامعية.',
          style: TextStyle(
            color: _muted,
            fontSize: 16,
            height: 1.85,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 34),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MainButton(
              text: 'إبدا مجاناً',
              onTap: () => _go(context, '/register'),
            ),
            _MainButton(
              text: 'شوف المكتبة',
              outlined: true,
              onTap: () => _go(context, '/resources'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Wrap(
          spacing: 18,
          runSpacing: 12,
          children: [
            _Check('كود منظّم'),
            _Check('تقارير جاهزة'),
            _Check('عروض تقديم'),
            _Check('فيديوهات شرح'),
          ],
        ),
      ],
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: context.isMobile ? 1.05 : .95,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _soft,
                alignment: Alignment.center,
                child: const Icon(Icons.groups_rounded,
                    color: _primary, size: 70),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _line),
                ),
                child: const Text(
                  'طلبة يخدمو على مشاريع، تقارير، وعروض جامعية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= STATS ================= */

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: 0,
      bottom: context.isMobile ? 70 : 110,
      child: const _ResponsiveGrid(
        minItemWidth: 220,
        spacing: 18,
        children: [
          _StatCard(Icons.people_alt_rounded, '+18K', 'طالب'),
          _StatCard(Icons.code_rounded, '+4.2K', 'كود ومشاريع'),
          _StatCard(Icons.slideshow_rounded, '+1.8K', 'عروض وتقارير'),
          _StatCard(Icons.video_library_rounded, '+920', 'فيديو شرح'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.35,
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
}

/* ================= SERVICES ================= */

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      child: _Page(
        top: context.isMobile ? 76 : 110,
        bottom: context.isMobile ? 78 : 120,
        child: const Column(
          children: [
            _TitleBlock(
              label: 'شنوة نقدمو؟',
              title: 'خدمات تساعدك تخدم مشروعك أسرع وبشكل أنظف',
              subtitle:
                  'كل service معمولة باش تعاون الطالب من الفكرة حتى التسليم: كود، rapport، présentation، فيديو، ومصادر منظّمة.',
            ),
            SizedBox(height: 48),
            _ResponsiveGrid(
              minItemWidth: 250,
              spacing: 22,
              children: [
                _ServiceCard(
                  icon: Icons.code_rounded,
                  title: 'كود و مشاريع',
                  body:
                      'أمثلة Flutter, Laravel, Next.js, Python و SQL مع structure واضح وتنظيم محترف.',
                  route: '/code',
                ),
                _ServiceCard(
                  icon: Icons.slideshow_rounded,
                  title: 'برزنطاسيونات',
                  body:
                      'قوالب عروض جاهزة ومنظّمة للـ PFE، TP، exposé، و project pitch.',
                  route: '/presentations',
                ),
                _ServiceCard(
                  icon: Icons.description_rounded,
                  title: 'تقارير و Rapports',
                  body:
                      'نماذج تقارير بالعربية والفرنسية مع introduction، analyse، conception و conclusion.',
                  route: '/reports',
                ),
                _ServiceCard(
                  icon: Icons.play_circle_rounded,
                  title: 'فيديوهات شرح',
                  body:
                      'فيديوهات قصيرة تشرح steps، code، diagrams، وطرق تقديم المشروع.',
                  route: '/videos',
                ),
                _ServiceCard(
                  icon: Icons.bookmark_rounded,
                  title: 'مكتبة محفوظات',
                  body:
                      'Save للموارد المهمة، وتنظيم حسب المادة، السنة، الجامعة، والتكنولوجيا.',
                  route: '/saved',
                ),
                _ServiceCard(
                  icon: Icons.groups_rounded,
                  title: 'مجتمع طلبة',
                  body:
                      'طلبة من تونس يتبادلو حلول، نصائح، أفكار مشاريع، وتجارب تقديم.',
                  route: '/community',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String route;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _go(context, route),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        constraints: const BoxConstraints(minHeight: 245),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: _white, size: 27),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                color: _primary,
                fontSize: 21,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'إكتشف أكثر ←',
              style: TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= RESOURCES ================= */

class _ResourcesSection extends StatelessWidget {
  const _ResourcesSection();

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: context.isMobile ? 76 : 110,
      bottom: context.isMobile ? 76 : 110,
      child: Column(
        children: [
          _SectionHeader(
            title: 'آخر الموارد في المكتبة',
            subtitle:
                'اختار من مشاريع كود، عروض، تقارير وفيديوهات معمولين بطريقة تساعدك تفهم وتخدم.',
            button: 'شوف الكل',
            onTap: () => _go(context, '/resources'),
          ),
          const SizedBox(height: 42),
          const _ResponsiveGrid(
            minItemWidth: 255,
            spacing: 22,
            children: [
              _ResourceCard(
                icon: Icons.code_rounded,
                tag: 'Code',
                title: 'Flutter App للـ PFE',
                body: 'Routing، Auth، Dashboard، و responsive UI.',
                route: '/code',
              ),
              _ResourceCard(
                icon: Icons.slideshow_rounded,
                tag: 'Presentation',
                title: 'عرض PFE جاهز',
                body: 'Slides مرتّبة: problematique، objectifs، demo.',
                route: '/presentations',
              ),
              _ResourceCard(
                icon: Icons.article_rounded,
                tag: 'Report',
                title: 'Rapport UML',
                body: 'Use case، class diagram، sequence diagram.',
                route: '/reports',
              ),
              _ResourceCard(
                icon: Icons.smart_display_rounded,
                tag: 'Video',
                title: 'شرح API Integration',
                body: 'كيفاش تربط frontend مع backend خطوة بخطوة.',
                route: '/videos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String tag;
  final String title;
  final String body;
  final String route;

  const _ResourceCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.body,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _go(context, route),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _accent, size: 28),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    tag,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primary,
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= HOW IT WORKS ================= */

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      child: _Page(
        top: context.isMobile ? 76 : 110,
        bottom: context.isMobile ? 76 : 110,
        child: const Column(
          children: [
            _TitleBlock(
              label: 'كيفاش تخدم؟',
              title: 'ثلاث خطوات وتبدأ تستعمل الموارد',
              subtitle:
                  'تدخل، تختار نوع المورد، وتبدأ تخدم على مشروعك بطريقة منظّمة.',
            ),
            SizedBox(height: 42),
            _ResponsiveGrid(
              minItemWidth: 260,
              spacing: 22,
              children: [
                _StepCard(
                  number: '01',
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'إعمل حساب',
                  body: 'سجّل و حدّد المستوى، الجامعة، والتكنولوجيا اللي تهمك.',
                ),
                _StepCard(
                  number: '02',
                  icon: Icons.search_rounded,
                  title: 'لوّج على المورد',
                  body:
                      'اختار Report، Presentation، Code، أو Video حسب حاجتك.',
                ),
                _StepCard(
                  number: '03',
                  icon: Icons.rocket_launch_rounded,
                  title: 'إخدم و طوّر',
                  body:
                      'استعمل المورد، بدّل عليه، وخليه مناسب للمشروع متاعك.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String body;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 34),
              const Spacer(),
              Text(
                number,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primary,
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= UNIVERSITIES ================= */

class _UniversitiesSection extends StatelessWidget {
  const _UniversitiesSection();

  @override
  Widget build(BuildContext context) {
    return _Page(
      top: context.isMobile ? 76 : 110,
      bottom: context.isMobile ? 76 : 110,
      child: const Column(
        children: [
          _TitleBlock(
            label: 'جامعات تونسية',
            title: 'منصّة موجهة للطلبة في تونس',
            subtitle:
                'تنجم تنظّم الموارد حسب الجامعة، المستوى، والتخصص.',
          ),
          SizedBox(height: 42),
          _ResponsiveGrid(
            minItemWidth: 170,
            spacing: 18,
            children: [
              _UniLogo('UTM', 'جامعة تونس المنار'),
              _UniLogo('UCAR', 'جامعة قرطاج'),
              _UniLogo('US', 'جامعة صفاقس'),
              _UniLogo('USO', 'جامعة سوسة'),
              _UniLogo('UM', 'جامعة المنستير'),
              _UniLogo('UVT', 'الجامعة الافتراضية'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UniLogo extends StatelessWidget {
  final String shortName;
  final String name;

  const _UniLogo(this.shortName, this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 125),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9E7FF)),
            ),
            child: Text(
              shortName,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: _primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= FOOTER ================= */

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _dark,
      padding: EdgeInsets.fromLTRB(
        context.pad,
        context.isMobile ? 64 : 90,
        context.pad,
        42,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.maxW),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.isMobile ? 30 : 48),
                decoration: BoxDecoration(
                  color: const Color(0xFF101B31),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _white.withValues(alpha: .10)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'حضّر مشروعك بطريقة محترفة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _white,
                        fontSize: 34,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'كود، برزنطاسيون، rapport، وفيديوهات شرح للطلبة في تونس.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB8C4D9),
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _MainButton(
                      text: 'جرّب المنصّة',
                      onTap: () => _go(context, '/register'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'TuniShare © 2026',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= SHARED ================= */

class _Page extends StatelessWidget {
  final Widget child;
  final double top;
  final double bottom;

  const _Page({
    required this.child,
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pad, top, context.pad, bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.maxW),
          child: child,
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const _ResponsiveGrid({
    required this.children,
    required this.minItemWidth,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            SizedBox(width: double.infinity, child: children[i]),
            if (i != children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final count = ((maxWidth + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, children.length);

        final itemWidth = (maxWidth - spacing * (count - 1)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;

  const _TitleBlock({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primary,
              fontSize: context.isMobile ? 30 : 42,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 15,
              height: 1.75,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleBlock(label: 'المكتبة', title: title, subtitle: subtitle),
          const SizedBox(height: 24),
          _MainButton(text: button, outlined: true, onTap: onTap),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _TitleBlock(label: 'المكتبة', title: title, subtitle: subtitle),
        ),
        const SizedBox(width: 40),
        _MainButton(text: button, outlined: true, onTap: onTap),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8E7FF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final String text;

  const _Check(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: _accent, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool outlined;

  const _MainButton({
    required this.text,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          minimumSize: const Size(154, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: _line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: _primary,
        foregroundColor: _white,
        minimumSize: const Size(154, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Text(text),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool outlined;

  const _SmallButton({
    required this.text,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return _MainButton(text: text, onTap: onTap, outlined: outlined);
  }
}