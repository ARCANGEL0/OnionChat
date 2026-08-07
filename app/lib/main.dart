import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/sticker_service.dart';
import 'state/chat_theme.dart';
import 'state/room_controller.dart';
import 'state/theme_controller.dart';
import 'themes/theme_style.dart';
import 'widgets/app_toast.dart';
import 'widgets/tap_click_sound.dart';
import 'widgets/theme_fx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  // Initialize sticker service and auto-import WhatsApp stickers
  await StickerService.instance.init();
  StickerService.instance.maybeAutoImportWhatsApp();
  runApp(const OnionChatApp());
  // Notifications are non-essential: never let a plugin failure block startup.
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('notification init failed: $e');
  }
  // Android 13+ runtime permission prompt (non-blocking).
  try {
    await NotificationService.instance.ensurePermission();
  } catch (e) {
    debugPrint('notification permission prompt failed: $e');
  }
}

class OnionChatApp extends StatefulWidget {
  const OnionChatApp({super.key});

  @override
  State<OnionChatApp> createState() => _OnionChatAppState();
}

class _OnionChatAppState extends State<OnionChatApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppToast.attach(_navKey.currentState?.overlay);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track foreground so notifications still fire while the app is minimized.
    RoomController.appInForeground =
        state == AppLifecycleState.resumed;
  }

  ThemeData _theme(Color seed, Brightness brightness) {
    final s = ThemeController.instance.settings;
    final dark = brightness == Brightness.dark;

    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    if (s.mainText != null) {
      scheme = scheme.copyWith(onSurface: Color(s.mainText!));
    }
    if (s.secondaryText != null) {
      scheme = scheme.copyWith(onSurfaceVariant: Color(s.secondaryText!));
    }

    final headerColor = s.headerColor != null ? Color(s.headerColor!) : null;
    final headerText = s.headerText != null ? Color(s.headerText!) : null;
    final backgroundColor = s.background != null ? Color(s.background!) : null;
    final myBubble = s.bubbleMine != null ? Color(s.bubbleMine!) : null;
    final theirBubble = s.bubbleTheirs != null ? Color(s.bubbleTheirs!) : null;

    final defaultBg = dark ? const Color(0xFF0D0B1E) : scheme.surface;
    final defaultHeader = dark ? const Color(0xFF17122B) : scheme.surface;

    final mainFont = s.mainFont.trim();
    final fontSizeFactor =
        s.mainFontSize > 0 ? s.mainFontSize / 14.0 : 1.0;
    final style = ThemeStyle.fromId(s.themeStyle);
    final cardShape = style.cardShape.toShapeBorder();
    final lainBorder = const Color(0xFF4A6B6B).withValues(alpha: 0.7);
    final filledButtonStyle = style == ThemeStyle.matrix
        ? FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF00FF41),
            side: const BorderSide(color: Color(0xFF00FF41), width: 1.2),
            shape: style.outlinedButtonShape,
          )
        : style == ThemeStyle.lain
            ? FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16121F),
                foregroundColor: const Color(0xFFB1A8C2),
                side: BorderSide(color: lainBorder, width: 1),
                shape: style.outlinedButtonShape,
              )
            : FilledButton.styleFrom(shape: style.outlinedButtonShape);

    var theme = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: mainFont.isEmpty ? null : mainFont,
      scaffoldBackgroundColor: backgroundColor ?? defaultBg,
      appBarTheme: AppBarTheme(
        backgroundColor: headerColor ?? defaultHeader,
        foregroundColor: headerText ??
            (headerColor != null ? onColor(headerColor) : null),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // Shape the whole app from the active theme template.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: style.outlinedFabShape,
      ),
      cardTheme: CardThemeData(
        shape: cardShape,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: style == ThemeStyle.matrix || style == ThemeStyle.lain
            ? OutlinedButton.styleFrom(
                foregroundColor: style == ThemeStyle.matrix
                    ? const Color(0xFF00FF41)
                    : const Color(0xFFB1A8C2),
                side: BorderSide(
                  color: style == ThemeStyle.matrix
                      ? const Color(0xFF00FF41)
                      : lainBorder,
                  width: 1.2,
                ),
                shape: style.outlinedButtonShape,
              )
            : OutlinedButton.styleFrom(shape: style.outlinedButtonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: style == ThemeStyle.matrix || style == ThemeStyle.lain
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: style == ThemeStyle.matrix
                    ? const Color(0xFF00FF41)
                    : const Color(0xFFB1A8C2),
                elevation: 0,
                side: BorderSide(
                  color: style == ThemeStyle.matrix
                      ? const Color(0xFF00FF41)
                      : lainBorder,
                  width: 1.2,
                ),
                shape: style.outlinedButtonShape,
              )
            : ElevatedButton.styleFrom(shape: style.outlinedButtonShape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: !(style == ThemeStyle.matrix || style == ThemeStyle.lain),
        fillColor:
            style == ThemeStyle.matrix || style == ThemeStyle.lain
                ? Colors.transparent
                : null,
        border: _inputBorder(style, width: 1.2),
        enabledBorder: _inputBorder(style, width: 1.2),
        focusedBorder: _inputBorder(style, width: 1.8),
      ),
      extensions: [
        ChatTheme(
          style: style,
          myBubble: myBubble ?? const Color(0xFF8B5CF6),
          myBubbleText: myBubble != null ? onColor(myBubble) : Colors.white,
          theirBubble: theirBubble ?? const Color(0xFF2A1F4D),
          theirBubbleText:
              theirBubble != null ? onColor(theirBubble) : const Color(0xFFE8DDF4),
          theirName: scheme.tertiary,
        ),
      ],
    );
    if (fontSizeFactor != 1.0) {
      // The raw ThemeData text theme carries only colors — font geometry comes
      // from the localized englishLike theme, so merge it in first (otherwise
      // apply() trips over null font sizes) before scaling.
      final concrete = theme.textTheme.merge(Typography.englishLike2021);
      theme = theme.copyWith(
        textTheme: concrete.apply(fontSizeFactor: fontSizeFactor),
      );
    }
    return theme;
  }

  static OutlineInputBorder? _inputBorder(ThemeStyle style, {double width = 1.2}) {
    final radius = style.inputShape.roundedOrTight;
    if (style == ThemeStyle.matrix) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: const Color(0xFF00FF41), width: width),
      );
    }
    if (style == ThemeStyle.lain) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: const Color(0xFF4A6B6B).withValues(alpha: 0.7),
          width: width,
        ),
      );
    }
    return OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final tc = ThemeController.instance;
        final seed = tc.accentColor;
        return MaterialApp(
          title: 'OnionChat',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navKey,
          theme: _theme(seed, Brightness.light),
          darkTheme: _theme(seed, Brightness.dark),
          themeMode: ThemeMode.dark,
          home: const SplashScreen(),
          // Click sound only on interactive taps (buttons/tiles) — never on
          // scrolling or background taps.
          builder: (context, child) => ThemeFX(
            style: ThemeStyle.fromId(
              ThemeController.instance.settings.themeStyle,
            ),
            child: TapClickSound(child: child!),
          ),
          routes: {
            '/home': (_) => const HomeScreen(),
          },
        );
      },
    );
  }
}
