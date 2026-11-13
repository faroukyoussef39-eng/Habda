import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';

class AnswerScreen extends ConsumerStatefulWidget {
  const AnswerScreen({super.key});

  @override
  ConsumerState<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends ConsumerState<AnswerScreen> {
  final _text = TextEditingController();

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final ok = await showGameDialog<bool>(
      context,
      emoji: '🤔',
      title: 'Lock it in?',
      content: ArabicText('«$text»', style: displayFont(size: 22)),
      message: "You can't change it after sending.",
      actions: [
        GameButton(
            label: 'Wait', compact: true, kind: GameButtonKind.stone,
            onPressed: () => Navigator.pop(context, false)),
        GameButton(
            label: 'Send', compact: true, kind: GameButtonKind.moss,
            onPressed: () => Navigator.pop(context, true)),
      ],
    );
    // If this is the real answer the server rejects it with
    // 'answer_is_correct' and GameShell shows the "change it" dialog.
    if (ok ?? false) ref.read(gameProvider.notifier).submitAnswer(text);
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(gameProvider).room!;
    final sent = room.myAnswer;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        QuestionCard(room: room),
        Panel(
          child: sent == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Heading('WRITE A FAKE ANSWER 😈', size: 22),
                    const Text(
                      "Answer in Arabic to fool your friends. Out of time? We'll write one for you 🤖",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _text,
                      autofocus: true,
                      maxLength: room.maxAnswerLength,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      inputFormatters: const [WesternDigitsFormatter()],
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                    ),
                    GameButton(label: 'Send', icon: Icons.send_rounded, kind: GameButtonKind.moss, onPressed: _submit),
                  ],
                )
              : Column(
                  children: [
                    const Heading('LOCKED IN ✅', size: 22),
                    ArabicText(sent, style: displayFont(size: 26)),
                  ],
                ),
        ),
        const Heading('Waiting for everyone…', size: 18),
        const SizedBox(height: 8),
        WaitingRow(isDone: (p) => p.submitted),
      ],
    );
  }
}
