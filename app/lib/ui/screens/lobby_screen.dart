import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config.dart';
import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider);
    final room = s.room!;
    final online = room.players.where((p) => p.connected).length;
    final canStart = online >= room.minPlayers;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ROOM PIN', style: displayFont(size: 18, color: Cave.outline)),
                  SelectableText(room.pin, style: displayFont(size: 48).copyWith(letterSpacing: 6)),
                  Text('or scan to join 📱', style: displayFont(size: 16, color: Cave.outline)),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Cave.outline, width: 3),
                ),
                child: QrImageView(data: joinUrlFor(room.pin), size: 160),
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            children: [
              Heading('PLAYERS (${room.players.length})'),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 18,
                children: [
                  for (final p in room.players)
                    PlayerTile(
                      player: p,
                      isHost: p.id == room.hostId,
                      isMe: p.id == s.playerId,
                      onKick: s.isHost && p.id != s.playerId ? () => confirmKick(context, ref, p) : null,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (s.isHost)
          GameButton(
            label: canStart ? 'Start!' : 'Need ${room.minPlayers} players',
            subtitle: '${room.totalRounds} rounds • ${difficultyLabel(room.difficulty)}',
            icon: canStart ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
            kind: GameButtonKind.moss,
            onPressed: canStart ? ref.read(gameProvider.notifier).startGame : null,
          )
        else
          const Heading('Waiting for the host to start… ⏳', size: 20),
      ],
    );
  }
}
