import { answersMatch, hasLatinLetters, normalizeAnswer, toWesternDigits } from './matching';

export type Phase = 'lobby' | 'choosingCategory' | 'answering' | 'voting' | 'roundResults' | 'gameOver';
export type Category =
  | 'history'
  | 'literature'
  | 'football'
  | 'movies'
  | 'flags'
  | 'songs'
  | 'geography'
  | 'cars'
  | 'whoPlayer'
  | 'whoCelebrity';
export type Difficulty = 'normal' | 'hard';
export const CATEGORIES: Category[] = [
  'history',
  'literature',
  'football',
  'movies',
  'flags',
  'songs',
  'geography',
  'cars',
  'whoPlayer',
  'whoCelebrity',
];
export const DIFFICULTIES: Difficulty[] = ['normal', 'hard'];
export const ROUND_OPTIONS = [10, 15, 20];
export const AVATAR_COUNT = 12;
/** Distinct character portraits; avatar index % CHARACTER_COUNT picks one. */
export const CHARACTER_COUNT = 6;

export interface Question {
  id: string;
  category: Category;
  /** Omitted = 'normal'. */
  level?: Difficulty;
  text: string;
  answer: string;
  /** Other spellings that also count as the real answer. */
  aliases?: string[];
  /** Plausible wrong answers, used for players who don't write one in time. */
  decoys?: string[];
  imageUrl?: string;
}

export interface Rules {
  minPlayers: number;
  maxPlayers: number;
  maxAnswerLength: number;
  chooseMs: number;
  answerMs: number;
  voteMs: number;
  resultsMs: number;
  /** A player who hasn't polled for this long counts as disconnected. */
  presenceMs: number;
  /** Disconnected players are dropped from the lobby after this long. */
  lobbyDropMs: number;
}

export const RULES: Rules = {
  minPlayers: 2,
  maxPlayers: 12,
  maxAnswerLength: 60,
  chooseMs: 20_000,
  answerMs: 75_000,
  voteMs: 40_000,
  resultsMs: 15_000,
  presenceMs: 15_000,
  lobbyDropMs: 60_000,
};

/** A rule violation; `code` is mapped to a user-facing message in the app. */
export class GameError extends Error {
  constructor(readonly code: string) {
    super(code);
  }
}

export interface PlayerState {
  id: string;
  /** Secret used to authenticate requests and reclaim the seat after a refresh. */
  token: string;
  name: string;
  avatar: number;
  score: number;
}

export interface OptionState {
  id: string;
  text: string;
  /** Players who wrote this answer. Empty means it is the real answer. */
  authorIds: string[];
}

export interface OptionResult {
  id: string;
  text: string;
  isTruth: boolean;
  /** Filled in by the game for players who didn't answer. */
  auto: boolean;
  authorIds: string[];
  voterIds: string[];
}

export interface RoundResult {
  questionText: string;
  answer: string;
  options: OptionResult[];
  deltas: Record<string, number>;
}

/** Everything about a room, stored as one JSON document. */
export interface RoomState {
  version: number;
  pin: string;
  totalRounds: number;
  hostId: string | null;
  phase: Phase;
  round: number;
  chooserId: string | null;
  questionId: string | null;
  /** Epoch ms when the current phase times out. */
  deadline: number | null;
  players: PlayerState[];
  submissions: Record<string, string>;
  options: OptionState[];
  votes: Record<string, string>;
  usedQuestionIds: string[];
  /** Shuffled queue so everyone picks a category once before anyone repeats. */
  chooserBag: string[];
  idSeq: number;
  result: RoundResult | null;
  kickedTokens: string[];
  difficulty: Difficulty;
  /** Host froze the game; the phase timer is stored in pausedRemainingMs. */
  paused: boolean;
  pausedRemainingMs: number | null;
  /** Players whose answer this round was filled in automatically. */
  autoIds: string[];
}

export class QuestionBank {
  private byId = new Map<string, Question>();

  constructor(private readonly base: Question[]) {
    this.setCustom([]);
  }

  /** Admin-managed questions: new ones are added, ones sharing a built-in id replace it. */
  setCustom(custom: Question[]): void {
    const map = new Map<string, Question>();
    for (const q of this.base) map.set(q.id, q);
    for (const q of custom) map.set(q.id, q);
    this.byId = map;
  }

  /** Every question currently in play. */
  all(): Question[] {
    return [...this.byId.values()];
  }

  get(id: string): Question | undefined {
    return this.byId.get(id);
  }

