import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../theme.dart';
import 'sheep_avatar.dart';

/// Leaderboard as bars that fill up from last round's score to the new one,
/// with a medal emoji per rank (ties share a rank).
class ScoreBars extends StatelessWidget {
  const ScoreBars({super.key, required this.room, required this.meId, this.deltas = const {}});

  final RoomView room;
  final String? meId;
  final Map<String, int> deltas;

  static String emojiFor(int rank) => switch (rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '🐑',
      };

  static Color colorFor(int rank) => switch (rank) {
        1 => Cave.gold,
        2 => const Color(0xFFB0BEC5),
        3 => const Color(0xFFCD7F32),
        _ => Cave.moss,
      };

  @override
  Widget build(BuildContext context) {
    final sorted = [...room.players]..sort((a, b) => b.score.compareTo(a.score));
    final top = max(1, sorted.isEmpty ? 1 : sorted.first.score);
    return Column(
      children: [
        for (final p in sorted)
          _Bar(
            player: p,
            rank: 1 + sorted.where((o) => o.score > p.score).length,
            isMe: p.id == meId,
            delta: deltas[p.id] ?? 0,
            top: top,
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.player,
    required this.rank,
    required this.isMe,
    required this.delta,
    required this.top,
  });

  final PlayerView player;
  final int rank;
  final bool isMe;
  final int delta;
  final int top;

  @override
  Widget build(BuildContext context) {
    final from = (player.score - delta).clamp(0, player.score);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: from.toDouble(), end: player.score.toDouble()),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(ScoreBars.emojiFor(rank),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
            ),
            SheepAvatar(index: player.avatar, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isMe ? '${player.name} (you)' : player.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (delta > 0)
                        Text('  +$delta',
                            style: const TextStyle(
                                color: Cave.success, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Container(height: 22, color: Colors.black.withValues(alpha: 0.06)),
                        FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: (value / top).clamp(0.02, 1.0),
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(colors: [
                                ScoreBars.colorFor(rank).withValues(alpha: 0.7),
                                ScoreBars.colorFor(rank),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('${value.round()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
