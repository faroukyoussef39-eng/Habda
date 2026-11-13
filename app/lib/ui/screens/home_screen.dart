import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/sheep_avatar.dart';
import 'admin_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _name = TextEditingController();

  /// Scanning the lobby QR opens `/?pin=123456`, so the PIN is prefilled.
  final _pin = TextEditingController(text: Uri.base.queryParameters['pin'] ?? '');
  int _rounds = allowedRoundCounts.first;
  String _difficulty = allowedDifficulties.first;
  String? _nameError;
  String? _pinError;

  /// Secret admin entry: tapping the logo 5 times within a few seconds.
  int _logoTaps = 0;
  DateTime _lastLogoTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _tapLogo() {
    final now = DateTime.now();
    _logoTaps = now.difference(_lastLogoTap) > const Duration(seconds: 2) ? 1 : _logoTaps + 1;
    _lastLogoTap = now;
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      openAdminEntry(context);
    }
  }

  GameController get _game => ref.read(gameProvider.notifier);

  bool _validName() {
    final ok = _name.text.trim().isNotEmpty;
    setState(() => _nameError = ok ? null : 'Name is required');
    return ok;
  }

  void _join() {
    final pinOk = RegExp(r'^\d{6}$').hasMatch(_pin.text.trim());
    setState(() => _pinError = pinOk ? null : 'Enter the 6-digit PIN');
    // Validate both so every missing field lights up at once.
    if (_validName() && pinOk) _game.joinRoom(_pin.text, _name.text);
  }

  void _create() {
    if (_validName()) _game.createRoom(_name.text, _rounds, _difficulty);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(gameProvider.select((s) => s.status == ConnStatus.connecting));
    final hasInvite = Uri.base.queryParameters.containsKey('pin');

    final join = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Heading('JOIN A ROOM'),
          const SizedBox(height: 12),
          TextField(
            controller: _pin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: const [WesternDigitsFormatter()],
            textAlign: TextAlign.center,
            style: displayFont(size: 30).copyWith(letterSpacing: 8),
            decoration: InputDecoration(hintText: 'PIN', counterText: '', errorText: _pinError),
            onChanged: (_) {
              if (_pinError != null) setState(() => _pinError = null);
            },
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 14),
          GameButton(label: 'Join', icon: Icons.login_rounded, onPressed: busy ? null : _join),
        ],
      ),
    );

    final create = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Heading('CREATE A ROOM'),
          const SizedBox(height: 12),
          Text('Rounds', style: displayFont(size: 16)),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: [
              for (final n in allowedRoundCounts) ButtonSegment(value: n, label: Text('$n')),
            ],
            selected: {_rounds},
            onSelectionChanged: (s) => setState(() => _rounds = s.first),
          ),
          const SizedBox(height: 12),
          Text('Question level', style: displayFont(size: 16)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              for (final d in allowedDifficulties) ButtonSegment(value: d, label: Text(difficultyLabel(d))),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 14),
          GameButton(
            label: 'Create room',
            icon: Icons.add_rounded,
            kind: GameButtonKind.lava,
            onPressed: busy ? null : _create,
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [for (var i = 0; i < 6; i++) SheepAvatar(index: i, size: 52)],
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tapLogo,
            child: const GameLogo(size: 64),
          ),
        ),
        Text('Fake it. Fool them. Find the truth!',
            textAlign: TextAlign.center, style: displayFont(size: 18, color: Cave.outline)),
        const SizedBox(height: 20),
        Panel(
          child: TextField(
            controller: _name,
            maxLength: 16,
            inputFormatters: const [WesternDigitsFormatter()],
            decoration: InputDecoration(
              labelText: 'Your name *',
              prefixIcon: const Icon(Icons.person_rounded),
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
        ),
        if (hasInvite) ...[join, create] else ...[create, join],
      ],
    );
  }
}