  /** Unused questions in a category, preferring [level] and falling back to any level. */
  pool(category: Category, used: string[], level?: Difficulty): Question[] {
    const all = [...this.byId.values()].filter((q) => q.category === category && !used.includes(q.id));
    if (!level) return all;
    const preferred = all.filter((q) => (q.level ?? 'normal') === level);
    return preferred.length > 0 ? preferred : all;
  }

  /** Every answer and decoy in a category: fallback material for auto-answers. */
  textsIn(category: Category): string[] {
    return [...this.byId.values()]
      .filter((q) => q.category === category)
      .flatMap((q) => [q.answer, ...(q.decoys ?? [])]);
  }
}

export function matchesQuestion(q: Question, guess: string): boolean {
  return answersMatch(guess, q.answer) || (q.aliases ?? []).some((a) => answersMatch(guess, a));
}

export function newRoomState(pin: string, totalRounds: number, difficulty: Difficulty = 'normal'): RoomState {
  return {
    difficulty,
    paused: false,
    pausedRemainingMs: null,
    autoIds: [],
    version: 0,
    pin,
    totalRounds,
    hostId: null,
    phase: 'lobby',
    round: 0,
    chooserId: null,
    questionId: null,
    deadline: null,
    players: [],
    submissions: {},
    options: [],
    votes: {},
    usedQuestionIds: [],
    chooserBag: [],
    idSeq: 0,
    result: null,
    kickedTokens: [],
  };
}

/**
 * Authoritative rules for one room, applied to a [RoomState] snapshot.
 *
 *   lobby -> choosingCategory -> answering -> voting -> roundResults
 *                 ^                                          |
 *                 +-------------- (next round) --------------+
 *                                                            v
 *                                                        gameOver
 *
 * There is no long-running server, so time is handled lazily: every request
 * calls [tick], which applies any expired deadline and drops absent players.
 * Every public action either applies or throws [GameError].
 */
export class GameRoom {
  constructor(
    readonly s: RoomState,
    /** Last time each player was heard from (epoch ms). */
    readonly seen: Record<string, number>,
    readonly now: number,
    readonly bank: QuestionBank,
    readonly rng: () => number = Math.random,
    readonly rules: Rules = RULES,
  ) {}

  get question(): Question | undefined {
    return this.s.questionId ? this.bank.get(this.s.questionId) : undefined;
  }

  player(id: string | null): PlayerState | undefined {
    return this.s.players.find((p) => p.id === id);
  }

  playerByToken(token: string): PlayerState | undefined {
    return this.s.players.find((p) => p.token === token);
  }

  isConnected(id: string): boolean {
    return (this.seen[id] ?? 0) > this.now - this.rules.presenceMs;
  }

  /** Players we wait for before moving on. Disconnected players never block. */
  activeIds(): string[] {
    return this.s.players.filter((p) => this.isConnected(p.id)).map((p) => p.id);
  }

  availableCategories(): Category[] {
    return CATEGORIES.filter((c) => this.bank.pool(c, this.s.usedQuestionIds).length > 0);
  }

  // ------------------------------------------------------------------ joining

  addPlayer(rawName: string): PlayerState {
    if (this.s.phase !== 'lobby') throw new GameError('game_in_progress');
    if (this.s.players.length >= this.rules.maxPlayers) throw new GameError('room_full');
    const p: PlayerState = {
      id: `p${++this.s.idSeq}`,
      token: randomToken(),
      name: this.uniqueName(rawName),
      avatar: this.pickAvatar(),
      score: 0,
    };
    this.s.players.push(p);
    this.s.hostId ??= p.id;
    this.seen[p.id] = this.now;
    return p;
  }

  leave(id: string): void {
    this.requirePlayer(id);
    this.removePlayer(id);
  }

  kick(by: string, target: string): void {
    this.requireHost(by);
    if (target === by) throw new GameError('cannot_kick_self');
    const p = this.requirePlayer(target);
    this.s.kickedTokens.push(p.token);
    this.removePlayer(target);
  }

  // ---------------------------------------------------------------- game flow

  startGame(by: string): void {
    this.requireHost(by);
    this.requirePhase('lobby');
    if (this.activeIds().length < this.rules.minPlayers) throw new GameError('not_enough_players');
    for (const p of this.s.players) p.score = 0;
    this.s.round = 0;
    this.s.usedQuestionIds = [];
    this.s.chooserBag = [];
    this.nextRoundInternal();
  }

