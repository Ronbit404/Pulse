import 'package:flutter/material.dart';

/// Initials on a color derived from the name, optionally wrapped in a story ring.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.ring = false,
  });

  final String name;
  final double radius;

  /// Draws a gradient ring around the avatar (used for people you follow).
  final bool ring;

  static const List<Color> _palette = [
    Color(0xFF5B5BD6),
    Color(0xFFD6409F),
    Color(0xFF0E9F6E),
    Color(0xFFE5732F),
    Color(0xFF2B8CD6),
    Color(0xFF8E4EC6),
  ];

  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final second = parts.length > 1 ? parts[1][0] : '';
    return (parts.first[0] + second).toUpperCase();
  }

  static Color colorFor(String name) {
    final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[sum % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colorFor(name),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
    if (!ring) return avatar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: avatar,
      ),
    );
  }
}
