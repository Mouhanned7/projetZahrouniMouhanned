import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});
  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_P> _ps;
  @override
  void initState() {
    super.initState();
    final r = Random();
    _ps = List.generate(30, (_) => _P(r));
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _PP(_ps, _c.value), size: Size.infinite));
}

class _P {
  final double x, y, rad, spd, ph;
  final Color col;
  _P(Random r) : x = r.nextDouble(), y = r.nextDouble(), rad = 1.5 + r.nextDouble() * 2.5,
    spd = 0.3 + r.nextDouble() * 0.7, ph = r.nextDouble() * 2 * pi,
    col = [AppTheme.primaryColor, AppTheme.secondaryColor, AppTheme.accentColor, const Color(0xFF0EA5E9), Colors.white][r.nextInt(5)];
}

class _PP extends CustomPainter {
  final List<_P> ps; final double t;
  _PP(this.ps, this.t);
  @override
  void paint(Canvas c, Size s) {
    for (final p in ps) {
      final dx = p.x * s.width + sin(t * 2 * pi * p.spd + p.ph) * 30;
      final dy = (p.y * s.height + t * p.spd * 80) % s.height;
      c.drawCircle(Offset(dx, dy), p.rad, Paint()..color = p.col.withValues(alpha: (0.15 + 0.2 * sin(t * 2 * pi + p.ph)).clamp(0.05, 0.35)));
    }
  }
  @override
  bool shouldRepaint(covariant _PP o) => true;
}

class GlassCard extends StatelessWidget {
  final Widget child; final EdgeInsets padding; final double radius; final Color? glow;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 22, this.glow});
  @override
  Widget build(BuildContext context) => Container(padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      boxShadow: [BoxShadow(color: (glow ?? Colors.black).withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12))],
    ), child: child);
}

class Hover3DCard extends StatefulWidget {
  final Widget child;
  const Hover3DCard({super.key, required this.child});
  @override
  State<Hover3DCard> createState() => _H3State();
}
class _H3State extends State<Hover3DCard> {
  double _rx = 0, _ry = 0; bool _h = false;
  @override
  Widget build(BuildContext c) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() { _h = false; _rx = 0; _ry = 0; }),
    onHover: (e) { final b = c.findRenderObject() as RenderBox; final s = b.size; final p = e.localPosition;
      setState(() { _ry = (p.dx / s.width - 0.5) * 0.03; _rx = -(p.dy / s.height - 0.5) * 0.03; }); },
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_rx)
        ..rotateY(_ry)
        ..scaleByDouble(_h ? 1.02 : 1.0, _h ? 1.02 : 1.0, 1.0, 1.0),
      transformAlignment: Alignment.center, child: widget.child));
}

class StaggeredEntry extends StatefulWidget {
  final Widget child; final Duration delay;
  const StaggeredEntry({super.key, required this.child, this.delay = Duration.zero});
  @override
  State<StaggeredEntry> createState() => _SEState();
}
class _SEState extends State<StaggeredEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() { super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    Future.delayed(widget.delay, () { if (mounted) _c.forward(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(animation: _c,
    builder: (_, child) => Opacity(opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut).value,
      child: Transform.translate(offset: Offset(0, 40 * (1 - CurvedAnimation(parent: _c, curve: Curves.easeOutCubic).value)), child: child)),
    child: widget.child);
}
