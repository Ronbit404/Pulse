import 'package:flutter/material.dart';

/// A network photo with a progress indicator and a visible failure state.
class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Image.network(
      url,
      fit: BoxFit.cover,
      semanticLabel: 'Photo attached to the post',
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        return Container(
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: total == null ? null : progress.cumulativeBytesLoaded / total,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: scheme.outline),
            const SizedBox(height: 4),
            Text(
              'Image unavailable',
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
