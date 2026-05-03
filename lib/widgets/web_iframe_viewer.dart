import 'package:flutter/material.dart';

import 'web_iframe_viewer_stub.dart'
    if (dart.library.js_interop) 'web_iframe_viewer_web.dart';

class WebIframeViewer extends StatelessWidget {
  final String url;

  const WebIframeViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) => buildWebIframeViewer(url);
}
