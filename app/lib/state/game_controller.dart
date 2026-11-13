import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../net/game_api.dart';

enum ConnStatus { idle, connecting, online, reconnecting }

/// One-off event for the UI (snackbar / dialog). New instance = new event.
class Notice {
  Notice(this.code);
  final String code;
}

@immutable
class ClientState {
  const ClientState({
    this.status = ConnStatus.idle,
    this.playerId,
    this.room,
    this.notice,
    this.clockOffsetMs = 0,
  });

  final ConnStatus status;
  final String? playerId;

  /// Latest snapshot from the server. Null = not in a room (home screen).
  final RoomView? room;
  final Notice? notice;

  /// serverTime - localTime, so countdowns match the server's deadlines.
  final int clockOffsetMs;

  bool get isHost => room != null && room!.hostId == playerId;
  PlayerView? get me => room?.player(playerId);

  ClientState copyWith({
    ConnStatus? status,
    String? playerId,
    RoomView? room,
    Notice? notice,
    int? clockOffsetMs,
  }) =>
      ClientState(
        status: status ?? this.status,
        playerId: playerId ?? this.playerId,
        room: room ?? this.room,
        notice: notice ?? this.notice,
        clockOffsetMs: clockOffsetMs ?? this.clockOffsetMs,
      );
}

final gameProvider =
    NotifierProvider<GameController, ClientState>(GameController.new);

/// The server is the source of truth: actions are POSTed and the UI only
/// changes when a [RoomView] comes back, either as the action's reply or
/// from the background poll that keeps every player in sync.
class GameController extends Notifier<ClientState> {
  static const _pinKey = 'session.pin';
  static const _tokenKey = 'session.token';
  static const _pollEvery = Duration(milliseconds: 1500);

  final _api = GameApi(apiUri());
  ({String pin, String token})? _session;
  Timer? _poller;
  bool _polling = false;
  int _failures = 0;

  @override
  ClientState build() {
    ref.onDispose(() => _poller?.cancel());
    Future.microtask(_restoreSession);
    return const ClientState();
  }

  // ------------------------------------------------------------ user actions

  Future<void> createRoom(String name, int rounds, String difficulty) => _join({
        'type': Msg.createRoom,
        'name': name,
        'rounds': rounds,
        'difficulty': difficulty,
      });

  Future<void> joinRoom(String pin, String name) =>
      _join({'type': Msg.joinRoom, 'pin': pin.trim(), 'name': name});

  void startGame() => _act({'type': Msg.startGame});
  void chooseCategory(Category c) =>
      _act({'type': Msg.chooseCategory, 'category': c.name});
  void submitAnswer(String text) => _act({'type': Msg.submitAnswer, 'text': text});
  void vote(String optionId) => _act({'type': Msg.vote, 'optionId': optionId});
  void kick(String playerId) => _act({'type': Msg.kick, 'playerId': playerId});
  void nextRound() => _act({'type': Msg.nextRound});
  void restart() => _act({'type': Msg.restart});
  void pause() => _act({'type': Msg.pause});
  void resume() => _act({'type': Msg.resume});

  void leave() {
    _act({'type': Msg.leave});
    _clearSession();
    state = ClientState(status: state.status);
  }

  // -------------------------------------------------------------- transport

  Future<void> _join(Map<String, Object?> msg) async {
    state = state.copyWith(status: ConnStatus.connecting);
    try {
      _apply(await _api.send(msg));
    } catch (_) {
      state = state.copyWith(status: ConnStatus.idle, notice: Notice('connection_failed'));
    }
  }

  Future<void> _act(Map<String, Object?> msg) async {
    final s = _session;
    if (s == null) return;
    try {
      _apply(await _api.send({'pin': s.pin, 'token': s.token, ...msg}));
    } catch (_) {
      state = state.copyWith(notice: Notice('connection_failed'));
    }
  }

  Future<void> _poll() async {
    final s = _session;
    if (s == null || _polling) return;
    _polling = true;
    try {
      _apply(await _api.send({'type': Msg.poll, 'pin': s.pin, 'token': s.token}));
      _failures = 0;
    } catch (_) {
      if (++_failures >= 3) state = state.copyWith(status: ConnStatus.reconnecting);
    } finally {
      _polling = false;
    }
  }

  void _apply(Map<String, dynamic> reply) {
    final error = reply['error'] as String?;
    if (error != null) {
      // The seat is gone (kicked, room expired): forget it and go home.
      if (error == 'kicked' ||
          error == 'session_expired' ||
          (error == 'room_not_found' && _session != null)) {
        _clearSession();
        state = ClientState(notice: Notice(error));
      } else {
        state = state.copyWith(status: ConnStatus.online, notice: Notice(error));
      }
      return;
    }
    final token = reply['token'] as String?;
    if (token != null) _saveSession(reply['pin'] as String, token);
    final json = reply['room'] as Map<String, dynamic>?;
    if (json == null) return;
    final room = RoomView.fromJson(json);
    final current = state.room;
    // Polls and action replies can overtake each other; never go backwards.
    if (current != null && current.pin == room.pin && room.version < current.version) {
      return;
    }
    state = state.copyWith(
      status: ConnStatus.online,
      playerId: reply['playerId'] as String?,
      room: room,
      clockOffsetMs: room.serverNowMs - DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ---------------------------------------------- session (survives refresh)

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    final token = prefs.getString(_tokenKey);
    if (pin == null || token == null) return;
    _startSession(pin, token);
    state = state.copyWith(status: ConnStatus.reconnecting);
    await _poll();
  }

  void _startSession(String pin, String token) {
    _session = (pin: pin, token: token);
    _poller?.cancel();
    _poller = Timer.periodic(_pollEvery, (_) => _poll());
  }

  void _saveSession(String pin, String token) {
    _startSession(pin, token);
    SharedPreferences.getInstance().then((p) => p
      ..setString(_pinKey, pin)
      ..setString(_tokenKey, token));
  }

  void _clearSession() {
    _session = null;
    _poller?.cancel();
    _poller = null;
    SharedPreferences.getInstance().then((p) => p
      ..remove(_pinKey)
      ..remove(_tokenKey));
  }
}
