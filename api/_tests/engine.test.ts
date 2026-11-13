import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';

import {
  CATEGORIES,
  GameError,
  GameRoom,
  QuestionBank,
  matchesQuestion,
  newRoomState,
  type PlayerState,
  type Question,
} from '../_lib/engine';
import { answersMatch, hasLatinLetters, normalizeAnswer } from '../_lib/matching';
import { QUESTIONS } from '../_lib/questions';

const bank = new QuestionBank([
  { id: 'h1', category: 'history', text: 'القسطنطينية؟', answer: '1453', decoys: ['1492', '1517', '1389'] },
  { id: 'h2', category: 'history', text: 'حطين؟', answer: 'صلاح الدين الأيوبي', decoys: ['قطز', 'بيبرس'] },
  { id: 'hh1', level: 'hard', category: 'history', text: 'أول خليفة أموي؟', answer: 'معاوية', decoys: ['يزيد'] },
  { id: 'm1', category: 'movies', text: 'الأسد الملك؟', answer: 'سيمبا', decoys: ['سكار', 'تيمون', 'رفيقي'] },
] satisfies Question[]);

let now: number;
let seen: Record<string, number>;
let room: GameRoom;
let a: PlayerState, b: PlayerState, c: PlayerState;

/** Seeded PRNG so shuffles are reproducible. */
function rng(seed = 1) {
  return () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;
}

/** Rebuilds the room at a new time, like the next HTTP request would. */
function at(t: number) {
  now = t;
  for (const p of room.s.players) seen[p.id] = Math.max(seen[p.id] ?? 0, t);
  room = new GameRoom(room.s, seen, now, bank, room.rng);
}

const throwsCode = (fn: () => void, code: string) =>
  assert.throws(fn, (e) => e instanceof GameError && e.code === code);

const optionId = (viewer: string, pred: (o: { text: string; mine: boolean }) => boolean) =>
  room.viewFor(viewer).options.find(pred)!.id;

function setup(difficulty: 'normal' | 'hard' = 'normal') {
  now = 1_000_000;
  seen = {};
  room = new GameRoom(newRoomState('123456', 2, difficulty), seen, now, bank, rng());
  a = room.addPlayer('A');
  b = room.addPlayer('B');
  c = room.addPlayer('C');
}

beforeEach(() => setup());

function startHistoryRound() {
  room.startGame(a.id);
  room.chooseCategory(room.s.chooserId!, 'history');
}

test('first player is host and avatars are unique', () => {
  assert.equal(room.s.hostId, a.id);
  assert.equal(new Set([a.avatar, b.avatar, c.avatar]).size, 3);
});

test('all 6 characters are used before any repeats', () => {
  for (let i = 0; i < 3; i++) room.addPlayer(`P${i}`);
  assert.equal(new Set(room.s.players.map((p) => p.avatar % 6)).size, 6);
  for (let i = 0; i < 6; i++) room.addPlayer(`Q${i}`);
  assert.equal(new Set(room.s.players.map((p) => p.avatar)).size, 12);
});

test('only host can start, and only with enough players', () => {
  throwsCode(() => room.startGame(b.id), 'not_host');
  room.kick(a.id, c.id);
  room.kick(a.id, b.id);
  throwsCode(() => room.startGame(a.id), 'not_enough_players');
});

test('host can kick at any point: mid-answer, mid-vote and while paused', () => {
  room.addPlayer('D');
  const d = room.s.players.at(-1)!;
  startHistoryRound();
  room.kick(a.id, b.id);
  assert.equal(room.s.phase, 'answering');
  room.submitAnswer(a.id, 'كدبة أ');
  room.submitAnswer(c.id, 'كدبة ج');
  room.submitAnswer(d.id, 'كدبة د');
  assert.equal(room.s.phase, 'voting');
  room.pause(a.id);
  room.kick(a.id, d.id);
  assert.deepEqual(room.s.players.map((p) => p.id), [a.id, c.id]);
});

test('a game can start with just 2 players', () => {
  room.kick(a.id, c.id);
  room.startGame(a.id);
  assert.equal(room.s.phase, 'choosingCategory');
});

