import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/app_settings.dart';
import '../services/wallpaper_lib.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';
import '../themes/theme_template.dart';
import '../themes/theme_templates.dart';
import '../widgets/app_toast.dart';
import '../widgets/lain_window.dart';
import '../widgets/themed_dialog.dart';
import 'wallpaper_picker_screen.dart';

/// Full appearance editor: import/export theme JSON, a color field for every
/// UI element, dark/light mode, wallpaper and reset.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  static const _palette = <Color>[
    Color(0xFF7C3FED), // tor purple
    Color(0xFF5B2DD3), // deep violet
    Color(0xFF2E3BDB), // royal blue
    Color(0xFF1B2A8F), // deep indigo
    Color(0xFF0D47A1), // deep blue
    Color(0xFF4A148C), // royal purple
    Color(0xFF8E24AA), // magenta violet
    Color(0xFF1565C0), // vivid blue
    Color(0xFF0097A7), // teal
    Color(0xFF00897B), // green-teal
    Color(0xFFE91E63), // pink
    Color(0xFFD81B60), // raspberry
  ];

  static const _colorGroups = <(String, List<_ColorFieldSpec>)>[
    (
      'General',
      [
        _ColorFieldSpec(
          'Buttons',
          'Primary buttons, toggles and highlights',
          ColorSetting.buttons,
        ),
        _ColorFieldSpec(
          'Header',
          'Top bars in every screen',
          ColorSetting.header,
        ),
        _ColorFieldSpec(
          'Header text',
          'Text on the top bars',
          ColorSetting.headerText,
        ),
        _ColorFieldSpec(
          'Background',
          'Main page background color',
          ColorSetting.background,
        ),
        _ColorFieldSpec(
          'Main page text',
          'Text on the main pages',
          ColorSetting.mainText,
        ),
        _ColorFieldSpec(
          'Secondary text',
          'Muted text, hints and labels',
          ColorSetting.secondaryText,
        ),
        _ColorFieldSpec(
          'Boot screen',
          'Background while the app starts',
          ColorSetting.splashBackground,
        ),
        _ColorFieldSpec(
          'Logo',
          'Tint applied over the app logo',
          ColorSetting.logo,
        ),
        _ColorFieldSpec(
          'Menu background',
          'The ⋮ popup menu background',
          ColorSetting.menuSettingsBackground,
        ),
        _ColorFieldSpec(
          'Menu text',
          'Text on the ⋮ popup menu',
          ColorSetting.menuSettingsText,
        ),
      ],
    ),
    (
      'Chat',
      [
        _ColorFieldSpec(
          'Chat header',
          'Top bar on the chat screen',
          ColorSetting.chatHeader,
        ),
        _ColorFieldSpec(
          'Chat header text',
          'Text on the chat top bar',
          ColorSetting.chatHeaderText,
        ),
        _ColorFieldSpec(
          'Chat background',
          'Chat screen behind messages',
          ColorSetting.chatBackground,
        ),
        _ColorFieldSpec(
          'Chat text',
          'Message text color in a chat',
          ColorSetting.chatText,
        ),
        _ColorFieldSpec(
          'My bubble',
          'Your messages in a chat',
          ColorSetting.bubbleMine,
        ),
        _ColorFieldSpec(
          'Their bubble',
          'Received messages in a chat',
          ColorSetting.bubbleTheirs,
        ),
        _ColorFieldSpec(
          'Notification bubble',
          'System tips (e.g. "has connected")',
          ColorSetting.noticeColor,
        ),
        _ColorFieldSpec(
          'Notification bubble text',
          'Text on the system tips',
          ColorSetting.noticeText,
        ),
      ],
    ),
    (
      'Member list',
      [
        _ColorFieldSpec(
          'Members text',
          'Member list names',
          ColorSetting.membersText,
        ),
        _ColorFieldSpec(
          'Members header',
          'Member list title',
          ColorSetting.membersHeader,
        ),
        _ColorFieldSpec(
          'Members background',
          'Member list panel',
          ColorSetting.membersBackground,
        ),
        _ColorFieldSpec(
          'Members icon',
          'Member list icons',
          ColorSetting.membersIcon,
        ),
        _ColorFieldSpec(
          'Online',
          'Members currently in the room',
          ColorSetting.onlineText,
        ),
        _ColorFieldSpec(
          'Offline',
          'Known members not connected',
          ColorSetting.offlineText,
        ),
      ],
    ),
(
      'Text colors',
      [
        _ColorFieldSpec(
          'Main header text',
          'App bar titles',
          ColorSetting.mainHeaderText,
        ),
        _ColorFieldSpec(
          'Main chats text',
          'Room names on home screen',
          ColorSetting.mainChatsText,
        ),
        _ColorFieldSpec(
          'Chat header text',
          'Chat screen top bar text',
          ColorSetting.chatHeaderText,
        ),
        _ColorFieldSpec(
          'Member list text',
          'Member list names',
          ColorSetting.membersText,
        ),
        _ColorFieldSpec(
          'Chat bubbles text',
          'Message text in bubbles',
          ColorSetting.chatBubblesText,
        ),
        _ColorFieldSpec(
          'Settings text',
          'Settings screen text',
          ColorSetting.settingsText,
        ),
        _ColorFieldSpec(
          'Splash text',
          'Boot screen text',
          ColorSetting.splashText,
        ),
      ],
    ),
    (
      'Message area',
      [
        _ColorFieldSpec(
          'Message area button',
          'The send button color',
          ColorSetting.inputButton,
        ),
        _ColorFieldSpec(
          'Message attachment',
          'The attach (image) button color',
          ColorSetting.inputAttach,
        ),
        _ColorFieldSpec(
          'Message area textarea',
          'The text field fill color',
          ColorSetting.inputTextarea,
        ),
        _ColorFieldSpec(
          'Message area background',
          'The footer behind the text field',
          ColorSetting.inputBar,
        ),
      ],
    ),
    (
      'Toasts',
      [
        _ColorFieldSpec(
          'Toast background',
          'Pop-up notices (top-left)',
          ColorSetting.toastBackground,
        ),
        _ColorFieldSpec(
          'Toast text',
          'Text on the pop-up notices',
          ColorSetting.toastText,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListenableBuilder(
        listenable: tc,
        builder: (context, _) {
          final s = tc.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _importTheme(context),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Import'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportTheme(context),
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Export'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Templates'),
              const SizedBox(height: 4),
              Text(
                'Ready-made looks that recolor AND reshape the whole app '
                '(bubbles, input bar, buttons and cards).',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in themeTemplates) ...[
                      _TemplateCard(
                        template: t,
                        selected: ThemeStyle.fromId(s.themeStyle) == t.style,
                        onTap: () => tc.applyTemplate(t),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Colors'),
              const SizedBox(height: 4),
              Text(
                'Tap a field to pick its color. "Use default" restores the '
                'built-in look for that element.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              for (final group in _colorGroups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text(
                    group.$1,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final f in group.$2)
                  _ColorField(
                    label: f.label,
                    description: f.description,
                    color: _currentColor(s, f.setting),
                    inactive: _isBubbleInactive(
                      s.themeStyle,
                      f.setting,
                    ),
                    onTap: () => _editColor(context, f.setting),
                  ),
              ],
              const SizedBox(height: 24),
              const _SectionTitle('Cards'),
              const SizedBox(height: 4),
              Text(
                'Each card\'s background (color or image), font color, size '
                'and style.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              _cardBlock(
                context,
                title: 'Kick card',
                background: const [
                  (
                    'Background',
                    'Color or image on the kick card',
                    ColorSetting.kickBackground,
                  ),
                  (
                    'Border',
                    'The card outline',
                    ColorSetting.kickBorder,
                  ),
                ],
                fontColor: (
                  'Font color',
                  '"Kick <name>?" heading and text',
                  ColorSetting.kickTitle,
                ),
                extraColors: const [
                  (
                    'Body text',
                    'The explanation text',
                    ColorSetting.kickBody,
                  ),
                  ('Icon', 'The warning icon', ColorSetting.kickIcon),
                  (
                    'Button',
                    'The Kick action button',
                    ColorSetting.kickButton,
                  ),
                  (
                    'Button text',
                    'Label on the Kick button',
                    ColorSetting.kickButtonText,
                  ),
                  (
                    'Cancel',
                    'Cancel label on the card',
                    ColorSetting.kickCancel,
                  ),
                ],
                font: s.kickFont,
                fontSize: s.kickFontSize,
                onFontChanged: tc.setKickFont,
                onFontSizeChanged: tc.setKickFontSize,
                sizeMin: 12,
                sizeMax: 20,
              ),
              const SizedBox(height: 8),
              _cardBlock(
                context,
                title: 'Disconnected card',
                background: const [
                  (
                    'Color',
                    'Background of the "Disconnected" notice',
                    ColorSetting.disconnectedBackground,
                  ),
                ],
                fontColor: (
                  'Font color',
                  'Text on the Disconnected notice',
                  ColorSetting.disconnectedText,
                ),
                font: s.disconnectedFont,
                fontSize: s.disconnectedFontSize,
                onFontChanged: tc.setDisconnectedFont,
                onFontSizeChanged: tc.setDisconnectedFontSize,
                sizeMin: 12,
                sizeMax: 20,
              ),
              const SizedBox(height: 8),
              _cardBlock(
                context,
                title: 'Profile card',
                background: const [
                  (
                    'Color',
                    'Color or image on the profile card',
                    ColorSetting.profileBackground,
                  ),
                ],
                fontColor: (
                  'Font color',
                  'Username on the profile card',
                  ColorSetting.profileText,
                ),
                extraColors: const [
                  (
                    'Muted text',
                    'Bio and joined time',
                    ColorSetting.profileSecondaryText,
                  ),
                  (
                    'Accent',
                    'Avatar ring and profile icons',
                    ColorSetting.profileAccent,
                  ),
                ],
                font: s.profileFont,
                fontSize: s.profileFontSize,
                onFontChanged: tc.setProfileFont,
                onFontSizeChanged: tc.setProfileFontSize,
                sizeMin: 12,
                sizeMax: 24,
              ),
              const SizedBox(height: 8),
              _cardBlock(
                context,
                title: 'Progress cards (Connecting / Creating)',
                background: const [
                  (
                    'Color',
                    'Background of the connecting / creating cards',
                    ColorSetting.card,
                  ),
                ],
                fontColor: (
                  'Font color',
                  'Text on the connecting / creating cards',
                  ColorSetting.cardText,
                ),
                font: s.cardFont,
                fontSize: s.cardFontSize,
                onFontChanged: tc.setCardFont,
                onFontSizeChanged: tc.setCardFontSize,
                sizeMin: 12,
                sizeMax: 22,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, tc),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset to defaults'),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Fonts'),
              const SizedBox(height: 4),
              Text(
                'Pick a device font and size for the main pages and for chat '
                'messages.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Main font',
                subtitle: 'Every screen',
                current: s.mainFont,
                onChanged: tc.setMainFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Main text size',
                value: s.mainFontSize,
                min: 12,
                max: 18,
                onChanged: tc.setMainFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Chat font',
                subtitle: 'Messages and the input field',
                current: s.chatFont,
                onChanged: tc.setChatFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Chat text size',
                value: s.chatFontSize,
                min: 12,
                max: 20,
                onChanged: tc.setChatFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Main header font',
                subtitle: 'App bar titles',
                current: s.mainHeaderFont,
                onChanged: tc.setMainHeaderFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Main header text size',
                value: s.mainHeaderFontSize,
                min: 12,
                max: 24,
                onChanged: tc.setMainHeaderFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Main chats font',
                subtitle: 'Room names on home screen',
                current: s.mainChatsFont,
                onChanged: tc.setMainChatsFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Main chats text size',
                value: s.mainChatsFontSize,
                min: 10,
                max: 20,
                onChanged: tc.setMainChatsFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Chat header font',
                subtitle: 'Chat screen top bar',
                current: s.chatHeaderFont,
                onChanged: tc.setChatHeaderFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Chat header text size',
                value: s.chatHeaderFontSize,
                min: 12,
                max: 20,
                onChanged: tc.setChatHeaderFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Chat bubbles font',
                subtitle: 'Message text inside bubbles',
                current: s.chatBubblesFont,
                onChanged: tc.setChatBubblesFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Chat bubbles text size',
                value: s.chatBubblesFontSize,
                min: 12,
                max: 20,
                onChanged: tc.setChatBubblesFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Member list font',
                subtitle: 'Names in the member sidebar',
                current: s.memberListFont,
                onChanged: tc.setMemberListFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Member list text size',
                value: s.memberListFontSize,
                min: 10,
                max: 18,
                onChanged: tc.setMemberListFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Settings font',
                subtitle: 'Settings screen text',
                current: s.settingsFont,
                onChanged: tc.setSettingsFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Settings text size',
                value: s.settingsFontSize,
                min: 10,
                max: 18,
                onChanged: tc.setSettingsFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Splash font',
                subtitle: 'Boot screen text',
                current: s.splashFont,
                onChanged: tc.setSplashFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Splash text size',
                value: s.splashFontSize,
                min: 14,
                max: 28,
                onChanged: tc.setSplashFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Notification font',
                subtitle: 'System tips in the chat',
                current: s.noticeFont,
                onChanged: tc.setNoticeFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Notification text size',
                value: s.noticeFontSize,
                min: 10,
                max: 16,
                onChanged: tc.setNoticeFontSize,
              ),
              const SizedBox(height: 12),
              _FontRow(
                label: 'Toast font',
                subtitle: 'Pop-up notices',
                current: s.toastFont,
                onChanged: tc.setToastFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Toast text size',
                value: s.toastFontSize,
                min: 11,
                max: 18,
                onChanged: tc.setToastFontSize,
              ),
              _FontRow(
                label: 'Menu font',
                subtitle: 'The ⋮ popup menu',
                current: s.menuSettingsFont,
                onChanged: tc.setMenuSettingsFont,
              ),
              const SizedBox(height: 4),
              _SizeRow(
                label: 'Menu text size',
                value: s.menuSettingsFontSize,
                min: 11,
                max: 20,
                onChanged: tc.setMenuSettingsFontSize,
              ),
            ],
          );
        },
      ),
    );
  }

  int? _currentColor(AppSettings s, ColorSetting setting) {
    switch (setting) {
      case ColorSetting.buttons:
        return s.accentColor;
      case ColorSetting.header:
        return s.headerColor;
      case ColorSetting.background:
        return s.background;
      case ColorSetting.chatBackground:
        return s.chatBackground;
      case ColorSetting.bubbleMine:
        return s.bubbleMine;
      case ColorSetting.bubbleTheirs:
        return s.bubbleTheirs;
      case ColorSetting.splashBackground:
        return s.splashBackground;
      case ColorSetting.logo:
        return s.logoColor ?? AppSettings.defaultLogoColor;
      case ColorSetting.mainText:
        return s.mainText;
      case ColorSetting.secondaryText:
        return s.secondaryText;
      case ColorSetting.chatHeader:
        return s.chatHeader;
      case ColorSetting.headerText:
        return s.headerText;
      case ColorSetting.chatHeaderText:
        return s.chatHeaderText;
      case ColorSetting.inputBar:
        return s.inputBar;
      case ColorSetting.inputTextarea:
        return s.inputTextarea;
      case ColorSetting.inputButton:
        return s.inputButton;
      case ColorSetting.inputAttach:
        return s.inputAttach;
      case ColorSetting.chatText:
        return s.chatTextColor;
      case ColorSetting.membersText:
        return s.membersText;
      case ColorSetting.membersHeader:
        return s.membersHeader;
      case ColorSetting.membersBackground:
        return s.membersBackground;
      case ColorSetting.membersIcon:
        return s.membersIcon;
      case ColorSetting.mainHeaderText:
        return s.mainHeaderTextColor;
      case ColorSetting.mainChatsText:
        return s.mainChatsTextColor;
      case ColorSetting.chatBubblesText:
        return s.chatBubblesTextColor;
      case ColorSetting.settingsText:
        return s.settingsTextColor;
      case ColorSetting.splashText:
        return s.splashTextColor;
      case ColorSetting.profileBackground:
        return s.profileBackground;
      case ColorSetting.profileText:
        return s.profileText;
      case ColorSetting.profileSecondaryText:
        return s.profileSecondaryText;
      case ColorSetting.profileAccent:
        return s.profileAccent;
      case ColorSetting.onlineText:
        return s.onlineText;
      case ColorSetting.offlineText:
        return s.offlineText;
      case ColorSetting.noticeColor:
        return s.noticeColor;
      case ColorSetting.noticeText:
        return s.noticeText;
      case ColorSetting.toastBackground:
        return s.toastBackground;
      case ColorSetting.toastText:
        return s.toastText;
      case ColorSetting.kickBackground:
        return s.kickBackground;
      case ColorSetting.kickBorder:
        return s.kickBorder;
      case ColorSetting.kickTitle:
        return s.kickTitle;
      case ColorSetting.kickBody:
        return s.kickBody;
      case ColorSetting.kickIcon:
        return s.kickIcon;
      case ColorSetting.kickButton:
        return s.kickButton;
      case ColorSetting.kickButtonText:
        return s.kickButtonText;
      case ColorSetting.kickCancel:
        return s.kickCancel;
      case ColorSetting.card:
        return s.cardColor;
      case ColorSetting.cardText:
        return s.cardText;
      case ColorSetting.disconnectedBackground:
        return s.disconnectedBackground;
      case ColorSetting.disconnectedText:
        return s.disconnectedText;
      case ColorSetting.menuSettingsBackground:
        return s.menuSettingsBackground;
      case ColorSetting.menuSettingsText:
        return s.menuSettingsText;
    }
  }

  /// True when the field is unusable in the current theme template (e.g. the
  /// Matrix and Lain themes draw their messages without side bubbles).
  static bool _isBubbleInactive(String? themeId, ColorSetting setting) {
    if (setting != ColorSetting.bubbleMine &&
        setting != ColorSetting.bubbleTheirs) {
      return false;
    }
    final style = ThemeStyle.fromId(themeId);
    return style == ThemeStyle.matrix || style == ThemeStyle.lain;
  }

  Future<void> _editColor(
    BuildContext context,
    ColorSetting setting, {
    String? label,
  }) async {
    final tc = ThemeController.instance;
    final current = _currentColor(tc.settings, setting);
    final wallpaper = _wallpaperTarget(tc, setting);
    final picked = await showDialog<Object?>(
      context: context,
      builder: (_) => _ColorDialog(
        title: label ??
            _colorGroups
                .expand((g) => g.$2)
                .firstWhere((f) => f.setting == setting)
                .label,
        initial: current != null ? Color(current) : null,
        palette: _palette,
        wallpaper: wallpaper,
      ),
    );
    if (picked == _canceled) return;
    if (picked == _pickedImage) {
      await _pickBackgroundImage(context, wallpaper!);
      return;
    }
    if (picked == null) {
      // "Use default": fall back to the theme's default — clear any custom
      // image AND reset the color.
      if (wallpaper != null) await wallpaper.onChanged(null);
      await tc.setColor(setting, null);
      return;
    }
    await tc.setColor(setting, picked as Color?);
  }

  /// For colors that are also backgrounds (main page, chat, member list,
  /// progress card, menu, kick card, profile card) this returns the metadata
  /// needed to let the user assign an image instead of a plain color.
  _WallpaperTarget? _wallpaperTarget(ThemeController tc, ColorSetting setting) {
    final s = tc.settings;
    switch (setting) {
      case ColorSetting.background:
        return _WallpaperTarget(
          current: s.mainWallpaper,
          pickerTitle: 'Main page background',
          defaultColor: s.background ?? s.accentColor,
          onChanged: tc.setMainWallpaper,
        );
      case ColorSetting.chatBackground:
        return _WallpaperTarget(
          current: s.globalWallpaper,
          pickerTitle: 'Chat background',
          defaultColor: s.chatBackground ?? s.accentColor,
          onChanged: tc.setGlobalWallpaper,
        );
      case ColorSetting.membersBackground:
        return _WallpaperTarget(
          current: s.membersWallpaper,
          pickerTitle: 'Member list background',
          defaultColor: s.membersBackground ?? s.accentColor,
          onChanged: tc.setMembersWallpaper,
        );
      case ColorSetting.card:
        return _WallpaperTarget(
          current: s.cardWallpaper,
          pickerTitle: 'Progress card background',
          defaultColor: s.cardColor ?? s.accentColor,
          onChanged: tc.setCardWallpaper,
        );
      case ColorSetting.menuSettingsBackground:
        return _WallpaperTarget(
          current: s.menuSettingsWallpaper,
          pickerTitle: 'Menu background',
          defaultColor: s.menuSettingsBackground ?? s.accentColor,
          onChanged: tc.setMenuSettingsWallpaper,
        );
      case ColorSetting.kickBackground:
        return _WallpaperTarget(
          current: s.kickWallpaper,
          pickerTitle: 'Kick card background',
          defaultColor: s.kickBackground ?? s.accentColor,
          onChanged: tc.setKickWallpaper,
        );
      case ColorSetting.profileBackground:
        return _WallpaperTarget(
          current: s.profileWallpaper,
          pickerTitle: 'Profile card background',
          defaultColor: s.profileBackground ?? s.accentColor,
          onChanged: tc.setProfileWallpaper,
        );
      case ColorSetting.disconnectedBackground:
        return _WallpaperTarget(
          current: s.disconnectedWallpaper,
          pickerTitle: 'Disconnected card background',
          defaultColor: s.disconnectedBackground ?? s.accentColor,
          onChanged: tc.setDisconnectedWallpaper,
        );
      default:
        return null;
    }
  }

  Future<void> _pickBackgroundImage(
    BuildContext context,
    _WallpaperTarget target,
  ) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WallpaperPickerScreen(
          current: target.current,
          title: target.pickerTitle,
          defaultColor: target.defaultColor,
        ),
      ),
    );
    if (result == null) return; // canceled
    await target.onChanged(
      result == WallpaperPickerScreen.kDefault ? null : result,
    );
  }

  /// Renders one card's settings block: a couple of background color/image
  /// fields, a font color field, and font size + style rows.
  Widget _cardBlock(
    BuildContext context, {
    required String title,
    required List<(String, String, ColorSetting)> background,
    required (String, String, ColorSetting) fontColor,
    List<(String, String, ColorSetting)> extraColors = const [],
    required String font,
    required double fontSize,
    required ValueChanged<String> onFontChanged,
    required ValueChanged<double> onFontSizeChanged,
    required double sizeMin,
    required double sizeMax,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final s = ThemeController.instance.settings;
    final style = ThemeStyle.fromId(s.themeStyle);
    final panel =
        ThemeController.instance.cardColor ??
        style.panelColor ??
        scheme.surfaceContainerHigh;
    return Card(
      elevation: 0,
      color: panel,
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                title,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            for (final c in background)
              _ColorField(
                label: c.$1,
                description: c.$2,
                color: _currentColor(s, c.$3),
                onTap: () => _editColor(context, c.$3, label: c.$1),
              ),
            _ColorField(
              label: fontColor.$1,
              description: fontColor.$2,
              color: _currentColor(s, fontColor.$3),
              onTap: () =>
                  _editColor(context, fontColor.$3, label: fontColor.$1),
            ),
            for (final c in extraColors)
              _ColorField(
                label: c.$1,
                description: c.$2,
                color: _currentColor(s, c.$3),
                onTap: () => _editColor(context, c.$3, label: c.$1),
              ),
            _SizeRow(
              label: 'Font size',
              value: fontSize,
              min: sizeMin,
              max: sizeMax,
              onChanged: onFontSizeChanged,
            ),
            const SizedBox(height: 4),
            _FontRow(
              label: 'Font style',
              subtitle: title,
              current: font,
              onChanged: onFontChanged,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTheme(BuildContext context) async {
    final tc = ThemeController.instance;
    final json = tc.exportThemeJson();
    try {
      // Android system picker (SAF): asks where to save the .json file.
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save theme as…',
        fileName: 'onionchat-theme.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(json),
      );
      if (path == null) return; // canceled
      if (!context.mounted) return;
      AppToast.show(context, 'Theme exported to $path');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Export failed: $e', style: AppToastStyle.error);
    }
  }

  Future<void> _importTheme(BuildContext context) async {
    final tc = ThemeController.instance;
    // Opens the system file chooser directly — pick a .json theme file.
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import theme…',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return; // canceled
    String json;
    try {
      json = await File(path).readAsString();
    } catch (_) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        'Could not read that file',
        style: AppToastStyle.error,
      );
      return;
    }
    if (json.trim().isEmpty) return;
    final error = await tc.importThemeJson(json.trim());
    if (!context.mounted) return;
    AppToast.show(
      context,
      error ?? 'Theme imported ✓',
      style: error == null ? AppToastStyle.info : AppToastStyle.error,
    );
  }

  Future<void> _confirmReset(BuildContext context, ThemeController tc) async {
    final ok = await showThemedConfirm(
      context: context,
      title: 'Reset appearance?',
      message: 'This restores every default color, wallpaper and profile picture.',
      action: 'Reset',
    );
    if (ok == true) await tc.resetAppearance();
  }
}

