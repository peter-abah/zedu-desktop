import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '',
      username: 'testuser',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime.utc(2026, 1, 1),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'test-org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

Future<void> _pumpButton(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: Scaffold(body: UserMenuButton())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows a pointer click cursor on hover', (tester) async {
    await _pumpButton(tester);

    final mouseRegions = tester.widgetList<MouseRegion>(
      find.descendant(
        of: find.byType(UserMenuButton),
        matching: find.byType(MouseRegion),
      ),
    );
    expect(mouseRegions, isNotEmpty);
    expect(
      mouseRegions.map((region) => region.cursor),
      contains(SystemMouseCursors.click),
    );
  });

  testWidgets('opens the user menu dialog on tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          orgCreditBalanceProvider.overrideWithValue(0),
        ],
        child: const MaterialApp(home: Scaffold(body: UserMenuButton())),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(UserMenuButton));
    await tester.pumpAndSettle();

    expect(find.byType(UserMenuDialog), findsOneWidget);
  });
}
