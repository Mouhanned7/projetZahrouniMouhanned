import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildWebIframeViewer(String url) {
  final viewId =
      'iframe-${url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) => web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
      ..referrerPolicy = 'strict-origin-when-cross-origin'
      ..allowFullscreen = true,
  );

  return HtmlElementView(viewType: viewId);
}
