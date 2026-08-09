import 'dart:async';

import 'package:flutter/material.dart';

import '../services/tor_engine.dart';
import '../services/wallpaper_lib.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import 'lain_window.dart';
import 'tor_log_view.dart';

/// Shows live Tor bootstrap progress (reads the daemon's log lines) with a
/// pulsing onion icon.
///
/// On the Lain theme this renders as a "system window" terminal: window chrome
/// with a mono title bar, a `>` prompt, and a blinking block cursor.
class TorProgressCard extends StatefulWidget {
  final String title;
  final String? subtitle;

  const TorProgressCard({super.key, required this.title, this.subtitle});

  @override
  State<TorProgressCard> createState() => _TorProgressCardState();
}

class _TorProgressCardState extends State<TorProgressCard> {
  final List<String> _recentLogs = [];
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = TorEngine.instance.logs.listen((line) {
      if (!mounted) return;
      setState(() {
        _recentLogs.insert(0, line);
        if (_recentLogs.length > 6) _recentLogs.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _clean(String l) =>
      l.replaceFirst(RegExp(r'^.*?\[notice\]\s*'), '').trim();

  @override
  Widget build(BuildContext context) {
    final style =
        ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    if (style == ThemeStyle.lain) return _buildLain();
    return _buildPlain(context);
  }

  Widget _buildLain() {
    final cyan = ThemeController.instance.cardColor ?? const Color(0xFF00FFFF);
    final windowTitle = widget.title.replaceFirst(
        RegExp(r'…$'), '').toUpperCase();
    return LainWindow(
      title: windowTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '> ',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: cyan,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.subtitle ?? widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: const Color(0xFFE7F7FF),
                      shadows: const [
                        Shadow(color: Color(0x6600FFFF), blurRadius: 6),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TerminalCursor(cyan: cyan),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: cyan.withValues(alpha: 0.4)),
                  color: const Color(0xFF100A1A),
                ),
child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.55,
                  child: ColoredBox(color: cyan),
                ),
              ),
            ),
            if (_recentLogs.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._recentLogs.take(4).map(_buildLogLine),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogLine(String log) {
    final cyan = ThemeController.instance.cardColor ?? const Color(0xFF00FFFF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '  | ',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: cyan.withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: Text(
              _clean(log),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: const Color(0xFF9FD6D6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlain(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tc = ThemeController.instance;
    final s = tc.settings;
    final style =
        ThemeStyle.fromId(tc.settings.themeStyle);
    final cardFont = s.cardFont.trim().isEmpty ? null : s.cardFont;
    final cardSize = s.cardFontSize;
    final cardTextColor = tc.cardText ?? scheme.onSurface;
    final cardSubColor = (tc.cardText ?? scheme.onSurfaceVariant)
        .withValues(alpha: 0.75);
    final bg = tc.cardColor ?? style.panelColor;
    return Card(
      elevation: 4,
      color: bg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (s.cardWallpaper != null)
            Wallpaper(s.cardWallpaper!).background(context),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BouncingOnion(size: 46),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cardTextColor,
                        fontFamily: cardFont,
                        fontSize: cardSize,
                      ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cardSubColor,
                          fontFamily: cardFont,
                          fontSize: cardSize * 0.88,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(6),
                    minHeight: 4,
                  ),
                ),
                if (_recentLogs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _recentLogs.take(3).map((l) {
                        final cleaned = _clean(l);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            cleaned,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: cardSubColor.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingOnion extends StatefulWidget {
  final double size;
  const _BouncingOnion({required this.size});

  @override
  State<_BouncingOnion> createState() => _BouncingOnionState();
}

class _BouncingOnionState extends State<_BouncingOnion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Transform.scale(
          scale: 0.9 + 0.2 * t,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.55),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 18 + 14 * t,
                ),
              ],
            ),
            child: Icon(Icons.wifi_tethering,
                size: widget.size * 0.55, color: scheme.onPrimary),
          ),
        );
      },
    );
  }
}