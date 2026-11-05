import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Panel opened from the notifications bell in the sidebar rail.
///
/// Lists the DMs and channels that have unread messages and opens one when
/// clicked. There is no mentions feed yet, so the empty state shows whenever
/// no DM and no channel is unread. Real incoming-message notifications are
/// still delivered by `NotificationService`.
class NotificationsDialog extends ConsumerWidget {
  const NotificationsDialog({super.key});

  void _openConversation(
    BuildContext context,
    WidgetRef ref,
    DmConversation conversation,
  ) {
    // Read before popping: the dialog's context is gone afterwards.
    final router = GoRouter.maybeOf(context);
    ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
    ref.read(selectedDmProvider.notifier).select(conversation);
    Navigator.of(context).pop();
    if (router != null &&
        router.routerDelegate.currentConfiguration.uri.path != AppRouter.home) {
      router.go(AppRouter.home);
    }
  }

  void _openChannel(BuildContext context, WidgetRef ref, Channel channel) {
    // Read before popping: the dialog's context is gone afterwards.
    final router = GoRouter.maybeOf(context);
    ref
        .read(activeChatProvider.notifier)
        .selectChannel(channel.name, channelId: channel.id);
    Navigator.of(context).pop();
    if (router != null &&
        router.routerDelegate.currentConfiguration.uri.path != AppRouter.home) {
      router.go(AppRouter.home);
    }
  }

  void _retry(WidgetRef ref) {
    ref.read(dmListProvider.notifier).refresh();
    ref.invalidate(channelProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dmState = ref.watch(dmListProvider);
    final channelState = ref.watch(channelProvider);
    final deletedIds = ref.watch(
      dmConversationActionsProvider.select((a) => a.deletedIds),
    );
    final unreadDms = (dmState.value ?? const <DmConversation>[])
        .where((c) => c.unreadCount > 0 && !deletedIds.contains(c.channelId))
        .toList();
    final unreadChannels = (channelState.value ?? const <Channel>[])
        .where((c) => c.unreadCount > 0 && !c.archived)
        .toList();
    // A failed load must not read as "caught up": show a retry instead.
    final hasError =
        (unreadDms.isEmpty && dmState.hasError) ||
        (unreadChannels.isEmpty && channelState.hasError);
    final isLoading =
        unreadDms.isEmpty &&
        unreadChannels.isEmpty &&
        (dmState.isLoading || channelState.isLoading);

    return Dialog(
      insetPadding: const EdgeInsets.only(bottom: 80, left: 74),
      alignment: Alignment.bottomLeft,
      backgroundColor: colors.background,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colors.textHint),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            if (hasError)
              _LoadError(onRetry: () => _retry(ref))
            else if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              )
            else if (unreadDms.isEmpty && unreadChannels.isEmpty)
              const _EmptyState()
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    for (final conversation in unreadDms)
                      _UnreadDmRow(
                        conversation: conversation,
                        onTap: () =>
                            _openConversation(context, ref, conversation),
                      ),
                    for (final channel in unreadChannels)
                      _UnreadChannelRow(
                        channel: channel,
                        onTap: () => _openChannel(context, ref, channel),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnreadDmRow extends StatelessWidget {
  const _UnreadDmRow({required this.conversation, required this.onTap});

  final DmConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = conversation.effectiveAvatarUrl;
    // Whole first character, so an empty name or an emoji can't break the row.
    final trimmedName = conversation.displayName.trim();
    final initial = trimmedName.isNotEmpty
        ? trimmedName.characters.first.toUpperCase()
        : '?';
    final preview = conversation.previewMessage
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryBg,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: TextStyle(fontSize: 13, color: colors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadChannelRow extends StatelessWidget {
  const _UnreadChannelRow({required this.channel, required this.onTap});

  final Channel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryBg,
              child: Text(
                '#',
                style: TextStyle(fontSize: 13, color: colors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${channel.unreadCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(
            "Couldn't load notifications.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You're all caught up",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You have no unread messages.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
