import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../state/game_controller.dart';
import 'screens/answer_screen.dart';
import 'screens/choose_category_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/results_screen.dart';
import 'screens/vote_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/game_ui.dart';

/// Single-page "router": the screen is a pure function of the room phase,
/// so every client stays in lock-step with the server.
class GameShell extends ConsumerStatefulWidget {
  const GameShell({super.key});

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  Notice? _toast;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(Notice n) {
    _toastTimer?.cancel();
    setState(() => _toast = n);
    _toastTimer = Timer(const Duration(milliseconds: 3200), _hideToast);
  }

  void _hideToast() {
    if (mounted) setState(() => _toast = null);
  }

  void _celebrateCorrect() => showGameDialog<void>(
        context,
        emoji: '🎉',
        title: "That's the real answer!",
        message: 'Nice one, genius! Now change it to something sneaky to fool your friends 😈',
        actions: [
          GameButton(
            label: "On it!",
            kind: GameButtonKind.moss,
            compact: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(gameProvider.select((s) => s.notice), (prev, next) {
      if (next == null || identical(prev, next)) return;
      if (next.code == 'answer_is_correct') {
        _celebrateCorrect();
      } else {
        _showToast(next);
      }
    });

    final s = ref.watch(gameProvider);
    final room = s.room;
    final Widget body = room == null
        ? const HomeScreen()
        : switch (room.phase) {
            Phase.lobby => const LobbyScreen(),
            Phase.choosingCategory => const ChooseCategoryScreen(),
            Phase.answering => const AnswerScreen(),
            Phase.voting => const VoteScreen(),
            Phase.roundResults => const ResultsScreen(),
            Phase.gameOver => const GameOverScreen(),
          };

    return Scaffold(
      body: CaveBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  if (s.status == ConnStatus.reconnecting)
                    const LinearProgressIndicator(color: Cave.lava, minHeight: 5),
                  if (room != null) const _GameHeader(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: room?.paused ?? false,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: KeyedSubtree(
                                  key: ValueKey('${room?.phase}-${room?.round}'),
                                  child: body,
                                ),
                              ),
                            ),
                            if (room?.paused ?? false) _PausedOverlay(isHost: s.isHost),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _toast == null
                        ? const SizedBox.shrink()
                        : GameToast(key: ObjectKey(_toast), code: _toast!.code, onClose: _hideToast),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedOverlay extends ConsumerWidget {
  const _PausedOverlay({required this.isHost});
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Positioned.fill(
        child: ColoredBox(
          color: Cave.outline.withValues(alpha: 0.5),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Panel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⏸️', style: TextStyle(fontSize: 56)),
                    const Heading('GAME PAUSED', size: 30),
                    const SizedBox(height: 12),
                    if (isHost)
                      GameButton(
                        label: 'Resume',
                        icon: Icons.play_arrow_rounded,
                        kind: GameButtonKind.moss,
                        onPressed: ref.read(gameProvider.notifier).resume,
                      )
                    else
                      const Text('Waiting for the host to resume…'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Round counter, timer and round icon buttons (players, pause, leave).
class _GameHeader extends ConsumerWidget {
  const _GameHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider);
    final room = s.room!;
    final game = ref.read(gameProvider.notifier);
    final canPause = s.isHost && room.phase != Phase.lobby && room.phase != Phase.gameOver;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (room.round > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Cave.sand,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Cave.outline, width: 2.5),
              ),
              child: Text('ROUND ${room.round}/${room.totalRounds}', style: displayFont(size: 17)),
            ),
          const Spacer(),
          const Countdown(),
          const SizedBox(width: 6),
          _RoundIcon(
            icon: Icons.groups_rounded,
            tooltip: 'Players',
            color: Cave.sky,
            onTap: () => _showPlayers(context),
          ),
          if (canPause)
            _RoundIcon(
              icon: room.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              tooltip: room.paused ? 'Resume' : 'Pause',
              color: Cave.moss,
              onTap: room.paused ? game.resume : game.pause,
            ),
          _RoundIcon(
            icon: Icons.logout_rounded,
            tooltip: 'Leave',
            color: Cave.stone,
            onTap: () => _confirmLeave(context, ref),
          ),
        ],
      ),
    );
  }

  void _showPlayers(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Cave.cream,
        builder: (_) => Consumer(builder: (context, ref, _) {
          final s = ref.watch(gameProvider);
          final room = s.room;
          if (room == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            child: Scoreboard(
              room: room,
              meId: s.playerId,
              onKick: s.isHost ? (p) => confirmKick(context, ref, p) : null,
            ),
          );
        }),
      );

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final ok = await showGameDialog<bool>(
      context,
      emoji: '🚪',
      title: 'Leave the room?',
      actions: [
        GameButton(
            label: 'Stay', compact: true, kind: GameButtonKind.moss,
            onPressed: () => Navigator.pop(context, false)),
        GameButton(
            label: 'Leave', compact: true, kind: GameButtonKind.lava,
            onPressed: () => Navigator.pop(context, true)),
      ],
    );
    if (ok ?? false) ref.read(gameProvider.notifier).leave();
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tooltip, required this.color, required this.onTap});
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Tooltip(
          message: tooltip,
          child: Pressable3D(
            color: color,
            depth: 4,
            padding: const EdgeInsets.all(6),
            onTap: onTap,
            child: Icon(icon, color: Cave.ink, size: 22),
          ),
        ),
      );
}
