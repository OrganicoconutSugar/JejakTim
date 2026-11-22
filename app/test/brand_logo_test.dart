import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jejaktim/core/design.dart';

void main() {
  testWidgets('BrandLogo uses the selected shared vector and exposes a label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandLogo(size: 96))),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(
      find.bySemanticsLabel('Logo JejakTim Titik Bertemu'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
