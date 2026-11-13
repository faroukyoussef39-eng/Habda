import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_controller.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/score_bars.dart';
import '../widgets/sheep_avatar.dart';

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider);
    final room = s.room!;
    final game = ref.read(gameProvider.notifier);
    final ranked = [...room.players]..sort((a, b) => b.score.compareTo(a.score));
    final winner = ranked.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Heading('GAME OVER! 🏆', size: 40),
        if (winner != null) ...[
          const SizedBox(height: 12),
          Center(child: SheepAvatar(index: winner.avatar, size: 160)),
          const SizedBox(height: 8),
          Heading('${winner.name} is the ultimate bluffer!', size: 24),
          const SizedBox(height: 16),
        ],
        Panel(child: ScoreBars(room: room, meId: s.playerId)),
        if (s.isHost)
          GameButton(label: 'Play again', icon: Icons.replay_rounded, kind: GameButtonKind.moss, onPressed: game.restart),
        GameButton(label: 'Leave', icon: Icons.logout_rounded, kind: GameButtonKind.stone, onPressed: game.leave),
      ],
    );
  }
}
