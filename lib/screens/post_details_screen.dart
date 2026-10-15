import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/social_api.dart';
import '../theme.dart';
import '../widgets/message_view.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

/// Route `/details`: reads the post from `ModalRoute.of(context)!.settings.arguments`.
class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    final Post post;
    try {
      post = Post.fromArguments(ModalRoute.of(context)!.settings.arguments);
    } on FormatException catch (e) {
      return ErrorScaffold(
        title: 'Post',
        message: 'This post cannot be shown: ${e.message}',
      );
    }
    return _PostDetailsView(key: ValueKey(post.id), deps: deps, post: post);
  }
}

class _PostDetailsView extends StatefulWidget {
  const _PostDetailsView({super.key, required this.deps, required this.post});

  final AppDependencies deps;
  final Post post;

  @override
  State<_PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<_PostDetailsView> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    // Posts written on this device are unknown to the server: no comments yet.
    if (widget.post.isLocal) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await widget.deps.api.fetchPostComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    if (_sending) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      setState(() => _sendError = 'Write something before sending.');
      return;
    }
    final me = widget.deps.feed.currentUser;
    if (me == null) {
      setState(
        () => _sendError =
            'Your profile has not loaded yet. Refresh the feed and try again.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final created = await widget.deps.api.createComment(
        postId: widget.post.id,
        name: me.name,
        email: me.email,
        body: text,
      );
      if (!mounted) return;
      widget.deps.feed.noteCommentAdded(widget.post.id);
      _commentController.clear();
      setState(() {
        _comments = [..._comments, created];
        _sending = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = e.message;
      });
    }
  }

  Widget _commentsSection(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return MessageView(
        icon: Icons.cloud_off,
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadComments,
      );
    }
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text('No comments yet. Be the first to reply.')),
      );
    }
    return Column(
      children: [for (final comment in _comments) _CommentTile(comment: comment)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                PostCard(deps: widget.deps, post: widget.post, detailed: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Text('Comments', style: theme.textTheme.titleMedium),
                ),
                _commentsSection(context),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sendError != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        _sendError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          enabled: !_sending,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton.filled(
                              tooltip: 'Send comment',
                              onPressed: _sendComment,
                              icon: const Icon(Icons.send),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(name: comment.email, radius: 18),
      title: Text(
        comment.email,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(comment.body),
    );
  }
}
