import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_animate/flutter_animate.dart';

import '../state/theme_controller.dart';
import '../themes/theme_style.dart';

class ThemedEmptyState extends StatelessWidget {
  const ThemedEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final style =
            ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
        switch (style) {
          case ThemeStyle.midnight:
            return const _MidnightEmpty();
          case ThemeStyle.matrix:
            return const _MatrixEmpty();
          case ThemeStyle.lain:
            return const _LainEmpty();
          case ThemeStyle.cyberpunk:
            return const _CyberpunkEmpty();
          case ThemeStyle.bladerunner:
            return const _BladerunnerEmpty();
          default:
            return const _DefaultEmpty();
        }
      },
    );
  }
}

class _DefaultEmpty extends StatelessWidget {
  const _DefaultEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 88, color: scheme.primary)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleY(begin: 1, end: 1.08)
                .scaleX(begin: 1, end: 0.96)
                .then()
                .scaleY(begin: 1.08, end: 1)
                .scaleX(begin: 0.96, end: 1)
                .swap(builder: (_, child) => child!)
                .shimmer(blendMode: BlendMode.srcATop)
                .animate()
                .fadeIn(duration: 600.ms),
            const SizedBox(height: 24),
            Text(
              'No rooms yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.3),
            const SizedBox(height: 12),
            Text(
              'Create a room to get an anonymous .onion address, or connect '
              'to a friend by namecode + password.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 500.ms)
                .slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}

class _MidnightEmpty extends StatelessWidget {
  const _MidnightEmpty();

  @override
  Widget build(BuildContext context) {
    return _EmptyLayout(
      visual: const _MidnightMoon(),
      title: 'A quiet night',
      subtitle: 'No rooms yet. Under a silent sky, create a room or connect '
          'to a friend.',
    );
  }
}

class _MidnightMoon extends StatefulWidget {
  const _MidnightMoon();

  @override
  State<_MidnightMoon> createState() => _MidnightMoonState();
}

class _MidnightMoonState extends State<_MidnightMoon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: const Size(150, 150),
        painter: _MoonPainter(_c.value, accent),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final double t;
  final Color accent;

  _MoonPainter(this.t, this.accent);

  static const _stars = [
    Offset(0.12, 0.2),
    Offset(0.86, 0.12),
    Offset(0.72, 0.78),
    Offset(0.08, 0.7),
    Offset(0.4, 0.9),
    Offset(0.92, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.3 * (1 + 0.04 * math.sin(2 * math.pi * t));
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(c, r * 1.6, glow);

    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
        center: c.translate(r * 0.42, r * 0.2),
        radius: r * 0.86,
      ));
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(crescent, Paint()..color = accent);

    final crater = Paint()..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(c + Offset(-r * 0.5, -r * 0.3), r * 0.1, crater);
    canvas.drawCircle(c + Offset(-r * 0.2, r * 0.1), r * 0.06, crater);

    for (var i = 0; i < _stars.length; i++) {
      final ph = (math.sin(2 * math.pi * (t + i * 0.13)) + 1) / 2;
      final p = _stars[i];
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.6 * ph),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.t != t || old.accent != accent;
}

class _MatrixEmpty extends StatelessWidget {
  const _MatrixEmpty();

  @override
  Widget build(BuildContext context) {
    return _EmptyLayout(
      visual: const _MatrixRain(),
      title: 'The system awaits',
      subtitle: 'There is no room created. Follow the rabbit, and invite a '
          'friend to Onion Protected Zion.',
    );
  }
}

class _MatrixRain extends StatefulWidget {
  const _MatrixRain();

  @override
  State<_MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<_MatrixRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF00FF9D);
    return Container(
      width: 150,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: neon.withValues(alpha: 0.8), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            CustomPaint(painter: _MatrixRainPainter(_c.value)),
      ),
    );
  }
}

class _MatrixRainPainter extends CustomPainter {
  final double t;

  _MatrixRainPainter(this.t);

