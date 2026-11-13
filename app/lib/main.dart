import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/game_shell.dart';
import 'ui/theme.dart';

void main() => runApp(const ProviderScope(child: BluffApp()));

/// UI is English (left-to-right); only questions and answers are Arabic,
/// rendered right-to-left where they appear.
class BluffApp extends StatelessWidget {
  const BluffApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bluff Party',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const GameShell(),
      );
}
