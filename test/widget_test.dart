import 'package:flutter_test/flutter_test.dart';

import 'package:socket_base/main.dart';

void main() {
  testWidgets('shows socket asset overview', (WidgetTester tester) async {
    await tester.pumpWidget(const SocketBaseApp());

    expect(find.text('Reusable Socket Base'), findsOneWidget);
    expect(find.text('Reusable Flutter Socket.IO asset'), findsOneWidget);
    expect(find.text('Main features'), findsOneWidget);
  });
}
