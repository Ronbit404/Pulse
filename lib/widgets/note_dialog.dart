import 'package:flutter/material.dart';

/// Dialog for editing a personal note. Pops with the trimmed text (possibly
/// empty, which clears the note) or null when cancelled.
class NoteDialog extends StatefulWidget {
  const NoteDialog({super.key, required this.initialNote});

  final String initialNote;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Personal note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 140,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Note',
          helperText: 'Only you can see this. Leave empty to clear it.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