  static const _glyphs =
      'アカサタナハマヤラワ0123456789ABCDEF<>!?ｱｶｻﾀﾅﾊﾏﾔﾗﾜｦ2KLMNOPQRSTUVWXYZ';
  static const _head = Color(0xFFC0FFE8);
  static const _green = Color(0xFF00FF9D);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = 17.0;
    final cols = (size.width / cell).floor().clamp(4, 14);
    for (var x = 0; x < cols; x++) {
      final rng = math.Random(11 + x * 37);
      final speed = 0.5 + rng.nextDouble() * 0.6;
      final phase = rng.nextDouble() * 2000;
      final swap = 4.0 + rng.nextDouble() * 5.0;
      final head = ((t * speed * size.height + phase) %
              (size.height + cell)) -
          cell;
      for (var k = 0; k < 7; k++) {
        final y = head - k * cell;
        if (y < -cell || y > size.height) continue;
        final bucket = (t * swap + k * 0.23).floor();
        final seed = (x * 131 + k * 17 + bucket * 7) * 2654435761 & 0x7fffffff;
        final glyph = _glyphs[seed % _glyphs.length];
        final alpha = k == 0 ? 1.0 : (0.55 - k * 0.07).clamp(0.12, 1.0);
        final tp = TextPainter(
          text: TextSpan(
            text: glyph,
            style: TextStyle(
              color: k == 0 ? _head : _green.withValues(alpha: alpha),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x * cell + (cell - tp.width) / 2, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter old) => old.t != t;
}

class _LainEmpty extends StatelessWidget {
  const _LainEmpty();

  @override
  Widget build(BuildContext context) {
    return _EmptyLayout(
      visual: const _LainWired(),
      title: 'Present Day. Present Time.',
      subtitle: 'The Wired seem quiet. Open a line, or connect to a friend '
          'through the net',
    );
  }
}

class _LainWired extends StatefulWidget {
  const _LainWired();

  @override
  State<_LainWired> createState() => _LainWiredState();
}

class _LainWiredState extends State<_LainWired>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            CustomPaint(painter: _LainWireframePainter(_c.value)),
      ),
    );
  }
}

class _LainWireframePainter extends CustomPainter {
  final double t;

  _LainWireframePainter(this.t);

  static const _line = Color(0xFFA9A28C);
  static const _cyan = Color(0xFF00FFFF);
  static const _magenta = Color(0xFFFF00FF);
  static const _grid = Color(0xFF4A6B6B);

  static const _verts = [
    [-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
    [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1],
  ];
  static const _edges = [
    [0, 1], [1, 2], [2, 3], [3, 0],
    [4, 5], [5, 6], [6, 7], [7, 4],
    [0, 4], [1, 5], [2, 6], [3, 7],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);

    final gridPaint = Paint()
      ..color = _grid.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final a = t * 2 * math.pi;
    final b = 0.35 * math.sin(t * 2 * math.pi * 0.5);
    final r = size.width * 0.3;

    final pts = <Offset>[];
    for (final v in _verts) {
      final x = v[0] * r, y = v[1] * r, z = v[2] * r;
      final yawX = x * math.cos(a) + z * math.sin(a);
      final yawZ = -x * math.sin(a) + z * math.cos(a);
      final pitchY = y * math.cos(b) - yawZ * math.sin(b);
      final pitchZ = y * math.sin(b) + yawZ * math.cos(b);
      final f = 3 * r;
      final s = f / (f + pitchZ);
      pts.add(c + Offset(yawX * s, pitchY * s));
    }

    final gate = math.sin(t * 2 * math.pi * 1.3);
    final glitch = gate > 0.6;
    final j = glitch ? math.sin(t * 2 * math.pi * 23) * 4 : 0.0;

    final main = Paint()
      ..color = _line.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final cyan = Paint()
      ..color = _cyan.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final magenta = Paint()
      ..color = _magenta.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    if (glitch) {
      _draw(canvas, pts, c.translate(-j, 0), cyan);
      _draw(canvas, pts, c.translate(j, 0), magenta);
    }
    _draw(canvas, pts, c, main);
  }

