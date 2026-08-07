import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'dart:math' as math;

import '../models/chat_message.dart';
import '../services/chat_protocol.dart';
import '../state/chat_theme.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import 'media_content.dart';
import 'profile_avatar.dart';
import 'shape_box.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? myAvatar;
  final String? myName;
  final String? theirAvatar;
  final ValueChanged<String>? onAvatarTap;
  final VoidCallback? onMyAvatarTap;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.myAvatar,
    this.myName,
    this.theirAvatar,
    this.onAvatarTap,
    this.onMyAvatarTap,
    this.onCopy,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _SystemNotice(text: message.text);

    final style = ChatTheme.of(context).style;
    if (style == ThemeStyle.matrix) {
      return _buildMatrix(context);
    }
    if (style == ThemeStyle.lain) {
      return _buildLain(context);
    }

    final scheme = Theme.of(context).colorScheme;
    final chat = ChatTheme.of(context);
    final mine = message.mine;
    final bubbleColor = mine ? chat.myBubble : chat.theirBubble;
    final bubbleText = mine ? chat.myBubbleText : chat.theirBubbleText;
    final senderColor = mine ? chat.myBubble : _senderColor(scheme);
    final tc = ThemeController.instance;
    final chatFont = tc.settings.chatFont.trim();
    final chatFontSize = tc.settings.chatFontSize;
    final chatTextColor = tc.settings.chatTextColor != null
        ? Color(tc.settings.chatTextColor!)
        : null;
    final showTs = message.ts.isNotEmpty;
    final mineName = myName == null || myName!.trim().isEmpty
        ? 'You'
        : myName!.trim();
    final name = mine ? mineName : message.username;
    final edge = style.edgeColor;
    final glow = style.glowColor;
    final gradient = style.gradientBubbles
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(bubbleColor, Colors.white, 0.16) ?? bubbleColor,
              Color.lerp(bubbleColor, Colors.black, 0.20) ?? bubbleColor,
            ],
          )
        : null;

    final bubble = ShapeBox(
      shape: style.bubbleShapeFor(mine),
      color: gradient == null ? bubbleColor : null,
      gradient: gradient,
      borderColor: edge?.withValues(alpha: 0.55),
      borderWidth: style.borderWidth,
      glowColor: glow,
      glowBlur: style.glowBlur,
      shadow: const BoxShadow(
        color: Colors.black26,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 6, 13, 9),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: mine ? bubbleText : senderColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (showTs) ...[
                    const SizedBox(width: 6),
                    Text(
                      message.ts,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: mine
                            ? bubbleText.withValues(alpha: 0.75)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              if (message.isMedia)
                MediaContent(message: message)
              else
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: chatFontSize,
                    height: 1.3,
                    color: chatTextColor ?? bubbleText,
                    fontFamily: chatFont.isEmpty ? null : chatFont,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          InkWell(
            onTap: onAvatarTap == null
                ? null
                : () => onAvatarTap!(message.username),
            customBorder: const CircleBorder(),
            child: ProfileAvatar(
              avatar: theirAvatar,
              initial: _initialOf(message.username),
              size: 34,
              color: senderColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(child: bubble),
        if (mine) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onMyAvatarTap,
            customBorder: const CircleBorder(),
            child: ProfileAvatar(
              avatar: myAvatar,
              initial: 'You',
              size: 34,
              color: senderColor,
            ),
          ),
        ],
      ],
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: _hasMenu ? () => _showMenu(context) : null,
        child: row,
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: mine ? 0.5 : -0.5,
          end: 0,
          duration: 220.ms,
          curve: Curves.easeOut,
        );
  }

  bool get _hasMenu => onCopy != null || onEdit != null || onDelete != null;

  Widget _buildMatrix(BuildContext context) {
    final tc = ThemeController.instance;
    final s = tc.settings;
    final mine = message.mine;
    final neon = const Color(0xFF00FF41);
    final chatTextColor = s.chatTextColor != null
        ? Color(s.chatTextColor!)
        : null;
    final showTs = message.ts.isNotEmpty;
    final mineName = myName == null || myName!.trim().isEmpty
        ? 'You'
        : myName!.trim();
    final name = mine ? mineName : message.username;
    final nameColor = mine
        ? neon
        : _senderColor(Theme.of(context).colorScheme);
    final chatFont = s.chatFont.trim();
    final chatFontSize = s.chatFontSize;

    final line = Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: nameColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (showTs) ...[
              const SizedBox(width: 8),
              Text(
                message.ts,
                style: TextStyle(
                  fontSize: 11,
                  color: neon.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        if (message.isMedia)
          MediaContent(message: message)
        else
          MatrixNeonText(
            text: message.text,
            color: chatTextColor ?? neon,
            fontSize: chatFontSize,
            fontFamily: chatFont.isEmpty ? null : chatFont,
          ),
      ],
    );

    final senderColor = _senderColor(Theme.of(context).colorScheme);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          InkWell(
            onTap: onAvatarTap == null
                ? null
                : () => onAvatarTap!(message.username),
            customBorder: const CircleBorder(),
            child: ProfileAvatar(
              avatar: theirAvatar,
              initial: _initialOf(message.username),
              size: 34,
              color: senderColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: line,
          ),
        ),
        if (mine) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onMyAvatarTap,
            customBorder: const CircleBorder(),
            child: ProfileAvatar(
              avatar: myAvatar,
              initial: 'You',
              size: 34,
              color: senderColor,
            ),
          ),
        ],
      ],
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: _hasMenu ? () => _showMenu(context) : null,
        child: row,
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: mine ? 0.5 : -0.5,
          end: 0,
          duration: 220.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildLain(BuildContext context) {
    final tc = ThemeController.instance;
    final s = tc.settings;
    final scheme = Theme.of(context).colorScheme;
    final mine = message.mine;
    final showTs = message.ts.isNotEmpty;
    final mineName = myName == null || myName!.trim().isEmpty
        ? 'You'
        : myName!.trim();
    final name = mine ? mineName : message.username;
    final senderColor = _senderColor(scheme);
    final nameColor = mine
        ? const Color(0xFF8C7AA8)
        : Color.lerp(senderColor, const Color(0xFF9A9A9A), 0.35)!;
    final chatFont = s.chatFont.trim();
    final chatFontSize = s.chatFontSize;
    final chatTextColor = s.chatTextColor != null
        ? Color(s.chatTextColor!)
        : null;
    final msgColor = chatTextColor ??
        (mine
            ? const Color(0xFFD8CFE6)
            : const Color(0xFFB1A8C2));

    final line = Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: LainGlitchText(
                text: name,
                color: nameColor,
                fontSize: 13,
                bold: true,
                maxLines: 1,
              ),
            ),
            if (showTs) ...[
              const SizedBox(width: 8),
              Text(
                message.ts,
                style: TextStyle(
                  fontSize: 10.5,
                  color: const Color(0xFF5C5470).withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        if (message.isMedia)
          MediaContent(message: message)
        else
          Text(
            message.text,
            style: TextStyle(
              fontSize: chatFontSize,
              height: 1.35,
              color: msgColor,
              fontFamily: chatFont.isEmpty ? null : chatFont,
              letterSpacing: 0.2,
            ),
          ),
      ],
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          InkWell(
            onTap: onAvatarTap == null
                ? null
                : () => onAvatarTap!(message.username),
            customBorder: const CircleBorder(),
            child: ProfileAvatar(
              avatar: theirAvatar,
              initial: _initialOf(message.username),
              size: 26,
              color: senderColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: line,
          ),
        ),
        if (mine) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onMyAvatarTap,
            customBorder: const CircleBorder(),
            child: ProfileAvatar(
              avatar: myAvatar,
              initial: 'You',
              size: 26,
              color: senderColor,
            ),
          ),
        ],
      ],
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: _hasMenu ? () => _showMenu(context) : null,
        child: row,
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: mine ? 0.5 : -0.5,
          end: 0,
          duration: 220.ms,
          curve: Curves.easeOut,
        );
  }

  void _showMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.mine;
    final isText = !message.isMedia;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isText && onCopy != null)
              ListTile(
                leading: Icon(Icons.copy_rounded, color: scheme.primary),
                title: const Text('Copy message'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onCopy!();
                },
              ),
            if (isText && mine && onEdit != null)
              ListTile(
                leading: Icon(Icons.edit_outlined, color: scheme.primary),
                title: const Text('Edit message'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onEdit!();
                },
              ),
            if (mine && onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  'Delete message',
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _initialOf(String username) {
    final s = username.trim();
    if (s.isEmpty) return '?';
    return s.characters.first.toUpperCase();
  }

  Color _senderColor(ColorScheme scheme) {
    final idx = int.tryParse(message.rawColor ?? '');
    if (idx != null && idx >= 0 && idx < kUserColorPalette.length) {
      return Color(kUserColorPalette[idx]);
    }
    return scheme.tertiary;
  }
}

