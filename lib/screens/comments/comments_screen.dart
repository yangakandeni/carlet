import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:carlet/models/report_model.dart';
import 'package:carlet/models/comment_model.dart';
import 'package:carlet/services/comment_service.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/widgets/reaction_picker_dialog.dart';
import 'package:carlet/utils/ui_constants.dart';

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
                      commentService: _commentService,
                      onReply: (commentId, userName) {
                        setState(() {
                          _replyToCommentId = commentId;
                          _replyToUserName = userName;
                        });
                      },
                      onLongPress: (c) => _showReactionPicker(c),
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
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyToUserName != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                children: [
                                  TextSpan(text: 'Replying to ', style: TextStyle(
                                    fontSize: theme.textTheme.bodyMedium?.fontSize
                                  )),
                                  TextSpan(
                                    text: _replyToUserName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                            onPressed: () {
                              setState(() {
                                _replyToCommentId = null;
                                _replyToUserName = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Cancel reply',
                          ),
                        ],
                      ),
                    ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                contentPadding: UIConstants.kInputContentPadding,
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _postComment(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _postComment,
                            icon: FaIcon(
                              FontAwesomeIcons.paperPlane,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            ),
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
                    FaIcon(
                      FontAwesomeIcons.lock,
                      size: 16,
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
  final CommentService commentService;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.isResolved,
    required this.onReply,
    required this.onLongPress,
    required this.commentService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        InkWell(
          onLongPress: isResolved ? null : () => onLongPress(comment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and timestamp inline
                      Row(
                        children: [
                          Text(
                            comment.userName ?? 'Anonymous',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(comment.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Comment text
                      Text(
                        comment.text,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      // Actions: Like, Reply
                      Row(
                        children: [
                          // Thumbs up
                          _buildLikeButton(
                            context,
                            comment,
                            isThumbsUp: true,
                          ),
                          const SizedBox(width: 12),
                          // Reply button
                          if (!isResolved)
                            InkWell(
                              onTap: () => onReply(comment.id, comment.userName ?? 'User'),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  'Reply',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Replies (indented)
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              children: replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: InkWell(
                    onLongPress: isResolved ? null : () => onLongPress(reply),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username and timestamp inline
                              Row(
                                children: [
                                  Text(
                                    reply.userName ?? 'Anonymous',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(reply.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply.text,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              // Actions: Like, Reply
                              Row(
                                children: [
                                  // Thumbs up (small version for replies)
                                  _buildLikeButton(
                                    context,
                                    reply,
                                    isThumbsUp: true,
                                    isSmall: true,
                                  ),
                                  const SizedBox(width: 12),
                                  // Reply button (enable nested replies)
                                  if (!isResolved)
                                    InkWell(
                                      onTap: () => onReply(reply.id, reply.userName ?? 'User'),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Text(
                                          'Reply',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLikeButton(
    BuildContext context,
    Comment comment,
    {
    required bool isThumbsUp,
    bool isSmall = false,
  }) {
    final theme = Theme.of(context);
    final userId = currentUserId;
    if (userId == null) return const SizedBox.shrink();

    final reactionType = isThumbsUp ? CommentReaction.thumbsUp : CommentReaction.thumbsDown;
    final userReaction = comment.reactions[userId];
    final isActive = userReaction == reactionType.emoji;
    
    // Count reactions of this type
    int count = 0;
    for (final reaction in comment.reactions.values) {
      if (reaction == reactionType.emoji) count++;
    }

    return InkWell(
      onTap: isResolved ? null : () {
        if (isActive) {
          // Remove reaction
          commentService.removeReaction(
            commentId: comment.id,
            userId: userId,
          );
        } else {
          // Add reaction
          commentService.addReaction(
            commentId: comment.id,
            userId: userId,
            reaction: reactionType,
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isActive && count > 0 ? 8 : 6,
          vertical: 4,
        ),
        decoration: isActive && count > 0
            ? BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              isThumbsUp ? FontAwesomeIcons.thumbsUp : FontAwesomeIcons.thumbsDown,
              size: isSmall ? 12 : 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: (isSmall ? theme.textTheme.bodySmall : theme.textTheme.bodySmall)?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: isSmall ? 11 : 12,
                ),
              ),
            ],
          ],
        ),
      ),
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
