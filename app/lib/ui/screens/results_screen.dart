import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/score_bars.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider);
    final room = s.room!;
    final r = room.result!;
    final options = [...r.options]..sort((a, b) {
        if (a.isTruth != b.isTruth) return a.isTruth ? -1 : 1;
        return b.voterIds.length.compareTo(a.voterIds.length);
      });
    final lastRound = room.round >= room.totalRounds;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          color: const Color(0xFFE6F2C4),
          child: Column(
            children: [
              ArabicText(r.questionText),
              const SizedBox(height: 8),
              Text('THE REAL ANSWER', style: displayFont(size: 18, color: Cave.success)),
              ArabicText(r.answer, style: displayFont(size: 36, color: Cave.success)),
            ],
          ),
        ),
        for (final o in options) _OptionResultTile(room: room, option: o),
        Panel(
          child: Column(
            children: [
              const Heading('LEADERBOARD 🏆'),
              const SizedBox(height: 8),
              ScoreBars(room: room, meId: s.playerId, deltas: r.deltas),
            ],
          ),
        ),
        if (s.isHost)
          GameButton(
            label: lastRound ? 'Final results' : 'Next round',
            icon: lastRound ? Icons.emoji_events_rounded : Icons.skip_next_rounded,
            kind: GameButtonKind.moss,
            onPressed: ref.read(gameProvider.notifier).nextRound,
          )
        else
          const Heading('Next round starts automatically…', size: 18),
      ],
    );
  }
}

class _OptionResultTile extends StatelessWidget {
  const _OptionResultTile({required this.room, required this.option});
  final RoomView room;
  final OptionResult option;

  @override
  Widget build(BuildContext context) {
    final fooled = option.voterIds.length;
    return Panel(
      color: option.isTruth ? const Color(0xFFD7EBA6) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ArabicText(option.text,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              if (option.isTruth)
                Text('✔ TRUTH', style: displayFont(size: 16, color: Cave.success))
              else if (fooled > 0)
                Text('+$fooled 😈', style: displayFont(size: 18, color: Cave.lava)),
            ],
          ),
          if (!option.isTruth) ...[
            const SizedBox(height: 8),
            Text(option.auto ? 'Auto-written 🤖 for:' : 'Written by:', style: displayFont(size: 15)),
            const SizedBox(height: 4),
            AvatarStack(room: room, ids: option.authorIds, showNames: true),
          ],
          const SizedBox(height: 8),
          Text(
            option.isTruth
                ? (option.voterIds.isEmpty ? 'Nobody found the truth 😮' : 'Found the truth (+2):')
                : (option.voterIds.isEmpty ? 'Nobody picked this one' : 'Picked by (fooled 😈):'),
            style: displayFont(size: 15, color: option.isTruth ? Cave.success : Cave.lava),
          ),
          if (option.voterIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            AvatarStack(room: room, ids: option.voterIds, showNames: true),
          ],
        ],
      ),
    );
  }
}
