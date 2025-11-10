import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:carlet/models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Toggle like on a report. Adds userId to likedBy if not present, removes if present.
  /// Updates likeCount accordingly.
  Future<void> toggleLike(String reportId, String userId) async {
    final reportRef = _db.collection('reports').doc(reportId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reportRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      
      if (likedBy.contains(userId)) {
        // Unlike: remove user from likedBy
        likedBy.remove(userId);
      } else {
        // Like: add user to likedBy
        likedBy.add(userId);
      }
      
      transaction.update(reportRef, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
      });
    });
  }

  /// Add a new comment to a report
  Future<String> addComment({
    required String reportId,
    required String userId,
    String? userName,
    String? userPhotoUrl,
    required String text,
    String? parentCommentId,
  }) async {
    final commentId = _uuid.v4();
    final comment = Comment(
      id: commentId,
      reportId: reportId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text,
      parentCommentId: parentCommentId,
      timestamp: DateTime.now().toUtc(),
    );

    // Add comment to comments collection
    await _db.collection('comments').doc(commentId).set(comment.toMap());

    // Increment comment count on the report
    await _db.collection('reports').doc(reportId).update({
      'commentCount': FieldValue.increment(1),
    });

    return commentId;
  }

  /// Stream all comments for a report, ordered by timestamp
  Stream<List<Comment>> streamComments(String reportId) {
    return _db
        .collection('comments')
        .where('reportId', isEqualTo: reportId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Add or update a reaction to a comment
  Future<void> addReaction({
    required String commentId,
    required String userId,
    required CommentReaction reaction,
  }) async {
    final commentRef = _db.collection('comments').doc(commentId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(commentRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final reactions = Map<String, String>.from(data['reactions'] ?? {});
      
      // Toggle reaction: if user already reacted with same emoji, remove it
      // Otherwise, add/update the reaction
      if (reactions[userId] == reaction.emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = reaction.emoji;
      }
      
      transaction.update(commentRef, {'reactions': reactions});
    });
  }

  /// Remove a reaction from a comment
  Future<void> removeReaction({
    required String commentId,
    required String userId,
  }) async {
    await _db.collection('comments').doc(commentId).update({
      'reactions.$userId': FieldValue.delete(),
    });
  }

  /// Delete all comments for a report (called when report is deleted/resolved)
  Future<void> deleteCommentsForReport(String reportId) async {
    final batch = _db.batch();
    
    final commentsSnapshot = await _db
        .collection('comments')
        .where('reportId', isEqualTo: reportId)
        .get();
    
    for (final doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  /// Delete a specific comment (and update report comment count)
  Future<void> deleteComment(String commentId, String reportId) async {
    await _db.collection('comments').doc(commentId).delete();
    
    // Decrement comment count on the report
    await _db.collection('reports').doc(reportId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }
}
