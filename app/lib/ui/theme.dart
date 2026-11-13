import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cartoon cave-adventure palette: sunset sky, sandstone, wood, lava, moss.
abstract final class Cave {
  static const skyTop = Color(0xFF86C2CB);
  static const skyMist = Color(0xFFD6E6DC);
  static const skyPeach = Color(0xFFF6D2B2);
  static const skyPink = Color(0xFFF3B0A2);

  static const sand = Color(0xFFF3C77F);
  static const lava = Color(0xFFC8402F);
  static const moss = Color(0xFFC9D84A);
  static const stone = Color(0xFFD9D2C8);
  static const sky = Color(0xFF4FA3D1);

  static const cream = Color(0xFFFFF1D6);
  static const outline = Color(0xFF4A2E17);
  static const ink = Color(0xFF3B2414);
  static const gold = Color(0xFFFFC233);
  static const success = Color(0xFF6E9E1E);

  /// Darker shade used for the 3D "edge" under buttons and panels.
  static Color edge(Color c) => Color.lerp(c, Colors.black, 0.32)!;
}

/// Chunky display font for English titles and buttons.
TextStyle displayFont({double size = 24, Color color = Cave.ink}) =>
    GoogleFonts.lilitaOne(fontSize: size, color: color, height: 1.1);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Cave.sand,
    primary: Cave.success,
    secondary: Cave.gold,
    error: Cave.lava,
    surface: Cave.cream,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    // Baloo Bhaijaan 2 is rounded and playful and covers Arabic questions too.
    textTheme: GoogleFonts.balooBhaijaan2TextTheme(base.textTheme).apply(
      bodyColor: Cave.ink,
      displayColor: Cave.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cave.outline, width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cave.success, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cave.lava, width: 3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cave.lava, width: 3),
      ),
      errorStyle: const TextStyle(color: Cave.lava, fontWeight: FontWeight.w800),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        selectedBackgroundColor: Cave.moss,
        selectedForegroundColor: Cave.ink,
        side: const BorderSide(color: Cave.outline, width: 2),
        textStyle: GoogleFonts.lilitaOne(fontSize: 16),
      ),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide(color: Cave.outline, width: 2),
      shape: StadiumBorder(),
    ),
  );
}

extension CategoryStyle on Category {
  String get label => switch (this) {
        Category.history => 'History',
        Category.literature => 'Literature',
        Category.football => 'Football',
        Category.movies => 'Movies',
        Category.flags => 'World Flags',
        Category.songs => 'Egyptian Songs',
        Category.geography => 'Geography',
        Category.cars => 'Cars',
        Category.whoPlayer => "Who's the Player?",
        Category.whoCelebrity => "Who's the Celebrity?",
      };

  IconData get icon => switch (this) {
        Category.history => Icons.account_balance_rounded,
        Category.literature => Icons.menu_book_rounded,
        Category.football => Icons.sports_soccer_rounded,
        Category.movies => Icons.movie_rounded,
        Category.flags => Icons.flag_rounded,
        Category.songs => Icons.music_note_rounded,
        Category.geography => Icons.public_rounded,
        Category.cars => Icons.directions_car_rounded,
        Category.whoPlayer => Icons.person_search_rounded,
        Category.whoCelebrity => Icons.star_rounded,
      };

  Color get color => switch (this) {
        Category.history => const Color(0xFFC08A4E),
        Category.literature => const Color(0xFF8E6CC7),
        Category.football => const Color(0xFF7DA62B),
        Category.movies => Cave.lava,
        Category.flags => Cave.sky,
        Category.songs => const Color(0xFFE0568F),
        Category.geography => const Color(0xFF2E9C8F),
        Category.cars => const Color(0xFF5B6B7C),
        Category.whoPlayer => const Color(0xFF3F7FBF),
        Category.whoCelebrity => Cave.gold,
      };
}

/// Every question is challenging now; 'normal' rooms get hard ones, 'hard' rooms expert ones.
String difficultyLabel(String d) => d == 'hard' ? 'Expert 💀' : 'Hard 🔥';

/// Converts ٠-٩ / ۰-۹ typed on Arabic keyboards to 0-9 as the user types.
class WesternDigitsFormatter extends TextInputFormatter {
  const WesternDigitsFormatter();

  static String convert(String s) => s.replaceAllMapped(
      RegExp('[٠-٩۰-۹]'),
      (m) => '${(m[0]!.codeUnitAt(0) - (m[0]!.codeUnitAt(0) >= 0x06F0 ? 0x06F0 : 0x0660))}');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: convert(newValue.text));
}

/// Emoji + friendly text for each server code, shown in the game toast.
({String emoji, String text, bool info}) noticeFor(String code) => switch (code) {
      'room_not_found' => (emoji: '🔍', text: 'Hmm… no room with that PIN', info: false),
      'game_in_progress' => (emoji: '⏳', text: 'Too late! That game already started', info: false),
      'room_full' => (emoji: '🚪', text: "Room's packed! No space left", info: false),
      'name_empty' => (emoji: '✍️', text: 'Hey! Tell us your name first', info: false),
      'not_enough_players' => (emoji: '👥', text: 'Grab more friends to start!', info: false),
      'answer_empty' => (emoji: '✍️', text: 'Write something first!', info: false),
      'answer_too_long' => (emoji: '📏', text: 'Whoa, keep it shorter!', info: false),
      'answer_not_arabic' => (emoji: '🔤', text: 'Arabic answers only, please!', info: false),
      'already_submitted' => (emoji: '🔒', text: 'Locked in! No take-backs', info: true),
      'game_paused' => (emoji: '⏸️', text: "Game's on pause", info: true),
      'cannot_vote_own' => (emoji: '🙈', text: "Nice try! You can't vote for your own answer", info: false),
      'not_host' => (emoji: '👑', text: 'Only the host can do that', info: false),
      'not_your_turn' => (emoji: '✋', text: 'Not your turn to pick!', info: false),
      'wrong_phase' => (emoji: '🐢', text: 'Too late for that!', info: false),
      'kicked' => (emoji: '👢', text: 'The host kicked you out', info: false),
      'session_expired' => (emoji: '⌛', text: 'Your session expired. Jump back in!', info: true),
      'session_replaced' => (emoji: '📱', text: 'You opened the game in another tab', info: true),
      'connection_failed' => (emoji: '📡', text: "Can't reach the server. Check your internet", info: false),
      'storage_not_configured' => (emoji: '🛠️', text: "Server storage isn't set up yet", info: false),
      _ => (emoji: '😬', text: 'Oops! Something went wrong ($code)', info: false),
    };
