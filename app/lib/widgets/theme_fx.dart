import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/theme_style.dart';

/// Whole-app CRT effect for scanline/glitch themes (Lain). A subtle graph-paper
/// grid, faint scanlines plus the occasional RGB tear bar layered on top of
/// everything. Decorative only, ignores taps.
class ThemeFX extends StatelessWidget {
  final ThemeStyle style;
  final Widget child;

  const ThemeFX({super.key, required this.style, required this.child});

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (style.useRedVignette)
          const IgnorePointer(
            child: CustomPaint(painter: _RedVignettePainter()),
          ),
        if (style.useHudGrid)
          IgnorePointer(
            child: CustomPaint(
              painter: _GridViewPainter(
                headerHeight: headerHeight,
                lineColor: style.edgeColor ?? const Color(0xFF4A6B6B),
              ),
            ),
          ),
        if (style.useScanlines)
          const IgnorePointer(
            child: CustomPaint(painter: _ScanlinesPainter()),
          ),
        if (style.useGlitch)
          IgnorePointer(child: _GlitchOverlay(tearColors: style.glitchTearColors)),
      ],
    );
  }
}

/// Faint Navi/CoplandOS-style graph grid. Lines every 38px with a slightly
/// bolder major line every 5 cells. Lines are even fainter within the header
/// band (status bar + app bar) so content there reads more solid.
class _GridViewPainter extends CustomPainter {
  final double headerHeight;
  final Color lineColor;

  const _GridViewPainter({required this.headerHeight, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = lineColor.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = lineColor.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final headMinor = Paint()
      ..color = lineColor.withValues(alpha: 0.015)
      ..strokeWidth = 1;
    final headMajor = Paint()
      ..color = lineColor.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    final h = (headerHeight > 0 && headerHeight < size.height)
        ? headerHeight
        : 0.0;
    const minorStep = 38.0;
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final p = i % 5 == 0;
      if (h > 0) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, h),
          p ? headMajor : headMinor,
        );
      }
      canvas.drawLine(
        Offset(x, h),
        Offset(x, size.height),
        p ? major : minor,
      );
      x += minorStep;
      i++;
    }
    var y = 0.0;
    i = 0;
    while (y < size.height) {
      final p = i % 5 == 0;
      final head = h > 0 && y < h;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        p
            ? (head ? headMajor : major)
            : (head ? headMinor : minor),
      );
      y += minorStep;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _GridViewPainter oldDelegate) =>
      oldDelegate.headerHeight != headerHeight ||
      oldDelegate.lineColor != lineColor;
}

class _RedVignettePainter extends CustomPainter {
  const _RedVignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: 1.1,
        colors: const [Color(0x1FFF1A3C), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final cornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 0.9,
        colors: const [Color(0x14FF1A3C), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _RedVignettePainter oldDelegate) => false;
}

class _ScanlinesPainter extends CustomPainter {
  const _ScanlinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    var y = 0.0;
    const step = 3.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += step;
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter oldDelegate) => false;
}

/// Random glitch tears now and then. Kept very faint and rare.
class _GlitchOverlay extends StatefulWidget {
  final List<Color> tearColors;

  const _GlitchOverlay({required this.tearColors});

  @override
  State<_GlitchOverlay> createState() => _GlitchOverlayState();
}

class _GlitchOverlayState extends State<_GlitchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _GlitchPainter(
          seed: (_controller.value * 1200).round(),
          tearColors: widget.tearColors,
        ),
      ),
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final int seed;
  final List<Color> tearColors;

  const _GlitchPainter({required this.seed, required this.tearColors});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    if (rand.nextDouble() > 0.07) return;
    final paints = [
      for (final c in tearColors) Paint()..color = c,
    ];
    final tears = rand.nextDouble() < 0.5 ? 1 : 2;
    for (var i = 0; i < tears; i++) {
      final y = rand.nextDouble() * size.height;
      final h = 1.0 + rand.nextDouble() * 2.0;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, h),
        paints[i % paints.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.tearColors != tearColors;
}