test('writing the real answer is rejected', () => {
  room.startGame(a.id);
  room.chooseCategory(room.s.chooserId!, 'movies');
  throwsCode(() => room.submitAnswer(a.id, 'السيمبا'), 'answer_is_correct');
  assert.equal(room.viewFor(a.id).myAnswer, null);
});

test('answers must be Arabic, use English digits, and cannot be edited', () => {
  startHistoryRound();
  throwsCode(() => room.submitAnswer(a.id, 'Fake'), 'answer_not_arabic');
  room.submitAnswer(a.id, 'سنة ١٤٩٠');
  assert.equal(room.viewFor(a.id).myAnswer, 'سنة 1490');
  throwsCode(() => room.submitAnswer(a.id, 'تانية'), 'already_submitted');
});

test('scoring: +2 for the truth, +1 per fooled player', () => {
  startHistoryRound();
  const truth = room.question!.answer;
  room.submitAnswer(a.id, 'كدبة أ');
  room.submitAnswer(b.id, 'كدبة ب');
  room.submitAnswer(c.id, 'كدبة ج');
  assert.equal(room.s.phase, 'voting');
  assert.equal(room.viewFor(a.id).options.length, 4);
  throwsCode(() => room.vote(a.id, optionId(a.id, (o) => o.mine)), 'cannot_vote_own');

  room.vote(a.id, optionId(a.id, (o) => o.text === truth));
  room.vote(b.id, optionId(b.id, (o) => o.text === 'كدبة أ'));
  room.vote(c.id, optionId(c.id, (o) => o.text === 'كدبة أ'));

  assert.equal(room.s.phase, 'roundResults');
  assert.deepEqual([a.score, b.score, c.score], [4, 0, 0]);
});

test('identical bluffs merge and both authors score', () => {
  startHistoryRound();
  room.submitAnswer(a.id, 'نفس الكدبة');
  room.submitAnswer(b.id, 'نفس  الكدبة!');
  room.submitAnswer(c.id, 'حاجة تانية');
  assert.equal(room.viewFor(c.id).options.length, 3);
  room.vote(c.id, optionId(c.id, (o) => normalizeAnswer(o.text) === normalizeAnswer('نفس الكدبة')));
  room.vote(a.id, optionId(a.id, (o) => o.text === 'حاجة تانية'));
  room.vote(b.id, optionId(b.id, (o) => o.text === 'حاجة تانية'));
  assert.deepEqual([a.score, b.score, c.score], [1, 1, 2]);
});

test('players who miss the timer get an automatic answer that scores for them', () => {
  startHistoryRound();
  room.submitAnswer(a.id, 'كدبة أ');
  at(now + 76_000);
  room.tick();
  assert.equal(room.s.phase, 'voting');
  const q = room.question!;
  for (const p of [b, c]) {
    const auto = room.s.submissions[p.id];
    assert.ok(auto, `auto answer for ${p.name}`);
    assert.ok(!matchesQuestion(q, auto), 'auto answer must not be the truth');
  }
  assert.notEqual(normalizeAnswer(room.s.submissions[b.id]), normalizeAnswer(room.s.submissions[c.id]));
  // a gets fooled by b's automatic answer: b scores.
  room.vote(a.id, optionId(a.id, (o) => o.text === room.s.submissions[b.id]));
  room.vote(b.id, optionId(b.id, (o) => o.text === 'كدبة أ'));
  room.vote(c.id, optionId(c.id, (o) => o.text === 'كدبة أ'));
  assert.equal(b.score, 1);
  assert.ok(room.s.result!.options.find((o) => o.authorIds.includes(b.id))!.auto);
});

test('host can pause: timer freezes and play is blocked until resume', () => {
  room.startGame(a.id);
  throwsCode(() => room.pause(b.id), 'not_host');
  room.pause(a.id);
  assert.equal(room.viewFor(b.id).paused, true);
  throwsCode(() => room.chooseCategory(room.s.chooserId!, 'history'), 'game_paused');
  at(now + 10 * 60_000); // long pause: nothing times out
  room.tick();
  assert.equal(room.s.phase, 'choosingCategory');
  room.resume(a.id);
  assert.ok(room.s.deadline! - now >= 5_000);
  room.chooseCategory(room.s.chooserId!, 'history');
  assert.equal(room.s.phase, 'answering');
});