class _SystemNotice extends StatelessWidget {
  final String text;

  const _SystemNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    final s = tc.settings;
    final style = ChatTheme.of(context).style;
    final bg = s.noticeColor != null
        ? Color(s.noticeColor!)
        : const Color(0xFF2A1F4D);
    final fg = s.noticeText != null
        ? Color(s.noticeText!)
        : onColor(bg);
    final font = s.noticeFont.trim();
    final size = s.noticeFontSize;
    final glow = bg.withValues(alpha: 0.55);

    final presenceUser = _presenceUser(text);
    final dotColor =
        presenceUser != null ? _userColor(presenceUser) : null;
    final isLain = style == ThemeStyle.lain;
    final noticeEdge = isLain
        ? const Color(0xFF00FFFF).withValues(alpha: 0.85)
        : (style.edgeColor ?? glow);
    final noticeGlow = isLain ? const Color(0xFF00FFFF) : style.glowColor;
    final noticeBlur = isLain ? 9.0 : style.glowBlur;
    final noticeWidth = isLain
        ? 1.2
        : (style.borderWidth > 0 ? style.borderWidth : 1.0);
    final gradientColors = isLain
        ? [
            bg.withValues(alpha: 0.35),
            bg.withValues(alpha: 0.5),
            bg.withValues(alpha: 0.35),
          ]
        : [
            bg.withValues(alpha: 0.9),
            bg,
            bg.withValues(alpha: 0.9),
          ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ShapeBox(
          shape: style.noticeShape,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradientColors,
          ),
          borderColor: noticeEdge,
          borderWidth: noticeWidth,
          glowColor: noticeGlow,
          glowBlur: noticeBlur,
          shadow: BoxShadow(
            color: glow.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.85),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: fg,
                  fontFamily: font.isEmpty ? null : font,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 320.ms).slideY(
            begin: 0.6,
            end: 0,
            duration: 320.ms,
            curve: Curves.easeOutBack,
          ),
      ),
    );
  }

  String? _presenceUser(String text) {
    final connected = RegExp(r'^(.*?)\s+has connected[!.]?$');
    final disconnected = RegExp(r'^(.*?)\s+has disconnected[!.]?$');
    final mc = connected.firstMatch(text);
    if (mc != null) return mc.group(1);
    final md = disconnected.firstMatch(text);
    if (md != null) return md.group(1);
    return null;
  }

  Color _userColor(String username) {
    var hash = 0;
    for (final code in username.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return Color(kUserColorPalette[hash % kUserColorPalette.length]);
  }
}