  /** Host freezes the timer; play actions are refused until [resume]. */
  pause(by: string): void {
    this.requireHost(by);
    if (this.s.phase === 'lobby' || this.s.phase === 'gameOver') throw new GameError('wrong_phase');
    if (this.s.paused) return;
    this.s.paused = true;
    this.s.pausedRemainingMs = this.s.deadline === null ? null : Math.max(0, this.s.deadline - this.now);
    this.s.deadline = null;
  }

  resume(by: string): void {
    this.requireHost(by);
    if (!this.s.paused) return;
    this.s.paused = false;
    const remaining = this.s.pausedRemainingMs;
    // At least a few seconds so nobody gets skipped the instant play resumes.
    this.s.deadline = remaining === null ? null : this.now + Math.max(remaining, 5_000);
    this.s.pausedRemainingMs = null;
    this.checkProgress();
  }

  chooseCategory(by: string, category: string): void {
    this.requirePhase('choosingCategory');
    this.requireNotPaused();
    if (by !== this.s.chooserId) throw new GameError('not_your_turn');
    if (!CATEGORIES.includes(category as Category)) throw new GameError('bad_category');
    this.beginQuestion(category as Category);
  }

  submitAnswer(by: string, raw: string): void {
    this.requirePhase('answering');
    this.requireNotPaused();
    this.requirePlayer(by);
    // Answers are final once sent.
    if (by in this.s.submissions) throw new GameError('already_submitted');
    const text = toWesternDigits(raw).trim().replace(/\s+/g, ' ');
    if (!normalizeAnswer(text)) throw new GameError('answer_empty');
    if (text.length > this.rules.maxAnswerLength) throw new GameError('answer_too_long');
    if (hasLatinLetters(text)) throw new GameError('answer_not_arabic');
    // Guessing the truth is rejected: the player must write a bluff instead.
    if (matchesQuestion(this.question!, text)) throw new GameError('answer_is_correct');
    this.s.submissions[by] = text;
    this.checkProgress();
  }

  vote(by: string, optionId: string): void {
    this.requirePhase('voting');
    this.requireNotPaused();
    this.requirePlayer(by);
    const option = this.s.options.find((o) => o.id === optionId);
    if (!option) throw new GameError('unknown_option');
    if (option.authorIds.includes(by)) throw new GameError('cannot_vote_own');
    this.s.votes[by] = optionId;
    this.checkProgress();
  }

  nextRound(by: string): void {
    this.requireHost(by);
    this.requirePhase('roundResults');
    this.requireNotPaused();
    this.nextRoundInternal();
  }

  restart(by: string): void {
    this.requireHost(by);
    this.requirePhase('gameOver');
    Object.assign(this.s, {
      phase: 'lobby',
      round: 0,
      chooserId: null,
      questionId: null,
      deadline: null,
      result: null,
      paused: false,
      pausedRemainingMs: null,
    } satisfies Partial<RoomState>);
  }

  /** Applies time-based changes: host hand-off, expired deadlines, absent players. */
  tick(): void {
    const s = this.s;
    if (s.phase === 'lobby') {
      for (const p of [...s.players]) {
        if ((this.seen[p.id] ?? 0) < this.now - this.rules.lobbyDropMs) this.removePlayer(p.id);
      }
    }
    if (s.hostId && !this.isConnected(s.hostId)) {
      const other = this.activeIds()[0];
      if (other) s.hostId = other;
    }
    if (s.paused) return;
    if (s.deadline !== null && this.now >= s.deadline) this.handleTimeout();
    this.checkProgress();
  }

  // ---------------------------------------------------------------- internals

  private handleTimeout(): void {
    switch (this.s.phase) {
      case 'choosingCategory': {
        // Chooser was too slow: pick for them.
        const cats = this.availableCategories();
        this.beginQuestion(cats[Math.floor(this.rng() * cats.length)]);
        break;
      }
      case 'answering':
        this.startVoting();
        break;
      case 'voting':
        this.scoreRound();
        break;
      case 'roundResults':
        this.nextRoundInternal();
        break;
      default:
        this.s.deadline = null;
    }
  }

  private nextRoundInternal(): void {
    const s = this.s;
    s.submissions = {};
    s.votes = {};
    s.options = [];
    s.autoIds = [];
    s.result = null;
    s.questionId = null;
    if (s.round >= s.totalRounds || this.availableCategories().length === 0) {
      s.phase = 'gameOver';
      s.chooserId = null;
      s.deadline = null;
      return;
    }
    s.round++;
    s.chooserId = this.drawChooser();
    s.phase = 'choosingCategory';
    s.deadline = this.now + this.rules.chooseMs;
  }

