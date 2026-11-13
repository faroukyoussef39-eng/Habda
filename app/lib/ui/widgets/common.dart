import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../state/game_controller.dart';
import '../theme.dart';
import 'game_ui.dart';
import 'sheep_avatar.dart';

/// Carved parchment card used for every content block.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color = Cave.cream});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(color: Cave.outline, width: 3),
          boxShadow: [
            BoxShadow(color: Cave.edge(Cave.sand), offset: const Offset(0, 6)),
            const BoxShadow(color: Cave.outline, offset: Offset(0, 9)),
          ],
        ),
        child: child,
      );
}

/// Section heading in the chunky display font.
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.size = 26});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: TextAlign.center, style: displayFont(size: size));
}

/// Arabic game content (questions, answers) inside the English UI.
class ArabicText extends StatelessWidget {
  const ArabicText(this.text, {super.key, this.style, this.textAlign = TextAlign.center});
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) =>
      Text(text, textDirection: TextDirection.rtl, textAlign: textAlign, style: style);
}

/// Seconds left until the server deadline for the current phase.
class Countdown extends ConsumerStatefulWidget {
  const Countdown({super.key});

  @override
  ConsumerState<Countdown> createState() => _CountdownState();
}

class _CountdownState extends ConsumerState<Countdown> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider);
    final deadline = s.room?.deadlineMs;
    if (deadline == null) return const SizedBox.shrink();
    final serverNow = DateTime.now().millisecondsSinceEpoch + s.clockOffsetMs;
    final secs = ((deadline - serverNow) / 1000).ceil().clamp(0, 999);
    final urgent = secs <= 5;
    return AnimatedScale(
      scale: urgent && secs.isOdd ? 1.12 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: urgent ? Cave.lava : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Cave.outline, width: 2.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(urgent ? '⏰' : '⏳', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('$secs', style: displayFont(size: 20, color: urgent ? Colors.white : Cave.ink)),
        ]),
      ),
    );
  }
}

/// Avatar + name, with optional host crown, status tick and kick button.
class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.player,
    this.isHost = false,
    this.isMe = false,
    this.done = false,
    this.onKick,
    this.size = 72,
  });

  final PlayerView player;
  final bool isHost;
  final bool isMe;
  final bool done;
  final VoidCallback? onKick;
  final double size;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: player.connected ? 1 : 0.4,
        child: SizedBox(
          width: size + 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SheepAvatar(index: player.avatar, size: size),
                  if (isHost)
                    const Positioned(
                      top: -14,
                      left: 0,
                      right: 0,
                      child: Text('👑', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                    ),
                  if (done)
                    const Positioned(
                      bottom: -2,
                      right: -2,
                      child: Text('✅', style: TextStyle(fontSize: 20)),
                    ),
                  if (onKick != null)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Tooltip(
                        message: 'Kick',
                        child: GestureDetector(
                          onTap: onKick,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Cave.lava,
                              shape: BoxShape.circle,
                              border: Border.all(color: Cave.outline, width: 2),
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isMe ? '${player.name} (you)' : player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
}

/// Row of players showing who has finished the current step. The host gets a
/// kick button on everyone else, so moderation works mid-round too.
class WaitingRow extends ConsumerWidget {
  const WaitingRow({super.key, required this.isDone});
  final bool Function(PlayerView) isDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider);
    final room = s.room!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in room.players)
          PlayerTile(
            player: p,
            done: isDone(p),
            size: 48,
            isHost: p.id == room.hostId,
            isMe: p.id == s.playerId,
            onKick: s.isHost && p.id != s.playerId ? () => confirmKick(context, ref, p) : null,
          ),
      ],
    );
  }
}

/// Avatars for a list of player ids; with [showNames] each one is labelled.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.room, required this.ids, this.showNames = false});
  final RoomView room;
  final List<String> ids;
  final bool showNames;

  @override
  Widget build(BuildContext context) {
    final players = [for (final id in ids) room.player(id)].nonNulls.toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in players)
          showNames
              ? Container(
                  padding: const EdgeInsets.fromLTRB(2, 2, 10, 2),
                  decoration: BoxDecoration(
                    color: Cave.cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Cave.outline, width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SheepAvatar(index: p.avatar, size: 26),
                    const SizedBox(width: 4),
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                )
              : Tooltip(message: p.name, child: SheepAvatar(index: p.avatar, size: 32)),
      ],
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.room});
  final RoomView room;

  @override
  Widget build(BuildContext context) {
    final cat = room.category;
    return Panel(
      color: Colors.white,
      child: Column(
        children: [
          if (cat != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Cave.outline, width: 2.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat.icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(cat.label.toUpperCase(), style: displayFont(size: 15, color: Colors.white)),
              ]),
            ),
          const SizedBox(height: 12),
          if (room.questionImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Cave.outline, width: 3)),
                child: Image.network(
                  room.questionImage!,
                  height: 140,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          ArabicText(
            room.questionText ?? '',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Plain leaderboard used in the players sheet. [onKick] enables host
/// moderation for everyone except the host.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.room, required this.meId, this.onKick});

  final RoomView room;
  final String? meId;
  final void Function(PlayerView)? onKick;

  @override
  Widget build(BuildContext context) {
    final sorted = [...room.players]..sort((a, b) => b.score.compareTo(a.score));
    return Column(
      children: [
        for (final (i, p) in sorted.indexed)
          ListTile(
            leading: SheepAvatar(index: p.avatar, size: 40),
            title: Text(
              '${i + 1}. ${p.name}${p.id == meId ? ' (you)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: p.connected ? null : const Text('offline'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${p.score}', style: displayFont(size: 22)),
                if (onKick != null && p.id != room.hostId)
                  IconButton(
                    tooltip: 'Kick',
                    icon: const Icon(Icons.person_remove_rounded, color: Cave.lava),
                    onPressed: () => onKick!(p),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<void> confirmKick(BuildContext context, WidgetRef ref, PlayerView p) async {
  final ok = await showGameDialog<bool>(
    context,
    emoji: '👢',
    title: 'Kick ${p.name}?',
    actions: [
      GameButton(
          label: 'No', compact: true, kind: GameButtonKind.stone,
          onPressed: () => Navigator.pop(context, false)),
      GameButton(
          label: 'Kick', compact: true, kind: GameButtonKind.lava,
          onPressed: () => Navigator.pop(context, true)),
    ],
  );
  if (ok ?? false) ref.read(gameProvider.notifier).kick(p.id);
}
