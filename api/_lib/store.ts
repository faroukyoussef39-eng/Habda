import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import type { Question, RoomState } from './engine';

/** Rooms untouched for this long are deleted. */
const ROOM_TTL_MS = 3 * 60 * 60 * 1000;

export interface Snapshot {
  state: RoomState | null;
  seen: Record<string, number>;
}

export interface Store {
  load(pin: string): Promise<Snapshot>;
  /** Persists a state whose `version` was just bumped by one. */
  save(state: RoomState): Promise<void>;
  /** Writes the new room only if the PIN is free. */
  create(state: RoomState): Promise<boolean>;
  /** Records that a player was just heard from (presence). */
  touch(pin: string, playerId: string, now: number): Promise<void>;
  /** Runs a load-modify-save of one room so concurrent writers can't clobber each other. */
  withLock<T>(pin: string, fn: () => Promise<T>): Promise<T>;
  /** Admin-managed questions (additions and edits of built-ins). */
  listQuestions(): Promise<Question[]>;
  saveQuestion(q: Question): Promise<void>;
  deleteQuestion(id: string): Promise<void>;
}

/** Another request saved the room first; the whole operation is retried. */
class ConflictError extends Error {}

/**
 * Supabase Postgres (tables in supabase/schema.sql). Instead of a lock, saves
 * are conditional on the previous version and the operation retries on conflict.
 */
export class SupabaseStore implements Store {
  constructor(private readonly db: SupabaseClient) {}

  async load(pin: string): Promise<Snapshot> {
    const [room, presence] = await Promise.all([
      this.db.from('rooms').select('state').eq('pin', pin).maybeSingle(),
      this.db.from('presence').select('player_id, seen').eq('pin', pin),
    ]);
    if (room.error) throw room.error;
    if (presence.error) throw presence.error;
    const seen: Record<string, number> = {};
    for (const row of presence.data ?? []) seen[row.player_id] = Number(row.seen);
    return { state: (room.data?.state as RoomState | undefined) ?? null, seen };
  }

  async save(state: RoomState): Promise<void> {
    const { data, error } = await this.db
      .from('rooms')
      .update({ state, version: state.version, updated_at: new Date().toISOString() })
      .eq('pin', state.pin)
      .eq('version', state.version - 1)
      .select('pin');
    if (error) throw error;
    if (!data?.length) throw new ConflictError();
  }

  async create(state: RoomState): Promise<boolean> {
    // Opportunistic cleanup of abandoned rooms (presence rows cascade).
    await this.db
      .from('rooms')
      .delete()
      .lt('updated_at', new Date(Date.now() - ROOM_TTL_MS).toISOString());
    const { error } = await this.db
      .from('rooms')
      .insert({ pin: state.pin, version: state.version, state });
    if (!error) return true;
    if (error.code === '23505') return false; // PIN already taken
    throw error;
  }

  async touch(pin: string, playerId: string, now: number): Promise<void> {
    const { error } = await this.db.from('presence').upsert({ pin, player_id: playerId, seen: now });
    if (error) throw error;
  }

  async listQuestions(): Promise<Question[]> {
    const { data, error } = await this.db.from('custom_questions').select('data');
    if (error) throw error;
    return (data ?? []).map((r) => r.data as Question);
  }

  async saveQuestion(q: Question): Promise<void> {
    const { error } = await this.db
      .from('custom_questions')
      .upsert({ id: q.id, data: q, updated_at: new Date().toISOString() });
    if (error) throw error;
  }

  async deleteQuestion(id: string): Promise<void> {
    const { error } = await this.db.from('custom_questions').delete().eq('id', id);
    if (error) throw error;
  }

  async withLock<T>(_pin: string, fn: () => Promise<T>): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await fn();
      } catch (e) {
        if (!(e instanceof ConflictError) || attempt >= 10) throw e;
        await new Promise((r) => setTimeout(r, 30 + Math.random() * 70));
      }
    }
  }
}

/** Single-process store for tests and local runs without Supabase. */
export class MemoryStore implements Store {
  private readonly rooms = new Map<string, string>();
  private readonly seen = new Map<string, Record<string, number>>();
  private readonly locks = new Map<string, Promise<unknown>>();
  private readonly questions = new Map<string, Question>();

  async listQuestions(): Promise<Question[]> {
    return [...this.questions.values()];
  }

  async saveQuestion(q: Question): Promise<void> {
    this.questions.set(q.id, q);
  }

  async deleteQuestion(id: string): Promise<void> {
    this.questions.delete(id);
  }

  async load(pin: string): Promise<Snapshot> {
    const raw = this.rooms.get(pin);
    return { state: raw ? JSON.parse(raw) : null, seen: { ...(this.seen.get(pin) ?? {}) } };
  }

  async save(state: RoomState): Promise<void> {
    this.rooms.set(state.pin, JSON.stringify(state));
  }

  async create(state: RoomState): Promise<boolean> {
    if (this.rooms.has(state.pin)) return false;
    await this.save(state);
    return true;
  }

  async touch(pin: string, playerId: string, now: number): Promise<void> {
    this.seen.set(pin, { ...(this.seen.get(pin) ?? {}), [playerId]: now });
  }

  async withLock<T>(pin: string, fn: () => Promise<T>): Promise<T> {
    const prev = this.locks.get(pin) ?? Promise.resolve();
    const run = prev.then(fn, fn);
    this.locks.set(pin, run.catch(() => undefined));
    return run;
  }
}

let shared: Store | undefined;

/** Supabase when SUPABASE_URL + SUPABASE_SECRET_KEY are set (Vercel env vars). */
export function defaultStore(): Store {
  if (shared) return shared;
  // Values pasted via some shells carry a BOM / whitespace that breaks HTTP headers.
  const clean = (v: string | undefined) => v?.replace(/^﻿/, '').trim() || undefined;
  const url = clean(process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL);
  const key = clean(process.env.SUPABASE_SECRET_KEY);
  if (url && key) {
    shared = new SupabaseStore(createClient(url, key, { auth: { persistSession: false } }));
  } else if (process.env.VERCEL_ENV === 'production' || process.env.VERCEL_ENV === 'preview') {
    // In-memory state would silently break across serverless instances.
    throw new Error('storage_not_configured');
  } else {
    shared = new MemoryStore();
  }
  return shared;
}
