// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class WebIframeViewer extends StatefulWidget {
  final String url;

  const WebIframeViewer({super.key, required this.url});

  @override
  State<WebIframeViewer> createState() => _WebIframeViewerState();
}

class _WebIframeViewerState extends State<WebIframeViewer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'iframe-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => html.IFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text(
          'Aperçu non disponible (Web uniquement)',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }

    return HtmlElementView(viewType: _viewId);
  }
}
