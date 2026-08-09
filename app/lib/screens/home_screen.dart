import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/app_settings.dart';
import '../models/room.dart';
import '../services/room_store.dart';
import '../services/wallpaper_lib.dart';
import '../state/chat_theme.dart';
import '../state/room_controller.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import '../widgets/app_logo.dart';
import '../widgets/chat_picture.dart';
import '../widgets/empty_states.dart';
import '../widgets/lain_window.dart';
import '../widgets/shape_box.dart';
import 'chat_screen.dart';
import 'connect_screen.dart';
import 'create_room_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

/// Home: the list of saved rooms (WhatsApp-style) with an animated
/// create/connect action menu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RoomStore? _store;
  List<Room> _rooms = [];
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await RoomStore.load();
    if (!mounted) return;
    setState(() {
      _store = store;
      _rooms = store.getRooms();
    });
  }

  Future<void> _refresh() async {
    final store = _store ??= await RoomStore.load();
    if (!mounted) return;
    setState(() {
      _rooms = store.getRooms();
    });
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  Future<void> _openRoom(Room room) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
    );
    _refresh();
    _showPendingWarning();
  }

  /// Shows a one-shot warning after the user was dropped from a room because
  /// its server went offline (see RoomController.onServerDisconnect).
  void _showPendingWarning() {
    final msg = RoomController.instance.takePendingDisconnect();
    if (msg == null || !mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _DisconnectedCard(message: msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClipOval(child: AppLogo(size: 26)),
            const SizedBox(width: 8),
            const Text('OnionChat'),
          ],
        ),
        centerTitle: true,
        actions: [
          _SettingsMenuButton(
            onSelected: (v) {
              if (v == 'settings') _open(const SettingsScreen());
              if (v == 'theme') _open(const ThemeScreen());
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) {
          final s = ThemeController.instance.settings;
          final content = _rooms.isEmpty
              ? const ThemedEmptyState()
              : _RoomList(
                  rooms: _rooms,
                  onTap: _openRoom,
                  onChanged: _refresh,
                );
          final wallpaper = s.mainWallpaper;
          if (wallpaper == null || wallpaper.isEmpty) return content;
          return Stack(
            fit: StackFit.expand,
            children: [
              Wallpaper(wallpaper).background(context),
              // Light scrim so room names stay readable on busy images.
              const ColoredBox(color: Colors.black26),
              content,
            ],
          );
        },
      ),
      floatingActionButton: _ActionMenu(
        open: _menuOpen,
        onToggle: _toggleMenu,
        onCreate: () => _navigate(CreateRoomScreen()),
        onConnect: () => _navigate(ConnectScreen()),
      ),
    );
  }

  Future<void> _navigate(Widget screen) async {
    _toggleMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    _refresh();
    _showPendingWarning();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    _refresh();
    _showPendingWarning();
  }
}

class _RoomList extends StatelessWidget {
  final List<Room> rooms;
  final void Function(Room) onTap;
  final VoidCallback onChanged;

