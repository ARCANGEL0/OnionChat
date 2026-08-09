import 'package:flutter/material.dart';

import '../state/theme_controller.dart';

class LainWindow extends StatelessWidget {
  final String title;
  final String? font;
  final Widget child;
  final MainAxisSize mainAxisSize;

  const LainWindow({
    super.key,
    required this.title,
    required this.child,
    this.font,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final card = ThemeController.instance.cardColor;
    final accent = card ?? const Color(0xFF4A6B6B);
    final bodyBg = card != null
        ? Color.lerp(card, Colors.black, 0.7)!
        : const Color(0xFF120E1E);
    return Container(
      decoration: BoxDecoration(
        color: bodyBg,
        border: Border.fromBorderSide(
          BorderSide(color: accent.withValues(alpha: 0.45), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LainWindowBar(
            title: title,
            font: font,
            accent: card != null ? accent : null,
          ),
          if (mainAxisSize == MainAxisSize.max)
            Expanded(child: child)
          else
            child,
        ],
      ),
    );
  }
}

class LainWindowBar extends StatelessWidget {
  final String title;
  final String? font;

  /// When the user picked a card override the chrome is painted in that
  /// color (with its own contrast text); otherwise the default teal palette.
  final Color? accent;

  const LainWindowBar({super.key, required this.title, this.font, this.accent});

  Color get _accent => accent ?? const Color(0xFF4A6B6B);

  @override
  Widget build(BuildContext context) {
    final onAccent = onColor(_accent);
    return Container(
      height: 30,
      color: accent != null ? _accent : const Color(0xFF1A1430),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            color: accent != null ? onAccent : const Color(0xFFFF2A6D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'WIRED://$title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent != null ? onAccent : const Color(0xFF7A708A),
                fontSize: 12,
                letterSpacing: 2,
                fontFamily: font,
              ),
            ),
          ),
          Text(
            '[-]',
            style: TextStyle(
              color: accent != null ? onAccent : const Color(0xFF7A708A),
              fontSize: 11,
              fontFamily: font,
            ),
          ),
        ],
      ),
    );
  }
}