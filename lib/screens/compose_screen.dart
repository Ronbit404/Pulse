import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_dependencies.dart';
import '../controllers/feed_controller.dart';
import '../services/social_api.dart';
import '../theme.dart';
import '../widgets/user_avatar.dart';

/// Route `/compose`: publishes a post and pops with the created `Post`.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = message;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    try {
      // The server must confirm with 201 before the post is kept on the device.
      await widget.deps.api.createPost(
        userId: FeedController.currentUserId,
        title: title,
        body: body,
      );
      final post = await widget.deps.myPosts.add(
        userId: FeedController.currentUserId,
        title: title,
        body: body,
      );
      if (!mounted) return;
      Navigator.pop(context, post);
    } on ApiException catch (e) {
      _fail(e.message);
    } on HiveError catch (e) {
      _fail(
        'The server accepted your post, but it could not be stored on this '
        'device: ${e.message}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = widget.deps.feed.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              UserAvatar(name: me?.name ?? 'You', radius: 20),
              const SizedBox(width: 12),
              Text(me?.name ?? 'You', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => _required(v, 'Title'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bodyController,
                  enabled: !_submitting,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: "What's on your mind?",
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => _required(v, 'Body'),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
