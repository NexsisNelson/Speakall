import 'package:flutter_test/flutter_test.dart';
import 'package:speakall/main.dart';

void main() {
  testWidgets('onboarding opens the language practice screen', (tester) async {
    await tester.pumpWidget(const SpeakApp());

    expect(find.text('Speak with\nconfidence and\nfluency'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Let's Speak English"), findsOneWidget);
    expect(find.text('Your personal AI language partner'), findsOneWidget);
  });
}
