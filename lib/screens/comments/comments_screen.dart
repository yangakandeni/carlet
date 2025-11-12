import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/models/comment_model.dart';
import 'package:carlet/services/comment_service.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/widgets/reaction_picker_dialog.dart';

class CommentsScreen extends StatefulWidget {
  final Report report;

  const CommentsScreen({super.key, required this.report});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentService = CommentService();
  final _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    try {
      await _commentService.addComment(
        reportId: widget.report.id,
        userId: user.id,
        userName: user.name,
        userPhotoUrl: user.photoUrl,
        text: text,
        parentCommentId: _replyToCommentId,
      );

      _commentController.clear();
      setState(() {
        _replyToCommentId = null;
        _replyToUserName = null;
      });

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Comment posted');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Failed to post comment: $e');
    }
  }

  void _showReactionPicker(Comment comment) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => ReactionPickerDialog(
        comment: comment,
        currentUserId: user.id,
        // Use then/catchError but capture a stable ScaffoldMessengerState
        // before the async call so we don't use BuildContext across async gaps.
        onReactionSelected: (reaction) {
          final messenger = ScaffoldMessenger.of(context);
          _commentService
              .addReaction(
            commentId: comment.id,
            userId: user.id,
            reaction: reaction,
          )
              .catchError((e) {
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text('Failed to add reaction: $e')));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResolved = widget.report.status == 'resolved';
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        // Invisible AppBar: transparent background, zero elevation
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _commentService.streamComments(widget.report.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load comments: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allComments = snapshot.data!;
                final topLevelComments =
                    allComments.where((c) => c.isTopLevel).toList();

                if (topLevelComments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final comment = topLevelComments[index];
                    final replies = allComments
                        .where((c) => c.parentCommentId == comment.id)
                        .toList();

                    return _CommentTile(
                      comment: comment,
                      replies: replies,
                      currentUserId: user?.id,
                      isResolved: isResolved,
                      onReply: (commentId, userName) {
                        setState(() {
                          _replyToCommentId = commentId;
                          _replyToUserName = userName;
                        });
                      },
                      onLongPress: (c) => _showReactionPicker(c),
                      onDelete: (commentId) {
                        final messenger = ScaffoldMessenger.of(context);
                        _commentService
                            .deleteComment(commentId, widget.report.id)
                            .then((_) {
                          if (!mounted) return;
                          messenger.showSnackBar(const SnackBar(content: Text('Comment deleted')));
                        }).catchError((e) {
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Comment input
          if (!isResolved)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyToUserName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: theme.colorScheme.secondaryContainer,
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Replying to $_replyToUserName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _replyToCommentId = null;
                                _replyToUserName = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _postComment(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _postComment,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isResolved)
            Container(
              padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 8),
                    Text(
                      'This post is resolved. Comments are read-only.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final List<Comment> replies;
  final String? currentUserId;
  final bool isResolved;
  final Function(String commentId, String userName) onReply;
  final Function(Comment comment) onLongPress;
  final Function(String commentId) onDelete;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.isResolved,
    required this.onReply,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnComment = comment.userId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        InkWell(
          onLongPress: isResolved ? null : () => onLongPress(comment),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info and timestamp
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: comment.userPhotoUrl != null
                          ? NetworkImage(comment.userPhotoUrl!)
                          : null,
                      child: comment.userPhotoUrl == null
                          ? Text(
                              comment.userName?.substring(0, 1).toUpperCase() ??
                                  '?',
                              style: const TextStyle(fontSize: 14),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName ?? 'Anonymous',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTimestamp(comment.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwnComment && !isResolved)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => onDelete(comment.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Comment text
                Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                // Reactions and reply button
                Row(
                  children: [
                    // Show reactions if any
                    if (comment.reactionCounts.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: comment.reactionCounts.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '${e.key} ${e.value}',
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Reply button
                    if (!isResolved)
                      TextButton.icon(
                        onPressed: () =>
                            onReply(comment.id, comment.userName ?? 'User'),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Reply'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Replies (indented)
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              children: replies.map((reply) {
                final isOwnReply = reply.userId == currentUserId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onLongPress: isResolved ? null : () => onLongPress(reply),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: reply.userPhotoUrl != null
                                  ? NetworkImage(reply.userPhotoUrl!)
                                  : null,
                              child: reply.userPhotoUrl == null
                                  ? Text(
                                      reply.userName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          '?',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply.userName ?? 'Anonymous',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(reply.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwnReply && !isResolved)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18),
                                onPressed: () => onDelete(reply.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply.text,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (reply.reactionCounts.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  reply.reactionCounts.entries.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    '${e.key} ${e.value}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const Divider(),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

  return timestamp.toLocal().toString().split(' ')[0];
  }
}
