import 'package:flutter/material.dart';

import '../services/tor_engine.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import 'lain_window.dart';

/// Tails the latest Tor daemon log line.
///
/// On the Lain theme this renders as a small "Navi"-style terminal window with
/// a title bar and a blinking block cursor; other themes keep a plain card.
class TorLogView extends StatelessWidget {
  const TorLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final style =
        ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    return ValueListenableBuilder<String>(
      valueListenable: TorEngine.instance.lastLogNotifier,
      builder: (context, lastLog, _) {
        if (lastLog.isEmpty) return const SizedBox.shrink();
        final line = lastLog
            .replaceFirst(RegExp(r'^.*?\[notice\]\s*'), '')
            .trim();
        if (style == ThemeStyle.lain) return _LainTerminal(line);
        return _PlainCard(line);
      },
    );
  }
}

class _LainTerminal extends StatelessWidget {
  final String line;

  const _LainTerminal(this.line);

  @override
  Widget build(BuildContext context) {
    final cyan = ThemeController.instance.cardColor ?? const Color(0xFF00FFFF);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LainWindow(
        title: 'SYS LOG',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r'system@lain:~$ ',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: cyan,
                ),
              ),
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: const Color(0xFFE7F7FF),
                    shadows: const [
                      Shadow(color: Color(0x6600FFFF), blurRadius: 6),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TerminalCursor(cyan: cyan),
            ],
          ),
        ),
      ),
    );
  }
}

class TerminalCursor extends StatefulWidget {
  final Color cyan;

  const TerminalCursor({super.key, required this.cyan});

  @override
  State<TerminalCursor> createState() => _TerminalCursorState();
}

class _TerminalCursorState extends State<TerminalCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_c),
      child: Text(
        '█',
        style: TextStyle(fontSize: 12, color: widget.cyan),
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  final String line;

  const _PlainCard(this.line);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = ThemeController.instance.cardColor;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card ?? Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Log',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            line,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}