  const _RoomList({
    required this.rooms,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, i) {
        final room = rooms[i];
        final preview = room.lastMessage ?? (room.isOwner
            ? 'Chat created by you.'
            : 'Joined room');
        return Dismissible(
          key: ValueKey(room.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            final store = await RoomStore.load();
            await store.deleteRoom(room.id);
            onChanged();
            return true;
          },
          child: ListTile(
            onTap: () => onTap(room),
            leading: ChatPictureAvatar(
              picture: room.chatPicture,
              fallbackAvatar:
                  room.avatar ?? ThemeController.instance.settings.avatar,
              initial: room.name,
              size: 46,
              color: _avatarColor(context, room),
            ),
            title: Text(
              room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeLabel(room.lastMessageAt ?? room.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                if (room.isOwner)
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Color _avatarColor(BuildContext context, Room room) {
    final scheme = Theme.of(context).colorScheme;
    final palette = [
      scheme.primary,
      scheme.tertiary,
      scheme.secondary,
      const Color(0xFF7E57C2),
      const Color(0xFF00897B),
    ];
    var hash = 0;
    for (final c in room.name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    }
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Expandable speed-dial: Create Room / Connect.
class _ActionMenu extends StatefulWidget {
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onCreate;
  final VoidCallback onConnect;

  const _ActionMenu({
    required this.open,
    required this.onToggle,
    required this.onCreate,
    required this.onConnect,
  });

  @override
  State<_ActionMenu> createState() => _ActionMenuState();
}

class _ActionMenuState extends State<_ActionMenu> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ChatTheme.of(context).style;

    if (style == ThemeStyle.matrix) return _buildMatrix();
    if (style == ThemeStyle.lain) return _buildLain();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.open) ...[
          _SpeedItem(
            label: 'Create Room',
            icon: Icons.add_chart,
            color: scheme.primary,
            onTap: widget.onCreate,
          )
              .animate()
              .fadeIn(duration: 160.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 220.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 12),
          _SpeedItem(
            label: 'Connect',
            icon: Icons.call_merge_rounded,
            color: scheme.tertiary,
            onTap: widget.onConnect,
          )
              .animate()
              .fadeIn(duration: 160.ms, delay: 60.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 220.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 12),
        ],
        AnimatedRotation(
          turns: widget.open ? 0.125 : 0,
          duration: const Duration(milliseconds: 220),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: FloatingActionButton(
              key: ValueKey(widget.open),
              onPressed: widget.onToggle,
              backgroundColor: widget.open ? Colors.redAccent : scheme.primary,
              shape: style.outlinedFabShape,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.open ? Icons.close : Icons.chat_bubble,
                  key: ValueKey(widget.open),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrix() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.open) ...[
          _MatrixMenuItem(label: 'CREATE ROOM', onTap: widget.onCreate),
          const SizedBox(height: 12),
          _MatrixMenuItem(
            label: 'CONNECT',
            onTap: widget.onConnect,
            delay: 80,
          ),
          const SizedBox(height: 16),
        ],
        _MatrixFab(open: widget.open, onToggle: widget.onToggle),
      ],
    );
  }

  Widget _buildLain() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: widget.open
              ? _LainWindow(
                  key: const ValueKey('lain-window'),
                  onCreate: widget.onCreate,
                  onConnect: widget.onConnect,
                )
              : const SizedBox(key: ValueKey('lain-hidden')),
        ),
        const SizedBox(height: 14),
        _LainFab(open: widget.open, onToggle: widget.onToggle),
      ],
    );
  }
}

class _MatrixMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final int delay;

  const _MatrixMenuItem({
    required this.label,
    required this.onTap,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF00FF41);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: neon,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 3,
              shadows: [
                Shadow(color: Color(0x9900FF41), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 2,
            height: 18,
            decoration: BoxDecoration(
              color: neon,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Color(0xAA00FF41), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: 0.9,
          end: 0,
          duration: 340.ms,
          delay: delay.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 220.ms, delay: delay.ms);
  }
}

class _MatrixFab extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;

  const _MatrixFab({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF00FF41);
    const red = Color(0xFFFF3B30);
    final color = open ? red : neon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                open ? Icons.close : Icons.chat_bubble_outline_rounded,
                key: ValueKey(open),
                color: color,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: open ? 34 : 26,
          height: 2.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _LainWindow extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onConnect;

  const _LainWindow({
    super.key,
    required this.onCreate,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final mainFont = ThemeController.instance.settings.mainFont.trim();
    final font = mainFont.isEmpty ? null : mainFont;
    final card = ThemeController.instance.cardColor;
    final barColor = card ?? const Color(0xFF1A1430);
    final bodyColor = card != null
        ? Color.lerp(card, Colors.black, 0.7)!
        : const Color(0xFF120E1E);
    final borderColor = card ?? const Color(0xFF4A6B6B);
    final dotColor = card != null
        ? onColor(card)
        : const Color(0xFFFF2A6D).withValues(alpha: 0.7);
    final chromeText = card != null ? onColor(card) : const Color(0xFF7A708A);
    return Container(
      width: 216,
      decoration: BoxDecoration(
        color: bodyColor,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.7),
          width: 1,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            color: barColor,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  color: dotColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'WIRED://',
                  style: TextStyle(
                    color: chromeText,
                    fontSize: 12,
                    fontFamily: font,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '[-]',
                  style: TextStyle(
                    color: chromeText,
                    fontSize: 11,
                    fontFamily: font,
                  ),
                ),
              ],
            ),
          ),
          _LainWindowRow(
            prompt: '>',
            label: 'CREATE ROOM',
            onTap: onCreate,
          ),
          Container(
            height: 1,
            color: const Color(0xFF4A6B6B).withValues(alpha: 0.25),
          ),
          _LainWindowRow(
            prompt: '>',
            label: 'CONNECT',
            onTap: onConnect,
          ),
        ],
      ),
    );
  }
}

