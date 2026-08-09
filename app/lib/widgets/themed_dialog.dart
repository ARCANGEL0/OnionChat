import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import 'lain_window.dart';
import 'shape_box.dart';

Color _panelColor(BuildContext context, ThemeStyle style) {
  final tc = ThemeController.instance;
  return tc.cardColor ??
      style.panelColor ??
      Theme.of(context).colorScheme.surfaceContainerHigh;
}

Color _accent(BuildContext context) =>
    ThemeController.instance.accentColor;

String? _menuFont(BuildContext context) {
  final f = ThemeController.instance.settings.kickFont.trim();
  return f.isEmpty ? null : f;
}

Widget _shell({
  required BuildContext context,
  required ThemeStyle style,
  required Widget content,
  double width = 380,
}) {
  if (style == ThemeStyle.lain) {
    return SizedBox(width: width, child: content);
  }
  final scheme = Theme.of(context).colorScheme;
  return SizedBox(
    width: width,
    child: ShapeBox(
      shape: style.cardShape,
      color: _panelColor(context, style),
      borderColor: style.edgeColor ?? scheme.onSurface.withValues(alpha: 0.3),
      borderWidth: style.borderWidth > 0 ? style.borderWidth : 1.5,
      glowColor: style.glowColor,
      glowBlur: style.glowBlur,
      shadow: const BoxShadow(
        color: Colors.black54,
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
      child: content,
    ),
  );
}

Widget _lainBody({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final font = _menuFont(context);
  return LainWindow(
    title: title,
    font: font,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: child,
    ),
  );
}

Widget _lainPromptRow(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '> ',
        style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF00FF9C)),
      ),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            color: Color(0xFFE7F7FF),
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    ],
  );
}

Widget _actionBar({
  required BuildContext context,
  required String cancelLabel,
  required String confirmLabel,
  required VoidCallback onCancel,
  required VoidCallback onConfirm,
}) {
  final style = ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
  final font = _menuFont(context);
  if (style == ThemeStyle.lain) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00B3B3),
            textStyle: TextStyle(fontFamily: font),
          ),
          onPressed: onCancel,
          child: Text(cancelLabel),
        ),
        const SizedBox(width: 6),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _accent(context),
            foregroundColor: onColor(_accent(context)),
            textStyle: TextStyle(fontFamily: font),
          ),
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
  return Row(
    children: [
      Expanded(
        child: TextButton(onPressed: onCancel, child: Text(cancelLabel)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _accent(context),
            foregroundColor: onColor(_accent(context)),
          ),
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ),
    ],
  );
}

Future<bool?> showThemedConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String action = 'OK',
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (bctx, _, _) => Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: const ColoredBox(color: Colors.black45),
        ),
        Center(
          child: Builder(
            builder: (ctx) {
              final style =
                  ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
              final scheme = Theme.of(ctx).colorScheme;
              final font = _menuFont(ctx);
              final size = ThemeController.instance.settings.kickFontSize;
              final content = style == ThemeStyle.lain
                  ? _lainBody(
                      context: ctx,
                      title: 'CONFIRM',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _lainPromptRow(title),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Color(0xFFB1A8C2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _actionBar(
                            context: ctx,
                            cancelLabel: 'Cancel',
                            confirmLabel: action,
                            onCancel: () => Navigator.of(ctx).pop(false),
                            onConfirm: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 40, color: _accent(ctx)),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(ctx)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  fontFamily: font,
                                  fontSize: size,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontFamily: font,
                                  fontSize: size * 0.92,
                                ),
                          ),
                          const SizedBox(height: 18),
                          _actionBar(
                            context: ctx,
                            cancelLabel: 'Cancel',
                            confirmLabel: action,
                            onCancel: () => Navigator.of(ctx).pop(false),
                            onConfirm: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    );
              return _shell(context: ctx, style: style, content: content);
            },
          ),
        ),
      ],
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
  );
}

Future<String?> showThemedTextInput({
  required BuildContext context,
  required String title,
  required TextEditingController controller,
  required String label,
  String? hint,
  IconData icon = Icons.lock,
  String action = 'Save',
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (bctx, _, _) => Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: const ColoredBox(color: Colors.black45),
        ),
        Center(
          child: Builder(
            builder: (ctx) {
              final style =
                  ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
              final scheme = Theme.of(ctx).colorScheme;
              final font = _menuFont(ctx);
              final content = style == ThemeStyle.lain
                  ? _lainBody(
                      context: ctx,
                      title: title,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _lainPromptRow(title),
                          const SizedBox(height: 12),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            style: TextStyle(
                              fontFamily: font,
                              color: const Color(0xFFE7F7FF),
                            ),
                            decoration: InputDecoration(
                              labelText: label,
                              hintText: hint,
                              prefixIcon: Icon(icon, color: const Color(0xFF00B3B3)),
                              border: inputFieldBorder(ThemeStyle.lain, 2),
                              enabledBorder: inputFieldBorder(ThemeStyle.lain, 2),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _actionBar(
                            context: ctx,
                            cancelLabel: 'Cancel',
                            confirmLabel: action,
                            onCancel: () => Navigator.of(ctx).pop(),
                            onConfirm: () =>
                                Navigator.of(ctx).pop(controller.text.trim()),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 40, color: _accent(ctx)),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: label,
                              hintText: hint,
                              prefixIcon: Icon(icon),
                              border: inputFieldBorder(style, 14),
                              enabledBorder: inputFieldBorder(style, 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _actionBar(
                            context: ctx,
                            cancelLabel: 'Cancel',
                            confirmLabel: action,
                            onCancel: () => Navigator.of(ctx).pop(),
                            onConfirm: () =>
                                Navigator.of(ctx).pop(controller.text.trim()),
                          ),
                        ],
                      ),
                    );
              return _shell(context: ctx, style: style, content: content);
            },
          ),
        ),
      ],
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
  );
}
