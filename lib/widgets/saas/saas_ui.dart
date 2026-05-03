import 'package:flutter/material.dart';

class SaasColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE11D48);

  static const bg = Color(0xFFF7F8FB);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF94A3B8);
}

class SaasSpacing {
  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 16;
    if (width < 1100) return 24;
    return 32;
  }

  static int gridColumns(BuildContext context, double maxWidth) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 680) return 1;
    if (width < 1050) return 2;
    return (maxWidth / 300).floor().clamp(3, 4);
  }
}

class SaasDecorations {
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: .06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static BoxDecoration card({
    Color color = SaasColors.surface,
    Color borderColor = SaasColors.border,
    double radius = 8,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: softShadow,
    );
  }

  static BoxDecoration subtleCard({
    Color color = SaasColors.surfaceMuted,
    double radius = 8,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: SaasColors.border),
    );
  }
}

class SaasPage extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SaasPage({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final base = SaasSpacing.pagePadding(context);
    return Container(
      color: SaasColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? EdgeInsets.all(base),
          child: child,
        ),
      ),
    );
  }
}

class SaasCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool hoverLift;

  const SaasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.hoverLift = false,
  });

  @override
  State<SaasCard> createState() => _SaasCardState();
}

class _SaasCardState extends State<SaasCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..translateByDouble(0, _hovered && widget.hoverLift ? -3 : 0, 0, 1),
      padding: widget.padding,
      decoration: SaasDecorations.card(
        borderColor:
            _hovered ? SaasColors.primary.withValues(alpha: .28) : SaasColors.border,
      ),
      child: widget.child,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: widget.onTap == null
          ? card
          : GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

class SaasPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final List<Widget> actions;

  const SaasPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SaasColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: SaasColors.primary),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SaasColors.text,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: SaasColors.textMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 20),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ],
    );
  }
}

class SaasEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const SaasEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SaasCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: SaasColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: SaasColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SaasColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SaasColors.textMuted, height: 1.45),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