  void _draw(Canvas canvas, List<Offset> pts, Offset shift, Paint paint) {
    final path = Path();
    for (final e in _edges) {
      final p0 = pts[e[0]] + shift;
      final p1 = pts[e[1]] + shift;
      path
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LainWireframePainter old) => old.t != t;
}

class _CyberpunkEmpty extends StatelessWidget {
  const _CyberpunkEmpty();

  @override
  Widget build(BuildContext context) {
    return _EmptyLayout(
      visual: const _CyberpunkMark(),
      title: 'No active netruns',
      subtitle: 'No rooms yet, choom. Spin up a new net or jack into a '
          'friend\u2019s.',
      titleColor: const Color(0xFFFF1A3C),
      subtitleColor: const Color(0xFFFF4D6D).withValues(alpha: 0.85),
      titleGlitchRed: const Color(0xFFFF4D6D),
      titleGlitchCyan: const Color(0xFF00E5FF),
      gap: 10,
    );
  }
}

class _CyberpunkMark extends StatefulWidget {
  const _CyberpunkMark();

  @override
  State<_CyberpunkMark> createState() => _CyberpunkMarkState();
}

class _CyberpunkMarkState extends State<_CyberpunkMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final glyph = _CyberpunkMarkPainter.measureGlyph();
        const pad = 6.0;
        return CustomPaint(
          size: Size(glyph.width + pad * 2, glyph.height + pad * 2),
          painter: _CyberpunkMarkPainter(_c.value),
        );
      },
    );
  }
}

class _CyberpunkMarkPainter extends CustomPainter {
  final double t;

  _CyberpunkMarkPainter(this.t);

  static const _neon = Color(0xFFFF1A3C);
  static const _neonBright = Color(0xFFFF4D6D);
  static const _fontSize = 93.0;

  static TextPainter measureGlyph() {
    return TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: _neonBright,
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Orbitron',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  TextPainter _glyph(double fontSize, Color color) {
    return TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'Orbitron',
          shadows: [
            Shadow(color: _neon.withValues(alpha: 0.5), blurRadius: 12),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final fs = _fontSize;
    final g = math.sin(t * 2 * math.pi * 1.3);
    final flick = 0.82 + 0.18 * math.sin(t * 2 * math.pi * 3.7);
    final drift = math.sin(t * 2 * math.pi * 0.8) * 2;

    final main = _glyph(fs, _neonBright.withValues(alpha: flick));
    final stutter = g > 0.6 ? (t * 40).floor() % 5 - 2 : 0;
    final gp = Offset(
      c.dx - main.width / 2 + drift + stutter,
      c.dy - main.height / 2,
    );

    final intensity = ((g - 0.5) / 0.5).clamp(0.0, 1.0);
    if (intensity > 0) {
      final red =
          _glyph(fs, _neon.withValues(alpha: 0.7 * intensity));
      final cyan = _glyph(
        fs,
        const Color(0xFF00E5FF).withValues(alpha: 0.55 * intensity),
      );
      red.paint(canvas, gp.translate(-3 * intensity, 0));
      cyan.paint(canvas, gp.translate(3 * intensity, 0));
    }

    if (g > 0.35) {
      final rng = math.Random((t * 50).floor());
      final n = 2 + rng.nextInt(2);
      for (var i = 0; i < n; i++) {
        final bandY = gp.dy + rng.nextDouble() * main.height;
        final bandH = 3 + rng.nextDouble() * 5;
        final dx = (rng.nextDouble() - 0.5) * 18;
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, bandY, w, bandH));
        canvas.translate(dx, 0);
        main.paint(canvas, gp);
        canvas.restore();
      }
    }

    main.paint(canvas, gp);
  }

  @override
  bool shouldRepaint(covariant _CyberpunkMarkPainter old) => old.t != t;
}

class _BladerunnerEmpty extends StatelessWidget {
  const _BladerunnerEmpty();

  @override
  Widget build(BuildContext context) {
    return _EmptyLayout(
      visual: const _BrJoi(),
      title: 'You look lonely.',
      subtitle: 'No rooms yet. I can fix that... create a link, or connect '
          'to a friend to share memories.',
    );
  }
}

