import 'package:cloud_firestore/cloud_firestore.dart';

/// Reaction types for comments
enum CommentReaction {
  thumbsUp('👍'),
  thumbsDown('👎'),
  heart('❤️'),
  laugh('😂');

  final String emoji;
  const CommentReaction(this.emoji);
}

class Comment {
  final String id;
  final String reportId;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String text;
  final String? parentCommentId; // null for top-level comments, set for replies
  final Map<String, String> reactions; // userId -> reactionType (emoji)
  final DateTime timestamp;

  const Comment({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.userName,
    this.userPhotoUrl,
    this.parentCommentId,
    this.reactions = const {},
  });

  /// Check if this is a top-level comment (not a reply)
  bool get isTopLevel => parentCommentId == null;

  /// Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;

  /// Get count of each reaction type
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final reaction in reactions.values) {
      counts[reaction] = (counts[reaction] ?? 0) + 1;
    }
    return counts;
  }

  factory Comment.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
      return null;
    }

    // Parse reactions map
    Map<String, String> parseReactions(dynamic v) {
      if (v == null) return {};
      if (v is Map) {
        return v.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      return {};
    }

    return Comment(
      id: id,
      reportId: map['reportId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String?,
      userPhotoUrl: map['userPhotoUrl'] as String?,
      text: map['text'] as String,
      parentCommentId: map['parentCommentId'] as String?,
      reactions: parseReactions(map['reactions']),
      timestamp: parseDate(map['timestamp']) ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'parentCommentId': parentCommentId,
      'reactions': reactions,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create a copy with updated reactions
  Comment copyWith({
    String? id,
    String? reportId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? text,
    String? parentCommentId,
    Map<String, String>? reactions,
    DateTime? timestamp,
  }) {
    return Comment(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      reactions: reactions ?? this.reactions,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
