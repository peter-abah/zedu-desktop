import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockChatHistory extends Mock implements ChatHistoryNotifier {}

class MockDraftStore extends Mock implements DmDraftStore {}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

void main() {
  setUp(() {
    if (locator.isRegistered<AppConfig>()) {
      locator.unregister<AppConfig>();
    }
    locator.registerSingleton<AppConfig>(
      const AppConfig(apiBaseUrl: 'http://test', usesMockData: false),
    );
  });

  tearDown(() {
    if (locator.isRegistered<AppConfig>()) {
      locator.unregister<AppConfig>();
    }
  });

  testWidgets('DM menu uses a white surface and opens the selected action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = MockChatHistory();
    when(() => history.messages).thenReturn([]);
    when(() => history.isLoading).thenReturn(false);
    when(() => history.hasMore).thenReturn(false);
    when(() => history.loadFailed).thenReturn(false);
    when(() => history.loadMoreFailed).thenReturn(false);
    when(() => history.historyCleared).thenReturn(false);
    final drafts = MockDraftStore();
    when(() => drafts.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          chatHistoryProvider('chat-1').overrideWith((ref) => history),
          dmDraftStoreProvider.overrideWith((ref) => drafts),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'chat-1',
                username: 'Menu Tester',
                participantId: 'user-1',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('View profile'), findsOneWidget);
    expect(find.text('Delete conversation'), findsOneWidget);
    final menuSurface = tester
        .widgetList<Material>(find.byType(Material))
        .where(
          (material) =>
              material.shape is RoundedRectangleBorder &&
              material.elevation == 8,
        );
    expect(menuSurface, hasLength(1));
    expect(menuSurface.single.color, AppPalette.light.onPrimary);
    expect(menuSurface.single.surfaceTintColor, Colors.transparent);
    expect(
      tester.widget<Text>(find.text('Delete conversation')).style?.color,
      AppPalette.light.error,
    );

    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('User ID: user-1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('kebab menu sizes to its content instead of a fixed width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = MockChatHistory();
    when(() => history.messages).thenReturn([]);
    when(() => history.isLoading).thenReturn(false);
    when(() => history.hasMore).thenReturn(false);
    when(() => history.loadFailed).thenReturn(false);
    when(() => history.loadMoreFailed).thenReturn(false);
    when(() => history.historyCleared).thenReturn(false);
    final drafts = MockDraftStore();
    when(() => drafts.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          chatHistoryProvider('chat-1').overrideWith((ref) => history),
          dmDraftStoreProvider.overrideWith((ref) => drafts),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'chat-1',
                username: 'Menu Tester',
                participantId: 'user-1',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final menu = tester.widget<PopupMenuButton<String>>(
      find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuButton<String> &&
            widget.tooltip == 'More options',
      ),
    );
    expect(menu.constraints, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('every kebab menu option responds when selected', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = MockChatHistory();
    when(() => history.messages).thenReturn([]);
    when(() => history.isLoading).thenReturn(false);
    when(() => history.hasMore).thenReturn(false);
    when(() => history.loadFailed).thenReturn(false);
    when(() => history.loadMoreFailed).thenReturn(false);
    when(() => history.historyCleared).thenReturn(false);
    final drafts = MockDraftStore();
    when(() => drafts.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          chatHistoryProvider('chat-1').overrideWith((ref) => history),
          dmDraftStoreProvider.overrideWith((ref) => drafts),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'chat-1',
                username: 'Menu Tester',
                participantId: 'user-1',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> openMenu() async {
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
    }

    await openMenu();
    for (final label in [
      'View profile',
      'Mute notifications',
      'Pin conversation',
      'Pinned messages',
      'Search in conversation',
      'View files',
      'Clear history',
      'Block User',
      'Delete conversation',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    // Pinned messages answers instead of silently closing the menu.
    await tester.tap(find.text('Pinned messages'));
    await tester.pumpAndSettle();
    expect(find.text('No pinned messages yet.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    // Muting flips the menu label so the action is visible.
    await openMenu();
    await tester.tap(find.text('Mute notifications'));
    await tester.pumpAndSettle();
    await openMenu();
    expect(find.text('Unmute notifications'), findsOneWidget);
    await tester.tap(find.text('Unmute notifications'));
    await tester.pumpAndSettle();

    // Pinning flips the menu label too.
    await openMenu();
    await tester.tap(find.text('Pin conversation'));
    await tester.pumpAndSettle();
    await openMenu();
    expect(find.text('Unpin conversation'), findsOneWidget);
    await tester.tap(find.text('Unpin conversation'));
    await tester.pumpAndSettle();

    // Blocking confirms and then acknowledges the choice.
    await openMenu();
    await tester.tap(find.text('Block User'));
    await tester.pumpAndSettle();
    expect(find.text('Block Menu Tester?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Block user'));
    await tester.pumpAndSettle();
    expect(find.text('Menu Tester blocked.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
