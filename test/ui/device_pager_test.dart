import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/ui/home/device_pager.dart';

Future<List<int>> _pumpPager(WidgetTester tester, List<double> pageHeights) async {
  final settled = <int>[];
  await tester.pumpWidget(MaterialApp(
    theme: ClaroTheme.dark,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            DevicePager<int>(
              items: [for (var i = 0; i < pageHeights.length; i++) i],
              onPageSettled: settled.add,
              pageBuilder: (i) => Container(
                key: ValueKey('page-$i'),
                height: pageHeights[i],
                color: const Color(0xFF333333),
                alignment: Alignment.bottomCenter,
                child: Text('Bottom of page $i'),
              ),
            ),
            const SizedBox(height: 2000, child: Text('Below the pager')),
          ],
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return settled;
}

void main() {
  testWidgets('reports page 0 when first shown, and 1 after a swipe', (tester) async {
    final settled = await _pumpPager(tester, [300, 300]);
    expect(settled, [0]);

    await tester.fling(find.byKey(const ValueKey('page-0')), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(settled, [0, 1]);
    expect(find.text('Bottom of page 1'), findsOneWidget);
  });

  testWidgets('dots show for two items, the active one following the page', (tester) async {
    await _pumpPager(tester, [300, 300]);
    expect(tester.getSize(find.byKey(const ValueKey('pager-dot-0'))), const Size(8, 8));
    expect(tester.getSize(find.byKey(const ValueKey('pager-dot-1'))), const Size(6, 6));

    await tester.fling(find.byKey(const ValueKey('page-0')), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('pager-dot-0'))), const Size(6, 6));
    expect(tester.getSize(find.byKey(const ValueKey('pager-dot-1'))), const Size(8, 8));
  });

  testWidgets('no dots for a single item', (tester) async {
    await _pumpPager(tester, [300]);
    expect(find.byKey(const ValueKey('pager-dot-0')), findsNothing);
  });

  testWidgets('the pager is as tall as the current page, never clipping it', (tester) async {
    await _pumpPager(tester, [450, 200]);
    expect(tester.getSize(find.byType(PageView)).height, 450);
    expect(tester.getSize(find.byKey(const ValueKey('page-0'))).height, 450);

    // The next page is shorter: the pager shrinks to it once swiped to.
    await tester.fling(find.byKey(const ValueKey('page-0')), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 200);
  });

  testWidgets('a vertical drag on the pager scrolls the page around it', (tester) async {
    await _pumpPager(tester, [300, 300]);
    final before = tester.getTopLeft(find.byKey(const ValueKey('page-0'))).dy;

    await tester.drag(find.byKey(const ValueKey('page-0')), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('page-0'))).dy, lessThan(before));
  });
}
