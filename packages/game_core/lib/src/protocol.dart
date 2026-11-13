/// `type` values POSTed to /api/game. Every request is a JSON object; every
/// reply is `{playerId, room: RoomView}` (plus `token`, `pin` on join) or `{error}`.
abstract final class Msg {
  static const createRoom = 'create_room'; // {name, rounds}
  static const joinRoom = 'join_room'; // {pin, name}
  static const poll = 'poll'; // {pin, token}
  static const leave = 'leave';
  static const startGame = 'start_game';
  static const chooseCategory = 'choose_category'; // {category}
  static const submitAnswer = 'submit_answer'; // {text}
  static const vote = 'vote'; // {optionId}
  static const kick = 'kick'; // {playerId}
  static const nextRound = 'next_round';
  static const restart = 'restart';
  static const pause = 'pause';
  static const resume = 'resume';
}

const allowedRoundCounts = [10, 15, 20];
const allowedDifficulties = ['normal', 'hard'];
