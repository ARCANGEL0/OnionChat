import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/room.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import 'app_toast.dart';
import 'lain_window.dart';

/// Bottom sheet showing the room's invite details: onion address, optional password, and a scannable QR code.
class InviteSheet extends StatelessWidget {
  final Room room;

  const InviteSheet({super.key, required this.room});

  String get _qrPayload =>
      'onionchat://join?onion=${Uri.encodeQueryComponent(room.onion)}'
      '${room.password != null ? '&pass=${Uri.encodeQueryComponent(room.password!)}' : ''}'
      '${room.name.isNotEmpty ? '&name=${Uri.encodeQueryComponent(room.name)}' : ''}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style =
        ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    final isLain = style == ThemeStyle.lain;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Invite friends',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Share this onion address and optional password.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: _qrPayload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 20),
          _CopyRow(
            icon: Icons.key,
            label: 'Password',
            value: room.password ?? 'No password',
            monospace: true,
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: isLain ? _LainInvite(_qrPayload, room) : body,
      ),
    );
  }
}

class _LainInvite extends StatelessWidget {
  final String payload;
  final Room room;

  const _LainInvite(this.payload, this.room);

  @override
  Widget build(BuildContext context) {
    final font = ThemeController.instance.settings.mainFont.trim();
    final cyan = const Color(0xFF00FFFF);

    return LainWindow(
      title: 'INVITE FRIENDS',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share this onion address and optional password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: font,
                color: cyan.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF08080F)),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 190,
                  backgroundColor: Colors.white,
                ),
              ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 18),
            _CopyRow(
              icon: Icons.alternate_email,
              label: 'ONION ADDRESS',
              value: room.onion,
              monospace: true,
            ),
            const SizedBox(height: 10),
            if (room.password != null) ...[
              _CopyRow(
                icon: Icons.key,
                label: 'PASSWORD',
                value: room.password!,
                monospace: true,
              ),
              const SizedBox(height: 10),
            ],
            _CopyRow(
              icon: Icons.title,
              label: 'ROOM NAME',
              value: room.name,
            ),
            const SizedBox(height: 10),
            _CopyRow(
              icon: Icons.link,
              label: 'SHARE LINK',
              value: payload,
              monospace: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style =
        ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    final isMatrix = style == ThemeStyle.matrix;
    final isLain = style == ThemeStyle.lain;
    final green = const Color(0xFF00FF41);
    final cyan = const Color(0xFF00FFFF);
    final detailsStyle = isLain
        ? TextStyle(
            fontFamily: monospace ? 'monospace' : null,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE7F7FF),
            shadows: const [
              Shadow(color: Color(0xA600FFFF), blurRadius: 10),
              Shadow(color: Color(0x6630A0FF), blurRadius: 8),
            ],
          )
        : TextStyle(
            fontFamily: monospace ? 'monospace' : null,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isMatrix ? green : scheme.onSurface,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMatrix
            ? Colors.transparent
            : isLain
            ? const Color(0xFF08080F)
            : style.panelColor ?? scheme.surfaceContainerHigh,
        borderRadius: isMatrix
            ? BorderRadius.circular(12)
            : isLain
            ? BorderRadius.zero
            : BorderRadius.circular(14),
        border: isMatrix
            ? Border.all(color: green.withValues(alpha: 0.55), width: 1.2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isMatrix
                ? green
                : isLain
                ? cyan
                : scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: isMatrix
                      ? TextStyle(
                          fontSize: 11,
                          color: green.withValues(alpha: 0.75),
                        )
                      : isLain
                      ? TextStyle(fontSize: 10, color: cyan)
                      : TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: detailsStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            color: isMatrix
                ? green.withValues(alpha: 0.8)
                : isLain
                ? cyan
                : null,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              AppToast.show(context, '$label copied');
            },
          ),
        ],
      ),
    );
  }
}