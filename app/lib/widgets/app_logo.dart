import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../services/app_assets.dart';
import '../state/theme_controller.dart';
import '../themes/theme_style.dart';

class AppLogo extends StatefulWidget {
  final double size;

  const AppLogo({super.key, this.size = 26});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  static const int _tintSize = 256;
  static Future<ui.Image>? _source;
  static final Map<int, Future<ui.Image>> _cache = {};

  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    final settings = tc.settings;
    final isLain =
        ThemeStyle.fromId(settings.themeStyle) == ThemeStyle.lain;
    final image = Image.asset(
      isLain ? AppAssets.wiredLogo : AppAssets.icon,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
    if (!isLain) {
      final logoColor = settings.logoColor;
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color(logoColor ?? AppSettings.defaultLogoColor),
          BlendMode.color,
        ),
        child: image,
      );
    }
    final logoColor = settings.logoColor;
    if (logoColor == null) return image;
    return FutureBuilder<ui.Image>(
      future: _tinted(logoColor),
      builder: (context, snapshot) {
        final tinted = snapshot.data;
        if (tinted == null) return image;
        return RawImage(
          image: tinted,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}

Future<ui.Image> _tinted(int argb) {
  return _AppLogoState._cache.putIfAbsent(argb, () async {
    final source = await _loadSource();
    final pixels = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pixels == null) throw StateError('Failed to read logo pixels');
    final bytes = pixels.buffer.asUint8List();
    final out = await compute(
      _recolor,
      _TintRequest(bytes, source.width, source.height, argb),
    );
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      out,
      source.width,
      source.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  });
}

Future<ui.Image> _loadSource() {
  return _AppLogoState._source ??= () async {
    final data = await rootBundle.load(AppAssets.wiredLogo);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _AppLogoState._tintSize,
      targetHeight: _AppLogoState._tintSize,
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }();
}

class _TintRequest {
  final Uint8List bytes;
  final int width;
  final int height;
  final int argb;

  const _TintRequest(this.bytes, this.width, this.height, this.argb);
}

Uint8List _recolor(_TintRequest request) {
  final bytes = request.bytes;
  final tr = (request.argb >> 16) & 0xff;
  final tg = (request.argb >> 8) & 0xff;
  final tb = request.argb & 0xff;

  int sum = 0;
  int count = 0;
  for (var i = 0; i < bytes.length; i += 4) {
    final a = bytes[i + 3];
    if (a == 0) continue;
    sum += _luma(bytes[i], bytes[i + 1], bytes[i + 2]);
    count++;
  }
  final mean = count == 0 ? 1 : sum / count;

  final out = Uint8List(bytes.length);
  for (var i = 0; i < bytes.length; i += 4) {
    final a = bytes[i + 3];
    out[i + 3] = a;
    if (a == 0) continue;
    final luma = _luma(bytes[i], bytes[i + 1], bytes[i + 2]);
    var f = luma / mean;
    if (f > 1) f = 1;
    if (f < 0) f = 0;
    out[i] = (tr * f).round();
    out[i + 1] = (tg * f).round();
    out[i + 2] = (tb * f).round();
  }
  return out;
}

int _luma(int r, int g, int b) {
  return r * 299 ~/ 1000 + g * 587 ~/ 1000 + b * 114 ~/ 1000;
}