class _BrJoi extends StatefulWidget {
  const _BrJoi();

  @override
  State<_BrJoi> createState() => _BrJoiState();
}

class _BrJoiState extends State<_BrJoi> with SingleTickerProviderStateMixin {
  static ui.Image? _cached;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _img = _cached;
    if (_img == null) _load();
  }

  Future<void> _load() async {
    final data = await rootBundle.load('assets/misc/joi.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 512,
    );
    final frame = await codec.getNextFrame();
    _cached = frame.image;
    if (!mounted) return;
    setState(() => _img = frame.image);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _img;
    if (img == null) return const SizedBox(width: 168, height: 168);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: const Size(168, 168),
        painter: _BrJoiPainter(_c.value, img),
      ),
    );
  }
}

class _BrJoiPainter extends CustomPainter {
  final double t;
  final ui.Image image;

  _BrJoiPainter(this.t, this.image);

  static const _pink = Color(0xFFFF6AC1);
  static const _magenta = Color(0xFFE6458E);
  static const _cyan = Color(0xFF7FE0FF);
  static const _streak = Color(0xFFFFE6F7);

  static const _bars = <List<double>>[
    [0.135, 0.18, 0.74, 0.42, 1.7],
    [0.212, 0.44, 0.97, 0.30, 1.2],
    [0.305, 0.08, 0.63, 0.46, 2.1],
    [0.398, 0.36, 0.90, 0.28, 1.3],
    [0.472, 0.04, 0.56, 0.38, 1.8],
    [0.561, 0.31, 0.94, 0.33, 1.4],
    [0.663, 0.11, 0.69, 0.44, 2.0],
    [0.742, 0.41, 0.99, 0.30, 1.3],
    [0.838, 0.06, 0.61, 0.37, 1.7],
    [0.915, 0.33, 0.92, 0.26, 1.2],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bob = math.sin(t * 2 * math.pi * 0.4) * 2.0;
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 0.6);

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, w, h);

    canvas.save();
    canvas.clipRect(dst);
    canvas.translate(0, bob);

    canvas.drawImageRect(
      image,
      src,
      dst.inflate(3),
      Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12)
        ..colorFilter = const ColorFilter.mode(_pink, BlendMode.srcATop)
        ..color = Colors.white.withValues(alpha: 0.26 + 0.14 * pulse),
    );

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..blendMode = BlendMode.plus
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 14, sigmaY: 0.7)
        ..colorFilter = const ColorFilter.mode(_pink, BlendMode.srcATop)
        ..color = Colors.white.withValues(alpha: 0.24 + 0.10 * pulse),
    );

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..blendMode = BlendMode.plus
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 7, sigmaY: 0.4)
        ..color = Colors.white.withValues(alpha: 0.20),
    );

    const split = 1.2;
    canvas.drawImageRect(
      image,
      src,
      dst.shift(Offset(-split, 0)),
      Paint()
        ..blendMode = BlendMode.plus
        ..colorFilter = const ColorFilter.mode(_magenta, BlendMode.srcATop)
        ..color = Colors.white.withValues(alpha: 0.20),
    );
    canvas.drawImageRect(
      image,
      src,
      dst.shift(Offset(split, 0)),
      Paint()
        ..blendMode = BlendMode.plus
        ..colorFilter = const ColorFilter.mode(_cyan, BlendMode.srcATop)
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    canvas.drawImageRect(image, src, dst, Paint());

    canvas.saveLayer(dst, Paint()..blendMode = BlendMode.plus);
    canvas.saveLayer(dst, Paint());
    canvas.clipRect(dst);

    for (final b in _bars) {
      final ly = b[0] * h;
      final bar = Rect.fromLTRB(b[1] * w, ly, b[2] * w, ly + b[4]);
      canvas.drawRect(
        bar,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4)
          ..shader = ui.Gradient.linear(
            Offset(bar.left, ly),
            Offset(bar.right, ly),
            [
              _streak.withValues(alpha: 0),
              _streak.withValues(alpha: b[3]),
              _streak.withValues(alpha: b[3] * 0.85),
              _streak.withValues(alpha: 0),
            ],
            [0.0, 0.28, 0.7, 1.0],
          ),
      );
    }

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 6, sigmaY: 0.5),
    );
    canvas.restore();
    canvas.restore();

    for (var i = 0; i < 12; i++) {
      final px = 0.06 + 0.88 * ((i * 0.41) % 1.0);
      final py = 0.08 + 0.86 * ((i * 0.29) % 1.0);
      final pa = 0.12 + 0.32 * (math.sin(t * 2 * math.pi + i * 1.3)).abs();
      final pr = 0.7 + 0.8 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 0.6 + i));
      canvas.drawCircle(
        Offset(px * w, py * h),
        pr,
        Paint()..color = (i.isEven ? _cyan : _pink).withValues(alpha: pa),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrJoiPainter old) =>
      old.t != t || old.image != image;
}

