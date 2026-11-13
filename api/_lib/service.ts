import {
  DIFFICULTIES,
  GameError,
  GameRoom,
  QuestionBank,
  ROUND_OPTIONS,
  newRoomState,
  type Difficulty,
  type RoomState,
} from './engine';
import { buildQuestion, newQuestionId, requireAdmin } from './admin';
import { toWesternDigits } from './matching';
import { QUESTIONS } from './questions';
import type { Snapshot, Store } from './store';

const bank = new QuestionBank(QUESTIONS);

/** Admin-edited questions are re-read from storage at most this often. */
const QUESTIONS_TTL_MS = 30_000;
let questionsSync: { store: Store; at: number } | undefined;

/** Keeps the shared bank in step with the admin's edits. A storage hiccup keeps the last good copy. */
async function syncQuestions(store: Store, now: number, force = false): Promise<void> {
  if (!force && questionsSync?.store === store && now - questionsSync.at < QUESTIONS_TTL_MS) return;
  try {
    bank.setCustom(await store.listQuestions());
  } catch (e) {
    console.error('custom questions unavailable', e);
  }
  questionsSync = { store, at: now };
}

/** Presence is written at most this often per player to save Redis commands. */
const TOUCH_EVERY_MS = 4_000;

export type Message = { type?: unknown; pin?: unknown; token?: unknown; [k: string]: unknown };
export type Reply = { status: number; body: Record<string, unknown> };

const str = (v: unknown) => (typeof v === 'string' ? v : '');
/** PINs typed on an Arabic keyboard arrive as ٨٦٦٦٧٥. */
const pinOf = (v: unknown) => toWesternDigits(str(v)).trim();

/**
 * Handles one client request. Every successful reply carries the caller's
 * fresh RoomView so the UI updates without waiting for the next poll.
 */
export async function handle(msg: Message, store: Store, now = Date.now()): Promise<Reply> {
  try {
    switch (msg.type) {
      case 'create_room':
        return await createRoom(msg, store, now);
      case 'join_room':
        return await joinRoom(msg, store, now);
      case 'poll':
        await syncQuestions(store, now);
        return await poll(msg, store, now);
      case 'admin_list':
      case 'admin_save':
      case 'admin_delete':
        return await admin(msg, store, now);
      default:
        await syncQuestions(store, now);
        return await act(msg, store, now);
    }
  } catch (e) {
    if (e instanceof GameError) return { status: 400, body: { error: e.code } };
    throw e;
  }
}

/** Question management for the admin. Every call must carry the admin key. */
async function admin(msg: Message, store: Store, now: number): Promise<Reply> {
  requireAdmin(msg.adminKey);
  const builtIn = new Set(QUESTIONS.map((q) => q.id));
  if (msg.type === 'admin_save') {
    const given = str(msg.id);
    // Only brand-new ids (c_…) or built-in ids (to override them) may be written.
    if (given && !given.startsWith('c_') && !builtIn.has(given)) throw new GameError('unknown_question');
    await store.saveQuestion(buildQuestion(msg.question, given || newQuestionId()));
  } else if (msg.type === 'admin_delete') {
    const id = str(msg.id);
    if (!id.startsWith('c_') && !builtIn.has(id)) throw new GameError('unknown_question');
    await store.deleteQuestion(id);
  }
  // Admin calls always see fresh data and refresh the game's copy right away.
  const custom = await store.listQuestions();
  bank.setCustom(custom);
  questionsSync = { store, at: now };
  const customIds = new Set(custom.map((q) => q.id));
  const questions = bank.all().map((q) => ({
    ...q,
    source: !customIds.has(q.id) ? 'builtin' : builtIn.has(q.id) ? 'edited' : 'custom',
  }));
  return { status: 200, body: { questions } };
}

async function createRoom(msg: Message, store: Store, now: number): Promise<Reply> {
  const rounds = typeof msg.rounds === 'number' ? msg.rounds : 10;
  if (!ROUND_OPTIONS.includes(rounds)) throw new GameError('bad_rounds');
  const difficulty = (msg.difficulty ?? 'normal') as Difficulty;
  if (!DIFFICULTIES.includes(difficulty)) throw new GameError('bad_difficulty');
  for (let attempt = 0; attempt < 10; attempt++) {
    const pin = String(100000 + Math.floor(Math.random() * 900000));
    const room = new GameRoom(newRoomState(pin, rounds, difficulty), {}, now, bank);
    const me = room.addPlayer(str(msg.name));
    room.s.version = 1;
    if (await store.create(room.s)) {
      await store.touch(pin, me.id, now);
      return welcome(room, me.id, me.token);
    }
  }
  throw new Error('pin_space_exhausted');
}