  private drawChooser(): string | null {
    const active = new Set(this.activeIds());
    if (active.size === 0) return null;
    for (;;) {
      if (this.s.chooserBag.length === 0) this.s.chooserBag = this.shuffle([...active]);
      const id = this.s.chooserBag.pop()!;
      if (active.has(id)) return id;
    }
  }

  private beginQuestion(category: Category): void {
    const pool = this.bank.pool(category, this.s.usedQuestionIds, this.s.difficulty);
    if (pool.length === 0) throw new GameError('category_exhausted');
    const q = pool[Math.floor(this.rng() * pool.length)];
    this.s.usedQuestionIds.push(q.id);
    this.s.questionId = q.id;
    this.s.phase = 'answering';
    this.s.deadline = this.now + this.rules.answerMs;
  }

  /**
   * Anyone who didn't answer in time gets a plausible fake from the question's
   * decoys (or other answers in the category). It counts as theirs: they still
   * earn a point for every friend it fools.
   */
  private fillMissingAnswers(): void {
    const q = this.question!;
    const taken = new Set(Object.values(this.s.submissions).map(normalizeAnswer));
    const candidates = [
      ...this.shuffle([...(q.decoys ?? [])]),
      ...this.shuffle(this.bank.textsIn(q.category)),
    ].filter((t) => !matchesQuestion(q, t));
    for (const p of this.s.players) {
      if (p.id in this.s.submissions) continue;
      const pick = candidates.find((t) => !taken.has(normalizeAnswer(t)));
      if (!pick) break;
      taken.add(normalizeAnswer(pick));
      this.s.submissions[p.id] = pick;
      this.s.autoIds.push(p.id);
    }
  }

  private startVoting(): void {
    this.fillMissingAnswers();
    // Identical bluffs collapse into one option credited to every author.
    const groups = new Map<string, { text: string; authors: string[] }>();
    for (const [playerId, text] of Object.entries(this.s.submissions)) {
      const key = normalizeAnswer(text);
      if (!groups.has(key)) groups.set(key, { text, authors: [] });
      groups.get(key)!.authors.push(playerId);
    }
    const entries = this.shuffle([...groups.values(), { text: this.question!.answer, authors: [] }]);
    // Ids are assigned after shuffling so they don't reveal which is real.
    this.s.options = entries.map((e, i) => ({ id: `o${i}`, text: e.text, authorIds: e.authors }));
    this.s.phase = 'voting';
    this.s.deadline = this.now + this.rules.voteMs;
  }

  private scoreRound(): void {
    const s = this.s;
    const deltas: Record<string, number> = Object.fromEntries(s.players.map((p) => [p.id, 0]));
    const voters: Record<string, string[]> = Object.fromEntries(s.options.map((o) => [o.id, []]));
    for (const [voterId, optionId] of Object.entries(s.votes)) {
      if (!(voterId in deltas)) continue;
      voters[optionId].push(voterId);
      const option = s.options.find((o) => o.id === optionId)!;
      if (option.authorIds.length === 0) {
        deltas[voterId] += 2; // found the real answer
      } else {
        // +1 to each author for every friend they fooled.
        for (const author of option.authorIds) if (author in deltas) deltas[author] += 1;
      }
    }
    for (const p of s.players) p.score += deltas[p.id];

    s.result = {
      questionText: this.question!.text,
      answer: this.question!.answer,
      options: s.options.map((o) => ({
        id: o.id,
        text: o.text,
        isTruth: o.authorIds.length === 0,
        auto: o.authorIds.length > 0 && o.authorIds.every((id) => s.autoIds.includes(id)),
        authorIds: o.authorIds,
        voterIds: voters[o.id],
      })),
      deltas,
    };
    s.phase = 'roundResults';
    s.deadline = this.now + this.rules.resultsMs;
  }

  /** Moves on early once everyone still connected has acted. */
  private checkProgress(): void {
    const s = this.s;
    if (s.paused) return;
    const active = this.activeIds();
    switch (s.phase) {
      case 'choosingCategory':
        if (!s.chooserId || !this.isConnected(s.chooserId)) {
          const next = this.drawChooser();
          if (next !== s.chooserId) {
            s.chooserId = next;
            s.deadline = this.now + this.rules.chooseMs;
          }
        }
        break;
      case 'answering':
        if (active.length > 0 && active.every((id) => id in s.submissions)) this.startVoting();
        break;
      case 'voting':
        if (active.length > 0 && active.every((id) => id in s.votes)) this.scoreRound();
        break;
    }
  }

