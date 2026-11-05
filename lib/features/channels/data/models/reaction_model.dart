/// A reaction on a channel message.
class ReactionModel {
  const ReactionModel({
    required this.messageId,
    required this.userId,
    required this.emoji,
    this.createdAt,
  });

  final String messageId;
  final String userId;
  final String emoji;
  final DateTime? createdAt;

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      messageId: _asString(json['messageId'] ?? json['message_id']),
      userId: _asString(json['userId'] ?? json['user_id']),
      emoji: _asString(json['emoji']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'userId': userId,
    'emoji': emoji,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}

String _asString(Object? value) => value?.toString() ?? '';

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
