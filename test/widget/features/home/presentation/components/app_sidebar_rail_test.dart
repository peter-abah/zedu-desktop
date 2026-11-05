import 'package:flutter/rendering.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  testWidgets('navigation labels use labelSmall and fit the 50px rail', (
    tester,
  ) async {
    // Use the app font instead of Flutter test's fallback font for layout.
    await (FontLoader(
      FontFamily.lato,
    )..addFont(rootBundle.load('assets/fonts/Lato/Lato-Regular.ttf'))).load();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: AppSidebarRail.width,
              height: 600,
              child: AppSidebarRail(activeType: HomeSidebarType.home),
            ),
          ),
        ),
      ),
    );

    final rail = tester.getSize(find.byType(AppSidebarRail));
    expect(rail.width, AppSidebarRail.width);

    final labelStyle = AppTheme.light.textTheme.labelSmall!;
    for (final label in ['Home', 'DMs', 'People', 'Files', 'Buzz']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.fontSize, labelStyle.fontSize);
      expect(text.style?.fontWeight, labelStyle.fontWeight);

      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: '$label is clipped');
      final labelSize = tester.getSize(find.text(label));
      final singleLineHeight = labelStyle.fontSize! * labelStyle.height!;
      expect(
        labelSize.height,
        lessThanOrEqualTo(singleLineHeight + 1),
        reason: '$label wrapped',
      );
      expect(labelSize.width, lessThanOrEqualTo(38));
    }

    final navIcons = tester.widgetList<Icon>(find.byType(Icon)).take(5);
    expect(navIcons, hasLength(5));
    for (final icon in navIcons) {
      expect(icon.size, 20);
    }

    final notificationIcon = tester.widget<Icon>(
      find.byIcon(Icons.notifications_none_outlined),
    );
    final settingsIcon = tester.widget<Icon>(
      find.byIcon(Icons.settings_outlined),
    );

    expect(notificationIcon.size, 20);
    expect(settingsIcon.size, 20);

    expect(tester.takeException(), isNull);
  });

  testWidgets('settings rail button has a tooltip with message "Settings"', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: AppSidebarRail.width,
              height: 600,
              child: AppSidebarRail(activeType: HomeSidebarType.home),
            ),
          ),
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.byIcon(Icons.settings_outlined),
        matching: find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'Settings',
        ),
      ),
      findsOneWidget,
    );
  });

  group('notifications bell dot', () {
    Finder bellStack() => find.ancestor(
      of: find.byIcon(Icons.notifications_none_outlined),
      matching: find.byType(Stack),
    );

    bool hasDot(WidgetTester tester) {
      final stack = tester.widget<Stack>(bellStack());
      return stack.children.whereType<Positioned>().isNotEmpty;
    }

    Future<void> pumpRail(
      WidgetTester tester, {
      List<DmConversation> dms = const [],
      List<Channel> channels = const [],
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dmListProvider.overrideWith(() => _RailDms(dms)),
            channelProvider.overrideWith(() => _RailChannels(channels)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SizedBox(
                width: AppSidebarRail.width,
                height: 600,
                child: AppSidebarRail(activeType: HomeSidebarType.home),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('is off when nothing is unread', (tester) async {
      await pumpRail(
        tester,
        dms: [
          DmConversation(
            channelId: 'c-ada',
            username: 'Ada',
            participantId: 'p-ada',
            previewMessage: '',
            unreadCount: 0,
          ),
        ],
      );

      expect(bellStack(), findsOneWidget);
      expect(hasDot(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is on when a DM is unread', (tester) async {
      await pumpRail(
        tester,
        dms: [
          DmConversation(
            channelId: 'c-ada',
            username: 'Ada',
            participantId: 'p-ada',
            previewMessage: '',
            unreadCount: 3,
          ),
        ],
      );

      expect(hasDot(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is on when a channel is unread', (tester) async {
      await pumpRail(
        tester,
        channels: [
          Channel(
            id: 'ch-general',
            name: 'general',
            description: '',
            organisationId: 'org-1',
            ownerId: 'owner-1',
            unreadCount: 2,
          ),
        ],
      );

      expect(hasDot(tester), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

class _RailDms extends DmListNotifier {
  _RailDms(this.conversations);

  final List<DmConversation> conversations;

  @override
  Future<List<DmConversation>> build() async => conversations;
}

class _RailChannels extends ChannelNotifier {
  _RailChannels(this.channels);

  final List<Channel> channels;

  @override
  Future<List<Channel>> build() async => channels;
}