class _LainWindowRow extends StatelessWidget {
  final String prompt;
  final String label;
  final VoidCallback onTap;

  const _LainWindowRow({
    required this.prompt,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mainFont = ThemeController.instance.settings.mainFont.trim();
    final font = mainFont.isEmpty ? null : mainFont;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '> ',
              style: TextStyle(
                color: const Color(0xFF00B3B3),
                fontFamily: font,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFFB1A8C2),
                fontFamily: font,
                fontSize: 14,
                letterSpacing: 3,
                shadows: const [
                  Shadow(color: Color(0x22FF2A6D), blurRadius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LainFab extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;

  const _LainFab({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = open ? const Color(0xFF8B0000) : const Color(0xFF4A6B6B);
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF16121F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Icon(
          open ? Icons.close : Icons.chat_bubble_outline_rounded,
          color: open ? const Color(0xFFFF8A8A) : const Color(0xFFB1A8C2),
          size: 26,
        ),
      ),
    );
  }
}

class _SpeedItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SpeedItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = ChatTheme.of(context).style;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: style.buttonShape.rippleRadius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: color,
              shape: style.outlinedButtonShape,
              elevation: 4,
              child: InkWell(
                customBorder: style.outlinedButtonShape,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ⋮ overflow menu: a custom popup so its background can be a plain color
/// or a wallpaper image (the built-in PopupMenuButton can't paint images).
/// Honors the Menu color, image, text color, font family and size.
class _SettingsMenuButton extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const _SettingsMenuButton({required this.onSelected});

  @override
  State<_SettingsMenuButton> createState() => _SettingsMenuButtonState();
}

class _SettingsMenuButtonState extends State<_SettingsMenuButton> {
  final GlobalKey _key = GlobalKey();

  static const _menuItems = <(String, IconData, String)>[
    ('settings', Icons.settings_outlined, 'Settings'),
    ('theme', Icons.palette_outlined, 'Theme'),
  ];

  Future<void> _open() async {
    final theme = Theme.of(context);
    final tc = ThemeController.instance;
    final s = tc.settings;
    final bgColor =
        tc.menuSettingsBackground ?? theme.colorScheme.surfaceContainer;
    final textColor = tc.menuSettingsText ?? theme.colorScheme.onSurface;
    final font = s.menuSettingsFont.trim().isEmpty ? null : s.menuSettingsFont;
    final size = s.menuSettingsFontSize;
    final width = 200.0;

    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final anchor = RelativeRect.fromLTRB(
      pos.dx - width + (box?.size.width ?? 48),
      pos.dy + (box?.size.height ?? 48),
      0,
      0,
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, _) => _SettingsMenuOverlay(
        anchor: anchor,
        width: width,
        style: ThemeStyle.fromId(s.themeStyle),
        background: tc.menuSettingsWallpaper,
        bgColor: bgColor,
        textStyle: TextStyle(
          color: textColor,
          fontFamily: font,
          fontSize: size,
        ),
        items: _menuItems,
        onSelected: (v) {
          Navigator.of(ctx).pop();
          widget.onSelected(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    final textColor =
        tc.menuSettingsText ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      key: _key,
      onPressed: _open,
      icon: Icon(
        Icons.more_vert,
        color: textColor,
        size: tc.settings.menuSettingsFontSize > 0
            ? tc.settings.menuSettingsFontSize * 1.4
            : null,
      ),
      tooltip: 'Settings and theme',
    );
  }
}

class _SettingsMenuOverlay extends StatelessWidget {
  final RelativeRect anchor;
  final double width;
  final ThemeStyle style;
  final String? background;
  final Color bgColor;
  final TextStyle textStyle;
  final List<(String, IconData, String)> items;
  final ValueChanged<String> onSelected;

  const _SettingsMenuOverlay({
    required this.anchor,
    required this.width,
    required this.style,
    required this.background,
    required this.bgColor,
    required this.textStyle,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final left = anchor.left.clamp(8.0, screenSize.width - width - 8);
    final top = anchor.top;
    final child = switch (style) {
      ThemeStyle.lain => _buildLain(context),
      ThemeStyle.matrix => _buildMatrix(context),
      ThemeStyle.cyberpunk => _buildCyberpunk(context),
      ThemeStyle.bladerunner => _buildBladerunner(context),
      _ => _buildDefault(context),
    };
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    (String, IconData, String) item,
    EdgeInsets padding,
    Color? hover, [
    Widget Function(BuildContext, Color, IconData)? iconBuilder,
  ]) {
    final color = textStyle.color;
    return InkWell(
      onTap: () => onSelected(item.$1),
      child: Container(
        color: hover,
        child: Padding(
          padding: padding,
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                if (iconBuilder != null)
                  iconBuilder(context, color ?? Colors.white, item.$2)
                else ...[
                  Icon(item.$2, size: 20, color: color),
                  const SizedBox(width: 12),
                ],
                Text(
                  item.$3,
                  style: textStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefault(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: background != null
                    ? Wallpaper(background).background(context)
                    : ColoredBox(color: bgColor),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items)
                    _row(context, item, const EdgeInsets.symmetric(horizontal: 14, vertical: 12), null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLain(BuildContext context) {
    final menuBg = ThemeController.instance.menuSettingsBackground;
    final barColor = menuBg ?? const Color(0xFF1A1430);
    final accent = menuBg ?? const Color(0xFF4A6B6B);
    final dotColor =
        menuBg != null ? onColor(menuBg) : const Color(0xFFFF2A6D).withValues(alpha: 0.7);
    final chromeText = menuBg != null ? onColor(menuBg) : const Color(0xFF7A708A);
    final bodyColor = menuBg != null
        ? Color.lerp(menuBg, Colors.black, 0.7)!
        : const Color(0xFF120E1E);
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
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
      child: Stack(
        children: [
          Positioned.fill(
            child: background != null
                ? Wallpaper(background).background(context)
                : ColoredBox(color: bodyColor),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 26,
                color: barColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, color: dotColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WIRED://SYSTEM',
                        style: TextStyle(
                          color: chromeText,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontFamily: textStyle.fontFamily,
                        ),
                      ),
                    ),
                    Text(
                      '[-]',
                      style: TextStyle(
                        color: chromeText,
                        fontSize: 10,
                        fontFamily: textStyle.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              for (final item in items)
                _row(
                  context,
                  item,
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  const Color(0x0DFFFFFF),
                  (c, color, icon) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(icon, size: 14, color: accent),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrix(BuildContext context) {
    final green = const Color(0xFF00FF41);
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: green, width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: background != null
                ? Wallpaper(background).background(context)
                : const ColoredBox(color: Color(0xFF0A0F0A)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
                child: Text(
                  '> SYS://MENU',
                  style: TextStyle(
                    color: green,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),
              for (final item in items)
                _row(context, item, const EdgeInsets.fromLTRB(10, 9, 10, 9), null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCyberpunk(BuildContext context) {
    final cyan = const Color(0xFF00F0FF);
    final yellow = const Color(0xFFFCE300);
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: cyan.withValues(alpha: 0.7), width: 1.6),
        ),
        boxShadow: [BoxShadow(color: cyan.withValues(alpha: 0.35), blurRadius: 22)], 
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: background != null
                ? Wallpaper(background).background(context)
                : const ColoredBox(color: Color(0xFF120716)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 4),
                child: Row(
                  children: [
                    Text('//', style: TextStyle(color: yellow, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text(
                      'SYS://MENU',
                      style: TextStyle(color: yellow, fontSize: 11, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              for (final item in items)
                _row(
                  context,
                  item,
                  const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  const Color(0x0AFCE300),
                  (c, color, icon) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(icon, size: 18, color: cyan),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBladerunner(BuildContext context) {
    final amber = const Color(0xFFFFB347);
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: amber.withValues(alpha: 0.6), width: 1.2),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: background != null
                ? Wallpaper(background).background(context)
                : const ColoredBox(color: Color(0xFF10141A)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFF1A222C),
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Text(
                  'NEXUS // MENU',
                  style: TextStyle(color: amber, fontSize: 10, letterSpacing: 2),
                ),
              ),
              for (final item in items)
                _row(context, item, const EdgeInsets.fromLTRB(12, 10, 12, 10), null),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "Disconnected" notice shown after being dropped from a room. Renders as
/// a small system window (WIRED://DISCONNECTED) on the Lain theme and as a
/// themed ShapeBox card otherwise (background color/image + font settings).
class _DisconnectedCard extends StatelessWidget {
  final String message;

  const _DisconnectedCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    final s = tc.settings;
    final style = ThemeStyle.fromId(
      ThemeController.instance.settings.themeStyle,
    );
    if (style == ThemeStyle.lain) {
      return _buildLain(context, tc);
    }
    return _buildPlain(context, tc, s);
  }

  Widget _buildLain(BuildContext context, ThemeController tc) {
    final s = tc.settings;
    final cyan = tc.disconnectedText ?? const Color(0xFF00FF9C);
    final font = s.disconnectedFont.trim().isEmpty ? null : s.disconnectedFont;
    return SizedBox(
      width: 320,
      child: LainWindow(
        title: 'DISCONNECTED',
        font: font,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: const Color(0xFFE7F7FF),
                        shadows: const [
                          Shadow(color: Color(0x6600FF9C), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cyan,
                      border: Border.all(color: cyan),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: onColor(cyan),
                        fontFamily: font,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlain(
    BuildContext context,
    ThemeController tc,
    AppSettings s,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final style = ChatTheme.of(context).style;
    final bg =
        tc.disconnectedBackground ??
        tc.cardColor ??
        style.panelColor ??
        scheme.surfaceContainerHigh;
    final textColor = tc.disconnectedText ?? scheme.onSurface;
    final subColor = (tc.disconnectedText ?? scheme.onSurfaceVariant)
        .withValues(alpha: 0.8);
    final font = s.disconnectedFont.trim().isEmpty ? null : s.disconnectedFont;
    final size = s.disconnectedFontSize;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 40,
            color: subColor.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 12),
          Text(
            'Disconnected',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: font,
                  fontSize: size + 1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subColor,
                  fontFamily: font,
                  fontSize: size * 0.95,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tc.accentColor,
              foregroundColor: onColor(tc.accentColor),
              textStyle: TextStyle(fontFamily: font),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return SizedBox(
      width: 360,
      child: ShapeBox(
        shape: style.cardShape,
        color: bg,
        borderColor: style.edgeColor ?? textColor.withValues(alpha: 0.3),
        borderWidth: style.borderWidth > 0 ? style.borderWidth : 1.5,
        glowColor: style.glowColor,
        glowBlur: style.glowBlur,
        shadow: const BoxShadow(
          color: Colors.black54,
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
        child: Stack(
          children: [
            if (s.disconnectedWallpaper != null)
              Positioned.fill(
                child: Wallpaper(s.disconnectedWallpaper!).background(context),
              ),
            content,
          ],
        ),
      ),
    );
  }
}