  private removePlayer(id: string): void {
    const s = this.s;
    s.players = s.players.filter((p) => p.id !== id);
    delete s.submissions[id];
    delete s.votes[id];
    s.chooserBag = s.chooserBag.filter((x) => x !== id);
    if (s.hostId === id) s.hostId = this.activeIds()[0] ?? s.players[0]?.id ?? null;
    const inGame = s.phase !== 'lobby' && s.phase !== 'gameOver';
    if (inGame && s.players.length < 2) {
      s.phase = 'gameOver';
      s.deadline = null;
      return;
    }
    this.checkProgress();
  }

  private uniqueName(raw: string): string {
    const cleaned = toWesternDigits(raw).trim().replace(/\s+/g, ' ');
    if (!cleaned) throw new GameError('name_empty');
    const base = [...cleaned].slice(0, 16).join('');
    const taken = new Set(this.s.players.map((p) => p.name));
    let name = base;
    for (let n = 2; taken.has(name); n++) name = `${base} ${n}`;
    return name;
  }

  /**
   * Avatars are CHARACTER_COUNT characters × ring colours; hand out every
   * character once before repeating one in another colour.
   */
  private pickAvatar(): number {
    const all = Array.from({ length: AVATAR_COUNT }, (_, i) => i);
    const used = new Set(this.s.players.map((p) => p.avatar));
    const usedCharacters = new Set([...used].map((i) => i % CHARACTER_COUNT));
    const fresh = all.filter((i) => !used.has(i) && !usedCharacters.has(i % CHARACTER_COUNT));
    const free = all.filter((i) => !used.has(i));
    const from = fresh.length > 0 ? fresh : free.length > 0 ? free : all;
    return from[Math.floor(this.rng() * from.length)];
  }

  private shuffle<T>(items: T[]): T[] {
    for (let i = items.length - 1; i > 0; i--) {
      const j = Math.floor(this.rng() * (i + 1));
      [items[i], items[j]] = [items[j], items[i]];
    }
    return items;
  }

  private requireNotPaused(): void {
    if (this.s.paused) throw new GameError('game_paused');
  }

  private requireHost(by: string): void {
    if (by !== this.s.hostId) throw new GameError('not_host');
  }

  private requirePhase(p: Phase): void {
    if (this.s.phase !== p) throw new GameError('wrong_phase');
  }

  private requirePlayer(id: string): PlayerState {
    const p = this.player(id);
    if (!p) throw new GameError('unknown_player');
    return p;
  }

  // --------------------------------------------------------------------- view

  /**
   * What one player is allowed to see. Hidden information (the real answer,
   * who wrote what) never leaves the server early. Shape matches the Dart
   * `RoomView.fromJson` in packages/game_core.
   */
  viewFor(playerId: string) {
    const s = this.s;
    const q = this.question;
    const showQuestion = s.phase === 'answering' || s.phase === 'voting';
    return {
      version: s.version,
      pin: s.pin,
      phase: s.phase,
      round: s.round,
      totalRounds: s.totalRounds,
      difficulty: s.difficulty,
      paused: s.paused,
      minPlayers: this.rules.minPlayers,
      maxAnswerLength: this.rules.maxAnswerLength,
      hostId: s.hostId,
      chooserId: s.chooserId,
      category: q?.category ?? null,
      players: s.players.map((p) => ({
        id: p.id,
        name: p.name,
        avatar: p.avatar,
        score: p.score,
        connected: this.isConnected(p.id),
        submitted: p.id in s.submissions,
        voted: p.id in s.votes,
      })),
      questionText: showQuestion ? q!.text : null,
      questionImage: showQuestion ? (q!.imageUrl ?? null) : null,
      myAnswer: s.submissions[playerId] ?? null,
      options:
        s.phase === 'voting'
          ? s.options.map((o) => ({ id: o.id, text: o.text, mine: o.authorIds.includes(playerId) }))
          : [],
      myVote: s.votes[playerId] ?? null,
      availableCategories: s.phase === 'choosingCategory' ? this.availableCategories() : [],
      result: s.phase === 'roundResults' ? s.result : null,
      deadlineMs: s.deadline,
      serverNowMs: this.now,
    };
  }
}

function randomToken(): string {
  const bytes = new Uint8Array(18);
  crypto.getRandomValues(bytes);
  return Buffer.from(bytes).toString('base64url');
}
