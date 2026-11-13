import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';

class VoteScreen extends ConsumerWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(gameProvider).room!;
    final game = ref.read(gameProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        QuestionCard(room: room),
        const Heading("WHICH ONE IS REAL? 🤔", size: 24),
        const SizedBox(height: 12),
        for (final o in room.options)
          Pressable3D(
            color: room.myVote == o.id ? Cave.gold : (o.mine ? Cave.stone : Colors.white),
            onTap: o.mine ? null : () => game.vote(o.id),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                if (room.myVote == o.id) const Text('👉 ', style: TextStyle(fontSize: 22)),
                Expanded(
                  child: ArabicText(o.text,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                if (o.mine) Text(' YOURS', style: displayFont(size: 14, color: Cave.outline)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        WaitingRow(isDone: (p) => p.voted),
      ],
    );
  }
}
