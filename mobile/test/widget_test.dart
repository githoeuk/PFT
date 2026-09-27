import 'package:flutter_test/flutter_test.dart';

import 'package:pft/main.dart';

void main() {
  testWidgets('로그인 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const BeaconAttendanceApp());

    expect(find.text('PFT'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}