class _GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color red;
  final Color cyan;

  const _GlitchText({
    required this.text,
    required this.style,
    required this.red,
    required this.cyan,
  });

  @override
  State<_GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<_GlitchText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
        )..layout();
        return CustomPaint(
          size: Size(tp.width, tp.height),
          painter: _GlitchTextPainter(
            widget.text,
            widget.style,
            widget.red,
            widget.cyan,
            _c.value,
          ),
        );
      },
    );
  }
}

class _GlitchTextPainter extends CustomPainter {
  final String text;
  final TextStyle? style;
  final Color red;
  final Color cyan;
  final double t;

  _GlitchTextPainter(this.text, this.style, this.red, this.cyan, this.t);

  TextPainter _tp(Color color, double alpha) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: style?.copyWith(color: color.withValues(alpha: alpha)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final g = math.sin(t * 2 * math.pi * 1.3);
    final flick = 0.85 + 0.15 * math.sin(t * 2 * math.pi * 3.7);
    final baseColor = style?.color ?? Colors.white;

    final main = _tp(baseColor, flick);
    final stutter = g > 0.6 ? (t * 40).floor() % 5 - 2 : 0;
    final gp = Offset(stutter.toDouble(), 0);

    final intensity = ((g - 0.5) / 0.5).clamp(0.0, 1.0).toDouble();
    if (intensity > 0) {
      _tp(red, 0.7 * intensity).paint(canvas, gp.translate(-2.5, 0));
      _tp(cyan, 0.6 * intensity).paint(canvas, gp.translate(2.5, 0));
    }

    if (g > 0.35) {
      final rng = math.Random((t * 50).floor());
      final n = 2 + rng.nextInt(2);
      for (var i = 0; i < n; i++) {
        final bandY = rng.nextDouble() * h;
        final bandH = 2.5 + rng.nextDouble() * 4;
        final dx = (rng.nextDouble() - 0.5) * 12;
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, bandY, w, bandH));
        canvas.translate(dx, 0);
        main.paint(canvas, gp);
        canvas.restore();
      }
    }

    main.paint(canvas, gp);
  }

  @override
  bool shouldRepaint(covariant _GlitchTextPainter old) => old.t != t;
}

class _EmptyLayout extends StatelessWidget {
  final Widget visual;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? titleGlitchRed;
  final Color? titleGlitchCyan;
  final double gap;

  const _EmptyLayout({
    required this.visual,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.subtitleColor,
    this.titleGlitchRed,
    this.titleGlitchCyan,
    this.gap = 24,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        );
    final titleWidget = (titleGlitchRed != null && titleGlitchCyan != null)
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 64,
            ),
            child: _GlitchText(
              text: title,
              style: titleStyle,
              red: titleGlitchRed!,
              cyan: titleGlitchCyan!,
            ),
          )
        : Text(
            title,
            textAlign: TextAlign.center,
            style: titleStyle,
          );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            visual,
            SizedBox(height: gap),
            titleWidget
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.3),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: subtitleColor ?? scheme.onSurfaceVariant,
                  ),
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 500.ms)
                .slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}
