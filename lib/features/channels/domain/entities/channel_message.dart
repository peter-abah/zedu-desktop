import 'package:zedu/features/dms/domain/message_content.dart';

/// A top-level message in a channel, as returned by
/// `GET /threads/channels/{channel_id}`.
class ChannelMessage {
  final String? id;
  final String senderName;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;
  final String? status;

  const ChannelMessage({
    this.id,
    required this.senderName,
    required this.text,
    this.avatarUrl,
    this.createdAt,
    this.status,
  });

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return ChannelMessage(
      id: json['id']?.toString(),
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['sender_name']) ??
          nonEmpty(json['username']) ??
          'Unknown',
      avatarUrl:
          nonEmpty(json['avatar_url']) ?? nonEmpty(json['default_avatar_url']),
      // Messages sent from the web app arrive as HTML (`<p>hi</p>`).
      // htmlMessageToMarkdown converts recognized formatting to Markdown
      // and keeps anything in angle brackets that is not real markup
      // (generics like `List<String>`, `<user@example.com>`, comparisons).
      text: htmlMessageToMarkdown(json['message']?.toString() ?? '').trim(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
      status: json['status']?.toString(),
    );
  }
}
