import 'package:flutter_test/flutter_test.dart';
import 'package:hearassist_data_collector/app/app.dart';

void main() {
  testWidgets('HearAssistApp smoke test and category rendering',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HearAssistApp());
    await tester.pump();

    // Verify AppBar title
    expect(find.text('HearAssist Data Collector'), findsOneWidget);

    // Verify category titles on dashboard
    expect(find.text('Clapping'), findsOneWidget);
    expect(find.text('Doorbell'), findsOneWidget);
    expect(find.text('Door Knock'), findsOneWidget);
    expect(find.text('Baby Cry'), findsOneWidget);
    expect(find.text('Microwave Oven'), findsOneWidget);
    expect(find.text('Background Noise'), findsOneWidget);
  });
}
