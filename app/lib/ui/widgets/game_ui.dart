import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Slightly uneven corners make blocks look hand-carved from stone/wood.
const _carved = BorderRadius.only(
  topLeft: Radius.circular(22),
  topRight: Radius.circular(12),
  bottomLeft: Radius.circular(14),
  bottomRight: Radius.circular(24),
);

/// A chunky block with a dark outline and a thick 3D bottom edge that sinks
/// when pressed. Base for [GameButton] and [GameTile].
class Pressable3D extends StatefulWidget {
  const Pressable3D({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.depth = 7,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double depth;

  @override
  State<Pressable3D> createState() => _Pressable3DState();
}

class _Pressable3DState extends State<Pressable3D> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = enabled ? widget.color : Color.lerp(widget.color, Colors.grey, 0.6)!;
    final edge = Cave.edge(face);
    final sink = _down ? widget.depth - 2 : 0.0;
    return Padding(
      // Reserve room for the edge so pressing doesn't shift the layout.
      padding: EdgeInsets.only(bottom: widget.depth + 3),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            transform: Matrix4.translationValues(0, sink, 0),
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: _carved,
              border: Border.all(color: Cave.outline, width: 3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(face, Colors.white, 0.25)!, face],
              ),
              boxShadow: [
                BoxShadow(color: edge, offset: Offset(0, widget.depth - sink)),
                BoxShadow(color: Cave.outline, offset: Offset(0, widget.depth - sink + 3)),
              ],
            ),
            child: Opacity(opacity: enabled ? 1 : 0.6, child: widget.child),
          ),
        ),
      ),
    );
  }
}

enum GameButtonKind { sand, lava, moss, stone, sky }

/// Big carved game button, like the PLAY / STORE buttons of an arcade menu.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = GameButtonKind.sand,
    this.icon,
    this.subtitle,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonKind kind;
  final IconData? icon;
  final String? subtitle;
  final bool compact;

  Color get _color => switch (kind) {
        GameButtonKind.sand => Cave.sand,
        GameButtonKind.lava => Cave.lava,
        GameButtonKind.moss => Cave.moss,
        GameButtonKind.stone => Cave.stone,
        GameButtonKind.sky => Cave.sky,
      };

  Color get _text => switch (kind) {
        GameButtonKind.lava => Cave.gold,
        GameButtonKind.sky => Colors.white,
        _ => Cave.ink,
      };

  @override
  Widget build(BuildContext context) => Pressable3D(
        color: _color,
        onTap: onPressed,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: compact ? 6 : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _text, size: compact ? 20 : 26),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: displayFont(size: compact ? 18 : 26, color: _text),
                  ),
                ),
              ],
            ),
            if (subtitle != null)
              Text(subtitle!, style: displayFont(size: 14, color: _text.withValues(alpha: 0.85))),
          ],
        ),
      );
}

/// Square block tile with an icon, like the icon row of an arcade menu.
class GameTile extends StatelessWidget {
  const GameTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.size = 140,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        child: Pressable3D(
          color: color,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, size: size * 0.38, color: Colors.white, shadows: const [
                Shadow(color: Cave.outline, offset: Offset(0, 3)),
              ]),
              const SizedBox(height: 6),
              Text(label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: displayFont(size: 17, color: Colors.white).copyWith(shadows: const [
                    Shadow(color: Cave.outline, offset: Offset(0, 2)),
                  ])),
            ],
          ),
        ),
      );
}

/// "BLUFF PARTY" in carved stone letters, each one slightly tilted.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StoneWord('BLUFF', size: size, fill: Cave.sand),
          Transform.translate(
            offset: Offset(size * 0.2, -size * 0.12),
            child: _StoneWord('PARTY', size: size * 0.82, fill: Cave.stone),
          ),
        ],
      );
}

class _StoneWord extends StatelessWidget {
  const _StoneWord(this.word, {required this.size, required this.fill});
  final String word;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final rnd = Random(word.hashCode);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in word.split(''))
          Transform.rotate(
            angle: (rnd.nextDouble() - 0.5) * 0.28,
            child: Transform.translate(
              offset: Offset(0, (rnd.nextDouble() - 0.5) * size * 0.12),
              child: Stack(
                children: [
                  // Outline + 3D edge, then the face on top.
                  Text(ch,
                      style: displayFont(size: size).copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = size * 0.16
                          ..color = Cave.outline,
                        shadows: [Shadow(color: Cave.outline, offset: Offset(0, size * 0.1))],
                      )),
                  Text(ch, style: displayFont(size: size, color: fill)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Sunset sky with mist swirls and floating carved-rock islands.
class CaveBackground extends StatelessWidget {
  const CaveBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Cave.skyTop, Cave.skyMist, Cave.skyPeach, Cave.skyPink],
            stops: [0, 0.35, 0.65, 1],
          ),
        ),
        child: CustomPaint(painter: _IslandsPainter(), child: child),
      );
}

