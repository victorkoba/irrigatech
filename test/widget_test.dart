import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:irrigatech/app.dart';
import 'package:irrigatech/services/irrigation_service.dart';

void main() {
  testWidgets('App smoke test - verifies IrrigaTech starts with Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => IrrigationService()),
        ],
        child: const IrrigaTechApp(),
      ),
    );

    // Verify app starts and displays the IrrigaTech title
    expect(find.text('IrrigaTech'), findsWidgets);
    expect(find.text('STATUS GERAL'), findsOneWidget);
  });
}
