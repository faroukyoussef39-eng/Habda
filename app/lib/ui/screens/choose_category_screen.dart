import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/sheep_avatar.dart';

class ChooseCategoryScreen extends ConsumerWidget {
  const ChooseCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider);
    final room = s.room!;
    final chooser = room.player(room.chooserId);

    if (room.chooserId != s.playerId) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chooser != null) SheepAvatar(index: chooser.avatar, size: 140),
            const SizedBox(height: 16),
            Heading('${chooser?.name ?? '…'} is picking a category…', size: 24),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Heading('YOUR TURN! PICK A CATEGORY 🎯', size: 28),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final c in Category.values)
              GameTile(
                icon: c.icon,
                label: c.label,
                color: c.color,
                onTap: room.availableCategories.contains(c)
                    ? () => ref.read(gameProvider.notifier).chooseCategory(c)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
