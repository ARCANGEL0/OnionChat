import 'package:flutter/material.dart';

import '../models/peer_info.dart';
import '../models/room.dart';
import '../services/chat_protocol.dart';
import '../services/room_store.dart';
import '../state/room_controller.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import '../widgets/profile_avatar.dart';

/// A participant's profile card: name, profile picture, bio and when they
/// joined the chat. Rendered as a stylized card inside the blurred overlay
/// opened from the chat.
class PeerProfileScreen extends StatefulWidget {
  final Room room;
  final String username;

  const PeerProfileScreen({
    super.key,
    required this.room,
    required this.username,
  });

  @override
  State<PeerProfileScreen> createState() => _PeerProfileScreenState();
}

class _PeerProfileScreenState extends State<PeerProfileScreen> {
  PeerInfo? _peer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    PeerInfo? info = RoomController.instance.members[widget.username];
    if (info == null) {
      final store = await RoomStore.load();
      for (final p in store.loadMembers(widget.room.id)) {
        if (p.username == widget.username) {
          info = p;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() => _peer = info);
  }

  @override
  Widget build(BuildContext context) {
    final s = ThemeController.instance.settings;
    final peer = _peer;
    final username = widget.username;
    final color = peer?.color ?? 0;

    final bg =
        s.profileBackground != null
            ? Color(s.profileBackground!)
            : const Color(0xFF1A0F2E); // deep dark purple
    final textColor = s.profileText != null
        ? Color(s.profileText!)
        : const Color(0xFFFFFFFF);
    final muted = s.profileSecondaryText != null
        ? Color(s.profileSecondaryText!)
        : const Color(0xFFCBB8E8); // light purple
    final accent = s.profileAccent != null
        ? Color(s.profileAccent!)
        : const Color(0xFF7C3FED); // tor purple
    final profileFont = s.profileFont.trim().isEmpty ? null : s.profileFont;
    final fontSize = s.profileFontSize;

    final style =
        ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    final isMatrix = style == ThemeStyle.matrix;
    final matrixBg = const Color(0xFF04120A);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 26),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isMatrix
              ? [
                  Color.lerp(matrixBg, const Color(0xFF00FF41), 0.05) ??
                      matrixBg,
                  Color.lerp(matrixBg, Colors.black, 0.4) ?? matrixBg,
                ]
              : [
                  Color.lerp(bg, Colors.white, 0.06) ?? bg,
                  Color.lerp(bg, Colors.black, 0.22) ?? bg,
                ],
        ),
        borderRadius: isMatrix
            ? BorderRadius.zero
            : BorderRadius.circular(14),
        border: Border.all(
          color: isMatrix
              ? const Color(0xFF00FF41).withValues(alpha: 0.35)
              : accent.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: isMatrix
            ? [
                BoxShadow(
                  color: const Color(0xFF00FF41).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (isMatrix)
            Positioned.fill(
              child: _MatrixRain(
                color: const Color(0xFF00FF41),
                cellSize: 15,
                opacity: 0.15,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: isMatrix ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isMatrix ? BorderRadius.zero : null,
              border: Border.all(
                color: isMatrix
                    ? const Color(0xFF00FF41).withValues(alpha: 0.55)
                    : accent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isMatrix
                      ? const Color(0xFF00FF41).withValues(alpha: 0.25)
                      : accent.withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
              ],
            ),
            child: ProfileAvatar(
              avatar: peer?.avatar,
              initial: username,
              size: 92,
              color: _senderColor(accent, color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: profileFont,
              fontSize: fontSize + 6,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          if (peer?.bio != null && peer!.bio!.isNotEmpty)
            Text(
              peer.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: profileFont,
                fontSize: fontSize - 1,
                height: 1.45,
                color: muted,
              ),
            )
          else
            Text(
              'No bio yet.',
              style: TextStyle(
                fontFamily: profileFont,
                fontSize: fontSize - 1,
                fontStyle: FontStyle.italic,
                color: muted,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Container(
              height: 1,
              color: accent.withValues(alpha: 0.25),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                _joinedLabel(peer),
                style: TextStyle(
                  fontFamily: profileFont,
                  fontSize: fontSize - 2,
                  color: muted,
                ),
              ),
            ],
          ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  String _joinedLabel(PeerInfo? peer) {
    final joined = peer?.joinedAt;
    if (joined == null) {
      return 'Joined this chat recently';
    }
    final d = joined.toLocal();
    String date;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      date = 'today';
    } else {
      date = '${_months[d.month - 1]} ${d.day}, ${d.year}';
    }
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return 'Joined $date at $hh:$mm';
  }

  Color _senderColor(Color accent, int color) {
    if (color >= 0 && color < kUserColorPalette.length) {
      return Color(kUserColorPalette[color]);
    }
    return accent;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

const _glyphs = 'アィウェオカキクケコサシスセソタチツテトナニヌネノ'
    'ハヒフヘホマミムメモヤユヨラリルレロワヲン'
    '0123456789<>=/';

class _MatrixRain extends StatefulWidget {
  final Color color;
  final double cellSize;
  final double opacity;

  const _MatrixRain({
    required this.color,
    this.cellSize = 15,
    this.opacity = 0.15,
  });

  @override
  State<_MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<_MatrixRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
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
      builder: (context, _) => CustomPaint(
        painter: _MatrixRainPainter(
          color: widget.color,
          cellSize: widget.cellSize,
          opacity: widget.opacity,
          time: _c.value,
        ),
      ),
    );
  }
}

class _MatrixRainPainter extends CustomPainter {
  final Color color;
  final double cellSize;
  final double opacity;
  final double time;

  const _MatrixRainPainter({
    required this.color,
    required this.cellSize,
    required this.opacity,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil() + 2;
    for (var col = 0; col < cols; col += 3) {
      final speed = 0.5 + ((col * 37) % 10) / 14.0;
      final phase = ((col * 83) % 30) / 30.0;
      final headRow = ((time * speed + phase) * rows) % rows;
      final head = headRow.floor();
      final trail = 4;
      for (var t = 0; t < trail; t++) {
        final row = head - t;
        if (row < 0) continue;
        final y = (row - 1) * cellSize;
        if (y < -cellSize || y > size.height) continue;
        final swap = ((time * 7 * speed) + row).floor() ^ (col * 131);
        if (((col + row * 3 + swap) % 4) == 0 && t > 0) continue;
        final idx = (col * 31 + row * 17 + swap) % _glyphs.length;
        final a = opacity *
            (t == 0 ? 1.0 : ((1.0 - t / trail) * 0.65));
        _glyph(canvas, _glyphs[idx], col * cellSize, y, a);
      }
    }
  }

  void _glyph(Canvas canvas, String ch, double x, double y, double a) {
    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          color: color.withValues(alpha: a.clamp(0.0, 1.0)),
          fontSize: cellSize * 0.82,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) =>
      oldDelegate.time != time;
}