class _IslandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Warm glow and mist swirls.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.42),
      w * 0.6,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.42), radius: w * 0.6)),
    );
    final mist = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.5 + i * 0.12);
      canvas.drawPath(
        Path()
          ..moveTo(-20, y)
          ..cubicTo(w * 0.3, y - 60, w * 0.6, y + 50, w + 20, y - 20),
        mist,
      );
    }

    // Distant small blocks (faded) then big cliffs at the edges.
    final far = Random(7);
    for (var i = 0; i < 9; i++) {
      final s = 14.0 + far.nextDouble() * 22;
      _block(canvas, Rect.fromLTWH(far.nextDouble() * w, h * (0.4 + far.nextDouble() * 0.3), s, s),
          const Color(0xFFE2CFC0), opacity: 0.55);
    }
    final cliff = min(w * 0.2, 140.0);
    for (var i = 0; i < 4; i++) {
      _block(canvas, Rect.fromLTWH(-cliff * 0.3, h * (0.62 + i * 0.1), cliff, cliff * 0.8),
          const Color(0xFFCBB59A));
      _block(canvas, Rect.fromLTWH(w - cliff * 0.7, h * (0.58 + i * 0.11), cliff, cliff * 0.8),
          const Color(0xFFD7B48D));
    }
    _block(canvas, Rect.fromLTWH(w * 0.42, h * 0.9, cliff * 0.9, cliff * 0.7), const Color(0xFFE0B98C));
  }

  /// Stone block: lit face, shaded side, mossy cap, soft outline.
  void _block(Canvas canvas, Rect r, Color base, {double opacity = 1}) {
    Color c(Color x) => x.withValues(alpha: opacity);
    final radius = Radius.circular(r.width * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), Paint()..color = c(base));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(r.left + r.width * 0.62, r.top, r.right, r.bottom), radius),
      Paint()..color = c(Cave.edge(base).withValues(alpha: 0.55)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left - 2, r.top - 2, r.width + 4, r.height * 0.24), radius),
      Paint()..color = c(const Color(0xFFB5C24A)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c(Cave.outline.withValues(alpha: 0.35)),
    );
  }

  @override
  bool shouldRepaint(_IslandsPainter old) => false;
}

/// Pop-in toast with a shake: lava for problems, sand for info.
class GameToast extends StatelessWidget {
  const GameToast({super.key, required this.code, required this.onClose});
  final String code;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final n = noticeFor(code);
    final bg = n.info ? Cave.sand : Cave.lava;
    final fg = n.info ? Cave.ink : Colors.white;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      builder: (context, t, child) => Transform.translate(
        // Damped wobble right after it pops in.
        offset: Offset(sin(t * pi * 6) * 10 * (1 - t), 0),
        child: Transform.scale(scale: Curves.elasticOut.transform(t.clamp(0, 1)), child: child),
      ),
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: _carved,
            border: Border.all(color: Cave.outline, width: 3),
            boxShadow: [
              BoxShadow(color: Cave.edge(bg), offset: const Offset(0, 6)),
              const BoxShadow(color: Cave.outline, offset: Offset(0, 9)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Cave.outline, width: 2.5),
                ),
                child: Text(n.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(n.text, style: displayFont(size: 19, color: fg))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game-styled dialog: big emoji, chunky title, carved buttons.
Future<T?> showGameDialog<T>(
  BuildContext context, {
  required String emoji,
  required String title,
  String? message,
  Widget? content,
  required List<Widget> actions,
}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Cave.outline.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (context, anim, _, child) =>
          Transform.scale(scale: Curves.elasticOut.transform(anim.value).clamp(0.0, 1.2), child: child),
      pageBuilder: (context, _, __) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: Cave.cream,
              borderRadius: _carved,
              border: Border.all(color: Cave.outline, width: 3),
              boxShadow: [
                BoxShadow(color: Cave.edge(Cave.sand), offset: const Offset(0, 8)),
                const BoxShadow(color: Cave.outline, offset: Offset(0, 11)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 56)),
                Text(title, textAlign: TextAlign.center, style: displayFont(size: 28)),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
                ],
                if (content != null) ...[const SizedBox(height: 8), content],
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, spacing: 12, children: actions),
              ],
            ),
          ),
        ),
      ),
    );
