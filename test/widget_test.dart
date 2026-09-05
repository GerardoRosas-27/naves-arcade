import 'package:flutter_test/flutter_test.dart';
import 'package:naves_arcade/main.dart';

void main() {
  testWidgets('Welcome screen shows title and play button', (tester) async {
    await tester.pumpWidget(const NavesArcadeApp());
    await tester.pump();

    expect(find.textContaining('NAVES'), findsOneWidget);
    expect(find.textContaining('JUGAR'), findsOneWidget);
  });
}
