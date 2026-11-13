import 'package:flutter/material.dart';

/// Character portraits in assets/avatars/. Index comes from the server
/// (kAvatarCount = 12): 6 characters × 2 ring colours, so every seat differs.
const _characters = ['shaun', 'timmy', 'shirley', 'bitzer', 'sheep1', 'sheep2'];

const _rings = [
  Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFFFFB300), Color(0xFFE5533D),
  Color(0xFF8E24AA), Color(0xFF00ACC1), Color(0xFFF06292), Color(0xFF6D4C41),
  Color(0xFF7CB342), Color(0xFF3949AB), Color(0xFFFB8C00), Color(0xFF546E7A),
];

class SheepAvatar extends StatelessWidget {
  const SheepAvatar({super.key, required this.index, this.size = 64});
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final i = index % _rings.length;
    final character = _characters[i % _characters.length];
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: _rings[i],
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4A2E17), width: size > 40 ? 3 : 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/avatars/$character.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
