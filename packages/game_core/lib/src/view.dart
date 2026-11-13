import 'models.dart';

/// What one specific player is allowed to see. Built by the server per player
/// (`viewFor` in api/_lib/engine.ts) so hidden information never leaves it early.
class RoomView {
  const RoomView({
    required this.version,
    required this.pin,
    required this.phase,
    required this.round,
    required this.totalRounds,
    required this.difficulty,
    required this.paused,
    required this.minPlayers,
    required this.maxAnswerLength,
    required this.hostId,
    required this.chooserId,
    required this.category,
    required this.players,
    required this.questionText,
    required this.questionImage,
    required this.myAnswer,
    required this.options,
    required this.myVote,
    required this.availableCategories,
    required this.result,
    required this.deadlineMs,
    required this.serverNowMs,
  });

  factory RoomView.fromJson(Map<String, dynamic> j) => RoomView(
        version: j['version'] as int,
        pin: j['pin'] as String,
        phase: Phase.values.byName(j['phase'] as String),
        round: j['round'] as int,
        totalRounds: j['totalRounds'] as int,
        difficulty: j['difficulty'] as String? ?? 'normal',
        paused: j['paused'] as bool? ?? false,
        minPlayers: j['minPlayers'] as int,
        maxAnswerLength: j['maxAnswerLength'] as int,
        hostId: j['hostId'] as String?,
        chooserId: j['chooserId'] as String?,
        category: j['category'] == null
            ? null
            : Category.values.byName(j['category'] as String),
        players: [
          for (final p in j['players'] as List)
            PlayerView.fromJson(p as Map<String, dynamic>)
        ],
        questionText: j['questionText'] as String?,
        questionImage: j['questionImage'] as String?,
        myAnswer: j['myAnswer'] as String?,
        options: [
          for (final o in j['options'] as List)
            OptionView.fromJson(o as Map<String, dynamic>)
        ],
        myVote: j['myVote'] as String?,
        availableCategories: [
          for (final c in j['availableCategories'] as List)
            Category.values.byName(c as String)
        ],
        result: j['result'] == null
            ? null
            : RoundResult.fromJson(j['result'] as Map<String, dynamic>),
        deadlineMs: j['deadlineMs'] as int?,
        serverNowMs: j['serverNowMs'] as int,
      );

  /// Increases with every server-side change; used to drop stale replies.
  final int version;
  final String pin;
  final Phase phase;
  final int round;
  final int totalRounds;

  /// 'normal' or 'hard'.
  final String difficulty;

  /// Host froze the game: timers stop and play actions are refused.
  final bool paused;
  final int minPlayers;
  final int maxAnswerLength;
  final String? hostId;
  final String? chooserId;
  final Category? category;
  final List<PlayerView> players;
  final String? questionText;
  final String? questionImage;
  final String? myAnswer;
  final List<OptionView> options;
  final String? myVote;
  final List<Category> availableCategories;
  final RoundResult? result;
  final int? deadlineMs;
  final int serverNowMs;

  PlayerView? player(String? id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'version': version,
        'pin': pin,
        'phase': phase.name,
        'round': round,
        'totalRounds': totalRounds,
        'difficulty': difficulty,
        'paused': paused,
        'minPlayers': minPlayers,
        'maxAnswerLength': maxAnswerLength,
        'hostId': hostId,
        'chooserId': chooserId,
        'category': category?.name,
        'players': [for (final p in players) p.toJson()],
        'questionText': questionText,
        'questionImage': questionImage,
        'myAnswer': myAnswer,
        'options': [for (final o in options) o.toJson()],
        'myVote': myVote,
        'availableCategories': [for (final c in availableCategories) c.name],
        'result': result?.toJson(),
        'deadlineMs': deadlineMs,
        'serverNowMs': serverNowMs,
      };
}

class PlayerView {
  const PlayerView({
    required this.id,
    required this.name,
    required this.avatar,
    required this.score,
    required this.connected,
    required this.submitted,
    required this.voted,
  });

  factory PlayerView.fromJson(Map<String, dynamic> j) => PlayerView(
        id: j['id'] as String,
        name: j['name'] as String,
        avatar: j['avatar'] as int,
        score: j['score'] as int,
        connected: j['connected'] as bool,
        submitted: j['submitted'] as bool,
        voted: j['voted'] as bool,
      );

  final String id;
  final String name;
  final int avatar;
  final int score;
  final bool connected;
  final bool submitted;
  final bool voted;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'score': score,
        'connected': connected,
        'submitted': submitted,
        'voted': voted,
      };
}

/// An anonymous answer shown during voting. [mine] is only true for the author.
class OptionView {
  const OptionView({required this.id, required this.text, required this.mine});

  factory OptionView.fromJson(Map<String, dynamic> j) => OptionView(
      id: j['id'] as String, text: j['text'] as String, mine: j['mine'] as bool);

  final String id;
  final String text;
  final bool mine;

  Map<String, Object?> toJson() => {'id': id, 'text': text, 'mine': mine};
}

class OptionResult {
  const OptionResult({
    required this.id,
    required this.text,
    required this.isTruth,
    this.auto = false,
    required this.authorIds,
    required this.voterIds,
  });

  factory OptionResult.fromJson(Map<String, dynamic> j) => OptionResult(
        id: j['id'] as String,
        text: j['text'] as String,
        isTruth: j['isTruth'] as bool,
        auto: j['auto'] as bool? ?? false,
        authorIds: (j['authorIds'] as List).cast<String>(),
        voterIds: (j['voterIds'] as List).cast<String>(),
      );

  final String id;
  final String text;
  final bool isTruth;

  /// Written by the game for a player who ran out of time.
  final bool auto;
  final List<String> authorIds;
  final List<String> voterIds;

  Map<String, Object?> toJson() => {
        'id': id,
        'text': text,
        'isTruth': isTruth,
        'auto': auto,
        'authorIds': authorIds,
        'voterIds': voterIds,
      };
}

class RoundResult {
  const RoundResult({
    required this.questionText,
    required this.answer,
    required this.options,
    required this.deltas,
  });

  factory RoundResult.fromJson(Map<String, dynamic> j) => RoundResult(
        questionText: j['questionText'] as String,
        answer: j['answer'] as String,
        options: [
          for (final o in j['options'] as List)
            OptionResult.fromJson(o as Map<String, dynamic>)
        ],
        deltas: (j['deltas'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
      );

  final String questionText;
  final String answer;
  final List<OptionResult> options;

  /// Points gained this round, by player id.
  final Map<String, int> deltas;

  Map<String, Object?> toJson() => {
        'questionText': questionText,
        'answer': answer,
        'options': [for (final o in options) o.toJson()],
        'deltas': deltas,
      };
}