class MatrixNeonText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final String? fontFamily;

  const MatrixNeonText({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 15,
    this.fontFamily,
  });

  @override
  State<MatrixNeonText> createState() => _MatrixNeonTextState();
}

class _MatrixNeonTextState extends State<MatrixNeonText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
        final t = _c.value;
        final fast = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 23.0);
        final slow = 0.7 + 0.3 * math.sin(t * 2 * math.pi * 2.4);
        final opacity = (0.82 + 0.18 * slow * (0.6 + 0.4 * fast)).clamp(0.3, 1.0);
        final glowA = (0.5 + 0.3 * fast).clamp(0.0, 1.0);
        final glowB = (0.25 + 0.15 * slow).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 1.3,
              color: widget.color,
              fontFamily: widget.fontFamily,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: widget.color.withValues(alpha: glowA),
                  blurRadius: 6,
                ),
                Shadow(
                  color: widget.color.withValues(alpha: glowB),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LainGlitchText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final String? fontFamily;
  final bool bold;
  final int? maxLines;

  const LainGlitchText({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 15,
    this.fontFamily,
    this.bold = false,
    this.maxLines,
  });

  @override
  State<LainGlitchText> createState() => _LainGlitchTextState();
}

class _LainGlitchTextState extends State<LainGlitchText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 30000),
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
        final t = _c.value;
        final burst = t > 0.93 && t < 0.975;
        final phase = (t - 0.93) / 0.045;
        final jx = burst ? math.sin(phase * math.pi * 22.0) * 2.2 : 0.0;
        final jy = burst ? math.cos(phase * math.pi * 27.0) * 1.2 : 0.0;
        final glow = burst ? 1.0 : 0.0;
        return Transform.translate(
          offset: Offset(jx, jy),
          child: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 1.3,
              color: widget.color,
              fontFamily: widget.fontFamily,
              fontWeight: widget.bold ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 0.4,
              shadows: [
                if (glow > 0)
                  Shadow(
                    color: const Color(0xFFFF2A6D).withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(-1.2, 0),
                  ),
                if (glow > 0)
                  Shadow(
                    color: const Color(0xFF008080).withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(1.2, 0),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}