test('hard rooms prefer hard questions', () => {
  setup('hard');
  room.startGame(a.id);
  room.chooseCategory(room.s.chooserId!, 'history');
  assert.equal(room.s.questionId, 'hh1');
});

test('lazy timeouts advance phases and auto-pick a category', () => {
  room.startGame(a.id);
  room.tick();
  assert.equal(room.s.phase, 'choosingCategory');
  at(now + 21_000);
  room.tick();
  assert.equal(room.s.phase, 'answering');
  room.submitAnswer(a.id, 'كدبة');
  at(now + 76_000);
  room.tick();
  assert.equal(room.s.phase, 'voting');
});

test('disconnected players do not block the round', () => {
  startHistoryRound();
  room.submitAnswer(a.id, 'كدبة أ');
  room.submitAnswer(b.id, 'كدبة ب');
  now += 16_000;
  seen[a.id] = seen[b.id] = now; // c stopped polling
  room = new GameRoom(room.s, seen, now, bank, room.rng);
  room.tick();
  assert.equal(room.s.phase, 'voting');
});

test('host role moves on when the host disappears', () => {
  now += 16_000;
  seen[b.id] = seen[c.id] = now;
  room = new GameRoom(room.s, seen, now, bank, room.rng);
  room.tick();
  assert.equal(room.s.hostId, b.id);
});

test('kicked player loses their seat and is told so', () => {
  room.kick(a.id, b.id);
  assert.equal(room.player(b.id), undefined);
  assert.ok(room.s.kickedTokens.includes(b.token));
  throwsCode(() => room.kick(b.id, a.id), 'not_host');
});

test('game ends after the configured number of rounds', () => {
  for (let r = 0; r < 2; r++) {
    if (r === 0) room.startGame(a.id);
    else room.nextRound(a.id);
    at(now + 300_000);
    room.tick(); // auto category
    for (const p of [a, b, c]) room.submitAnswer(p.id, `كدبة ${p.name === 'A' ? 'أ' : p.name === 'B' ? 'ب' : 'ج'}`);
    for (const p of [a, b, c]) room.vote(p.id, optionId(p.id, (o) => !o.mine));
  }
  room.nextRound(a.id);
  assert.equal(room.s.phase, 'gameOver');
});

test('answer matching tolerates Arabic spelling variants', () => {
  assert.ok(answersMatch('صلاح الدين الايوبى', 'صلاح الدين الأيوبي'));
  assert.ok(answersMatch('١٤٥٣', '1453'));
  assert.ok(!answersMatch('1454', '1453'));
  assert.ok(answersMatch('اسبانيا', 'إسبانيا'));
});

test('question bank is valid: Arabic only, enough decoys, none of them correct', () => {
  const ids = new Set<string>();
  for (const q of QUESTIONS) {
    assert.ok(!ids.has(q.id), `duplicate id ${q.id}`);
    ids.add(q.id);
    for (const t of [q.text, q.answer, ...(q.aliases ?? []), ...(q.decoys ?? [])]) {
      assert.ok(!hasLatinLetters(t), `${q.id}: Latin text "${t}"`);
      assert.ok(!/[٠-٩]/.test(t), `${q.id}: Arabic-Indic digits in "${t}"`);
    }
    assert.ok((q.decoys ?? []).length >= 3, `${q.id}: needs 3 decoys`);
    for (const d of q.decoys ?? []) assert.ok(!matchesQuestion(q, d), `${q.id}: decoy "${d}" matches the answer`);
  }
  for (const c of CATEGORIES) {
    for (const level of ['normal', 'hard'] as const) {
      const n = QUESTIONS.filter((q) => q.category === c && (q.level ?? 'normal') === level).length;
      assert.ok(n >= 6, `${c}/${level} has only ${n} questions`);
    }
  }
});
