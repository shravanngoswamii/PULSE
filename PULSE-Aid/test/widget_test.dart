import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_aid/src/pulse_aid_app.dart';

void main() {
  testWidgets('shows connect screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PulseAidApp());

    expect(find.text('PULSE Aid'), findsOneWidget);
    expect(find.text('Connect to Ambulance Stream'), findsOneWidget);
  });
}