async function joinRoom(msg: Message, store: Store, now: number): Promise<Reply> {
  const pin = pinOf(msg.pin);
  return store.withLock(pin, async () => {
    const room = await loadRoom(store, pin, now);
    room.tick();
    const me = room.addPlayer(str(msg.name));
    await commit(store, room);
    await store.touch(pin, me.id, now);
    return welcome(room, me.id, me.token);
  });
}

/** Read path. Only takes the lock if time has moved the game on. */
async function poll(msg: Message, store: Store, now: number): Promise<Reply> {
  const pin = pinOf(msg.pin);
  const snap = await store.load(pin);
  const meId = authenticate(snap, str(msg.token)).id;
  if (now - (snap.seen[meId] ?? 0) > TOUCH_EVERY_MS) {
    snap.seen[meId] = now;
    await store.touch(pin, meId, now);
  }
  const before = JSON.stringify(snap.state);
  const probe = new GameRoom(JSON.parse(before), snap.seen, now, bank);
  probe.tick();
  if (JSON.stringify(probe.s) === before) return view(probe, meId);

  return store.withLock(pin, async () => {
    const room = await loadRoom(store, pin, now, meId);
    room.tick();
    await commit(store, room);
    return view(room, meId);
  });
}

/** Authenticated game actions, applied under the room lock. */
async function act(msg: Message, store: Store, now: number): Promise<Reply> {
  const pin = pinOf(msg.pin);
  return store.withLock(pin, async () => {
    const snap = await store.load(pin);
    const me = authenticate(snap, str(msg.token));
    snap.seen[me.id] = now;
    await store.touch(pin, me.id, now);
    const room = openRoom(snap.state!, snap.seen, now);
    room.tick();
    try {
      switch (msg.type) {
        case 'start_game':
          room.startGame(me.id);
          break;
        case 'choose_category':
          room.chooseCategory(me.id, str(msg.category));
          break;
        case 'submit_answer':
          room.submitAnswer(me.id, str(msg.text));
          break;
        case 'vote':
          room.vote(me.id, str(msg.optionId));
          break;
        case 'kick':
          room.kick(me.id, str(msg.playerId));
          break;
        case 'next_round':
          room.nextRound(me.id);
          break;
        case 'restart':
          room.restart(me.id);
          break;
        case 'pause':
          room.pause(me.id);
          break;
        case 'resume':
          room.resume(me.id);
          break;
        case 'leave':
          room.leave(me.id);
          await commit(store, room);
          return { status: 200, body: { left: true } };
        default:
          throw new GameError('unknown_message');
      }
    } finally {
      // Persist tick() changes even when the action itself was rejected.
      await commit(store, room);
    }
    return view(room, me.id);
  });
}

async function loadRoom(store: Store, pin: string, now: number, meId?: string): Promise<GameRoom> {
  const snap = await store.load(pin);
  if (!snap.state) throw new GameError('room_not_found');
  if (meId) snap.seen[meId] = Math.max(snap.seen[meId] ?? 0, now);
  return openRoom(snap.state, snap.seen, now);
}

function authenticate(snap: Snapshot, token: string) {
  if (!snap.state) throw new GameError('room_not_found');
  const me = snap.state.players.find((p) => p.token === token);
  if (me) return me;
  throw new GameError(snap.state.kickedTokens.includes(token) ? 'kicked' : 'session_expired');
}

/** Last persisted JSON of each loaded state, so unchanged rooms aren't rewritten. */
const baselines = new WeakMap<RoomState, string>();

function openRoom(state: RoomState, seen: Record<string, number>, now: number): GameRoom {
  baselines.set(state, JSON.stringify(state));
  return new GameRoom(state, seen, now, bank);
}

/** Saves only if something changed, bumping the version clients use to order replies. */
async function commit(store: Store, room: GameRoom): Promise<void> {
  if (baselines.get(room.s) === JSON.stringify(room.s)) return;
  room.s.version++;
  await store.save(room.s);
  baselines.set(room.s, JSON.stringify(room.s));
}

function welcome(room: GameRoom, playerId: string, token: string): Reply {
  return { status: 200, body: { playerId, token, pin: room.s.pin, room: room.viewFor(playerId) } };
}

function view(room: GameRoom, playerId: string): Reply {
  return { status: 200, body: { playerId, room: room.viewFor(playerId) } };
}
