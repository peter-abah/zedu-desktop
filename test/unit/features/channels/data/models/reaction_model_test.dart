import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ReactionModel', () {
    test('parses a camelCase payload', () {
      final model = ReactionModel.fromJson({
        'messageId': 'message-1',
        'userId': 'user-1',
        'emoji': '👍',
        'createdAt': '2026-11-04T07:30:00.000Z',
      });

      expect(model.messageId, 'message-1');
      expect(model.userId, 'user-1');
      expect(model.emoji, '👍');
      expect(model.createdAt, DateTime.utc(2026, 11, 4, 7, 30));
    });

    test('parses the backend snake_case payload', () {
      final model = ReactionModel.fromJson({
        'message_id': 'message-2',
        'user_id': 'user-2',
        'emoji': '🎉',
        'created_at': '2026-11-04T08:00:00.000Z',
      });

      expect(model.messageId, 'message-2');
      expect(model.userId, 'user-2');
      expect(model.emoji, '🎉');
      expect(model.createdAt, DateTime.utc(2026, 11, 4, 8));
    });

    test('falls back for missing fields', () {
      final model = ReactionModel.fromJson({});

      expect(model.messageId, isEmpty);
      expect(model.userId, isEmpty);
      expect(model.emoji, isEmpty);
      expect(model.createdAt, isNull);
    });

    test('round-trips through toJson', () {
      final original = ReactionModel(
        messageId: 'message-3',
        userId: 'user-3',
        emoji: '❤️',
        createdAt: DateTime.utc(2026, 11, 4, 9, 15),
      );

      final restored = ReactionModel.fromJson(original.toJson());

      expect(restored.messageId, original.messageId);
      expect(restored.userId, original.userId);
      expect(restored.emoji, original.emoji);
      expect(restored.createdAt, original.createdAt);
    });

    test('omits a missing createdAt from toJson', () {
      const model = ReactionModel(
        messageId: 'message-4',
        userId: 'user-4',
        emoji: '👀',
      );

      expect(model.toJson().containsKey('createdAt'), isFalse);
    });
  });
}