final _canceled = Object();
/// Sent from the color dialog when the user taps "Pick image".
final _pickedImage = Object();

/// A preview thumbnail for one theme template. Tapping applies the
/// template's colors and shape style.
class _TemplateCard extends StatelessWidget {
  final ThemeTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: _PreviewClipper(template.style),
                  child: Image.asset(
                    template.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: scheme.primary.withValues(alpha: 0.25),
                      child: Icon(Icons.palette_outlined, color: scheme.primary),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _PreviewFramePainter(
                      style: template.style,
                      selected: selected,
                      primary: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 60,
            child: Text(
              template.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewClipper extends CustomClipper<Path> {
  final ThemeStyle style;

  const _PreviewClipper(this.style);

  @override
  Path getClip(Size size) => style.previewPath(Offset.zero & size);

  @override
  bool shouldReclip(_PreviewClipper oldClipper) => oldClipper.style != style;
}

class _PreviewFramePainter extends CustomPainter {
  final ThemeStyle style;
  final bool selected;
  final Color primary;

  const _PreviewFramePainter({
    required this.style,
    required this.selected,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = style.previewPath(rect);
    final neon = switch (style) {
      ThemeStyle.matrix => const Color(0xFF00FF41),
      ThemeStyle.bladerunner => const Color(0xFFFFB347),
      ThemeStyle.lain => const Color(0xFF4A6B6B),
      _ => null,
    };
    if (neon != null) {
      final isLain = style == ThemeStyle.lain;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isLain
              ? (selected ? 1.5 : 0.8)
              : (selected ? 3 : 1.3)
          ..color = neon.withValues(alpha: selected ? (isLain ? 0.8 : 0.95) : 0.5),
      );
      if (selected) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isLain ? 5 : 10
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, isLain ? 3.5 : 7)
            ..color = neon.withValues(alpha: isLain ? 0.18 : 0.45),
        );
      }
    } else if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = primary,
      );
    }
    final tears = switch (style) {
      ThemeStyle.bladerunner => 2,
      ThemeStyle.lain => 4,
      _ => 0,
    };
    if (tears > 0) {
      canvas.save();
      canvas.clipPath(path);
      final paint = Paint()
        ..color = (style.glowColor ?? primary)
            .withValues(alpha: style == ThemeStyle.lain ? 0.07 : 0.16);
      for (var i = 0; i < tears; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            i.isEven ? -size.width * 0.08 : size.width * 0.06,
            size.height * (0.2 + 0.18 * i),
            size.width,
            i.isEven ? 4 : 3,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PreviewFramePainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.selected != selected ||
      oldDelegate.primary != primary;
}

class _ColorFieldSpec {
  final String label;
  final String description;
  final ColorSetting setting;

  const _ColorFieldSpec(this.label, this.description, this.setting);
}

/// Metadata used by the color dialog so a background color field can also
/// assign an image (built-in wallpaper or an uploaded photo) instead.
class _WallpaperTarget {
  final String? current;
  final String pickerTitle;
  final int? defaultColor;
  final Future<void> Function(String?) onChanged;

  const _WallpaperTarget({
    required this.current,
    required this.pickerTitle,
    required this.defaultColor,
    required this.onChanged,
  });
}

class _ColorDialog extends StatefulWidget {
  final String title;
  final Color? initial;
  final List<Color> palette;
  final _WallpaperTarget? wallpaper;

  const _ColorDialog({
    required this.title,
    required this.initial,
    required this.palette,
    this.wallpaper,
  });

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  Color? _color;

  @override
  void initState() {
    super.initState();
    _color = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    final s = tc.settings;
    final isLain = ThemeStyle.fromId(s.themeStyle) == ThemeStyle.lain;
    final cardFont = s.cardFont.trim().isEmpty ? null : s.cardFont;
    final cardSize = s.cardFontSize;
    final cardTextColor = tc.cardText ?? Theme.of(context).colorScheme.onSurface;
    final cardSubColor =
        (tc.cardText ?? Theme.of(context).colorScheme.onSurfaceVariant)
            .withValues(alpha: 0.8);

    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in widget.palette)
                _Swatch(
                  color: c,
                  selected: _color?.toARGB32() == c.toARGB32(),
                  onTap: () => setState(() => _color = c),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ColorPicker(
            pickerColor: _color ?? Theme.of(context).colorScheme.primary,
            onColorChanged: (c) => setState(() => _color = c),
            enableAlpha: false,
            labelTextStyle: TextStyle(
              color: cardSubColor,
              fontSize: cardSize * 0.85,
              fontFamily: cardFont,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: _color, size: 26),
              const SizedBox(width: 8),
              Text(
                _color != null
                    ? '#${(_color!.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'
                    : 'Theme default',
                style: TextStyle(
                  color: cardTextColor,
                  fontFamily: cardFont,
                  fontSize: cardSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: isLain
          ? _LainWindow(
              title: widget.title,
              font: cardFont,
              child: content,
              actions: _actions(context, lain: true),
            )
          : _CardColorWindow(
              background: s.cardWallpaper,
              bgColor: tc.cardColor,
              textColor: cardTextColor,
              subColor: cardSubColor,
              font: cardFont,
              size: cardSize,
              title: widget.title,
              child: content,
              actions: _actions(context, lain: false),
            ),
    );
  }

  List<Widget> _actions(BuildContext context, {required bool lain}) {
    final tc = ThemeController.instance;
    final cyan = tc.cardColor ?? const Color(0xFF4A6B6B);
    final accent = cyan;
    final font = tc.settings.cardFont.trim().isEmpty
        ? null
        : tc.settings.cardFont;

    Widget action({
      required VoidCallback onPressed,
      required String label,
      bool bold = false,
      bool filled = false,
    }) {
      if (!lain) {
        return filled
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : TextButton(onPressed: onPressed, child: Text(label));
      }
      final onAccent = onColor(filled ? accent : cyan);
      return InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: filled ? accent : null,
            border: Border.all(color: cyan),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled ? onAccent : cyan,
              fontFamily: font,
              fontWeight: bold ? FontWeight.w700 : null,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return [
      action(
        onPressed: () => Navigator.pop(context, _canceled),
        label: 'Cancel',
      ),
      if (widget.wallpaper != null)
        action(
          onPressed: () => Navigator.pop(context, _pickedImage),
          label: 'Pick image',
        ),
      action(
        onPressed: () => Navigator.pop(context, null),
        label: 'Use default',
      ),
      action(
        onPressed: () => Navigator.pop(context, _color ?? _canceled),
        label: 'Use',
        bold: true,
        filled: true,
      ),
    ];
  }
}

/// The color picker rendered as a Lain "system window" (chrome bar + dark
/// body), mirroring the progress-card windows.
class _LainWindow extends StatelessWidget {
  final String title;
  final String? font;
  final Widget child;
  final List<Widget> actions;

  const _LainWindow({
    required this.title,
    required this.font,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: LainWindow(
        title: title,
        font: font,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions) ...[
                    action,
                    if (action != actions.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The color picker dialog styled like a "general card": card color or
/// wallpaper background, card text color, font and size.
class _CardColorWindow extends StatelessWidget {
  final String? background;
  final Color? bgColor;
  final Color textColor;
  final Color subColor;
  final String? font;
  final double size;
  final String title;
  final Widget child;
  final List<Widget> actions;

  const _CardColorWindow({
    required this.title,
    required this.background,
    required this.bgColor,
    required this.textColor,
    required this.subColor,
    required this.font,
    required this.size,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    final bg =
        bgColor ??
        ThemeController.instance.cardColor ??
        style.panelColor ??
        scheme.surfaceContainerHigh;
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 400,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (background != null)
                Wallpaper(background!).background(context)
              else
                ColoredBox(color: bg),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: size + 2,
                            fontFamily: font,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DefaultTextStyle(
                          style: TextStyle(
                            color: textColor,
                            fontFamily: font,
                            fontSize: size,
                          ),
                          child: child,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ],
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
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  final String label;
  final String description;
  final int? color;
  final VoidCallback onTap;
  final bool inactive;

  const _ColorField({
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
    this.inactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      enabled: !inactive,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color != null ? Color(color!) : Colors.transparent,
          border: Border.all(
            color: inactive ? scheme.outlineVariant : scheme.outline,
            width: 2,
          ),
        ),
        child: color == null
            ? Icon(
                Icons.auto_awesome,
                size: 16,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        inactive ? 'Inactive in current theme' : description,
        style: TextStyle(
          fontSize: 12,
          color: inactive ? scheme.outline : null,
          fontStyle: inactive ? FontStyle.italic : null,
        ),
      ),
      trailing: Icon(
        inactive ? Icons.block : Icons.chevron_right,
        color: inactive ? scheme.outline : null,
      ),
      onTap: inactive ? null : onTap,
    );
  }
}

/// A "color or image" row for one background (main page, chat, member list).
/// Opens [WallpaperPickerScreen]; picking the Default tile clears the image so
/// the area falls back to its color field.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

const _fontOptions = <(String, String)>[
  ('Default (Roboto)', ''),
  ('sans-serif', 'sans-serif'),
  ('serif', 'serif'),
  ('monospace', 'monospace'),
  ('sans-serif-condensed', 'sans-serif-condensed'),
  ('sans-serif-medium', 'sans-serif-medium'),
  ('Orbitron', 'Orbitron'),
  ('Comfortaa', 'Comfortaa'),
  ('Share Tech Mono', 'ShareTechMono'),
  ('VT323', 'VT323'),
  ('Michroma', 'Michroma'),
];

class _FontRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final String current;
  final ValueChanged<String> onChanged;

  const _FontRow({
    required this.label,
    required this.subtitle,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ThemeStyle.fromId(ThemeController.instance.settings.themeStyle);
    final panel =
        ThemeController.instance.cardColor ??
        style.panelColor ??
        scheme.surfaceContainerHigh;
    return Card(
      elevation: 0,
      color: panel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.font_download_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: current,
              underline: const SizedBox.shrink(),
              items: [
                for (final f in _fontOptions)
                  DropdownMenuItem(value: f.$2, child: Text(f.$1)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SizeRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: ((max - min) * 2).round(),
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
