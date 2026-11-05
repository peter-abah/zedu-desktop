import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _Dms extends DmListNotifier {
  _Dms(this.conversations);

  final List<DmConversation> conversations;

  @override
  Future<List<DmConversation>> build() async => conversations;
}

class _Channels extends ChannelNotifier {
  _Channels(this.channels);

  final List<Channel> channels;

  @override
  Future<List<Channel>> build() async => channels;
}

class _FailingDms extends DmListNotifier {
  @override
  Future<List<DmConversation>> build() async =>
      throw Exception('dm load failed');
}

DmConversation _dm(String id, String name, {int unread = 0}) => DmConversation(
  channelId: id,
  username: name,
  participantId: 'p-$id',
  previewMessage: '<p>Hello from $name</p>',
  unreadCount: unread,
);

Channel _channel(String id, String name, {int unread = 0}) => Channel(
  id: id,
  name: name,
  description: '',
  organisationId: 'org-1',
  ownerId: 'owner-1',
  unreadCount: unread,
);

Widget _opener() => Builder(
  builder: (context) => TextButton(
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => const NotificationsDialog(),
    ),
    child: const Text('Open'),
  ),
);

void main() {
  group('NotificationsDialog', () {
    Future<void> openDialog(
      WidgetTester tester, {
      List<DmConversation> dms = const [],
      List<Channel> channels = const [],
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dmListProvider.overrideWith(() => _Dms(dms)),
            channelProvider.overrideWith(() => _Channels(channels)),
          ],
          child: buildTestMaterialApp(_opener()),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the empty state when no DM is unread', (tester) async {
      await openDialog(tester, dms: [_dm('c-ada', 'Ada')]);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('You have no unread messages.'), findsOneWidget);
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('lists only the unread DMs', (tester) async {
      await openDialog(
        tester,
        dms: [
          _dm('c-ada', 'Ada', unread: 3),
          _dm('c-bo', 'Bo'),
          _dm('c-cy', 'Cy', unread: 1),
        ],
      );

      expect(find.text("You're all caught up"), findsNothing);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Hello from Ada'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Cy'), findsOneWidget);
      expect(find.text('Bo'), findsNothing);
    });

    testWidgets('lists unread channels when no DM is unread', (tester) async {
      await openDialog(
        tester,
        dms: [_dm('c-ada', 'Ada')],
        channels: [
          _channel('ch-general', 'general', unread: 5),
          _channel('ch-random', 'random'),
        ],
      );

      expect(find.text("You're all caught up"), findsNothing);
      expect(find.text('general'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('random'), findsNothing);
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('clicking an unread channel opens it on the home screen', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: AppRouter.home,
            builder: (_, _) => const Scaffold(body: Text('home screen')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => Scaffold(body: _opener()),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          dmListProvider.overrideWith(() => _Dms(const [])),
          channelProvider.overrideWith(
            () => _Channels([_channel('ch-general', 'general', unread: 2)]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('general'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsDialog), findsNothing);
      expect(container.read(activeChatProvider).id, 'general');
      expect(find.text('home screen'), findsOneWidget);
    });

    testWidgets('a failed load shows a retry instead of caught up', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dmListProvider.overrideWith(() => _FailingDms()),
            channelProvider.overrideWith(() => _Channels(const [])),
          ],
          child: buildTestMaterialApp(_opener()),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up"), findsNothing);
      expect(find.text("Couldn't load notifications."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty or emoji name shows a safe initial', (tester) async {
      await openDialog(
        tester,
        dms: [
          _dm('c-blank', '  ', unread: 1),
          _dm('c-emoji', '😀 Joy', unread: 2),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('😀'), findsOneWidget);
    });

    testWidgets('clicking an unread DM opens it on the home screen', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: AppRouter.home,
            builder: (_, _) => const Scaffold(body: Text('home screen')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => Scaffold(body: _opener()),
          ),
        ],
      );
      addTearDown(router.dispose);
      final ada = _dm('c-ada', 'Ada', unread: 2);
      final container = ProviderContainer(
        overrides: [
          dmListProvider.overrideWith(() => _Dms([ada])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsDialog), findsNothing);
      expect(container.read(selectedDmProvider)?.channelId, 'c-ada');
      expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
      expect(find.text('home screen'), findsOneWidget);
    });

    testWidgets('close button is labelled and closes it', (tester) async {
      await openDialog(tester);

      final close = find.widgetWithIcon(IconButton, Icons.close);
      expect(close, findsOneWidget);
      expect(tester.widget<IconButton>(close).tooltip, 'Close');

      await tester.tap(close);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsDialog), findsNothing);
    });

    testWidgets('sidebar bell opens the panel', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dmListProvider.overrideWith(() => _Dms(const []))],
          child: buildTestMaterialApp(
            const Scaffold(
              body: Row(
                children: [AppSidebarRail(activeType: HomeSidebarType.home)],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsDialog), findsOneWidget);
    });
  });
}
