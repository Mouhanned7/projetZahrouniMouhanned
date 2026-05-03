import 'package:app_z_m/widgets/web_iframe_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web iframe viewer shows a VM-safe fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WebIframeViewer(url: 'https://example.com'),
        ),
      ),
    );

    expect(find.textContaining('Web uniquement'), findsOneWidget);
  });
}
