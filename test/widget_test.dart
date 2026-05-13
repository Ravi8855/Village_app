import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:naganoor_village_app/app.dart';

void main() {
  testWidgets('NaganoorApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NaganoorApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NaganoorApp), findsOneWidget);
  });
}
