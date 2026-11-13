import { timingSafeEqual } from 'node:crypto';

import { CATEGORIES, GameError, matchesQuestion, type Category, type Difficulty, type Question } from './engine';
import { hasLatinLetters, toWesternDigits } from './matching';

/** Admin access is a shared secret in the ADMIN_KEY environment variable. */
export function requireAdmin(key: unknown): void {
  const expected = process.env.ADMIN_KEY?.replace(/^﻿/, '').trim();
  if (!expected) throw new GameError('admin_disabled');
  const given = Buffer.from(typeof key === 'string' ? key : '');
  const want = Buffer.from(expected);
  if (given.length !== want.length || !timingSafeEqual(given, want)) throw new GameError('bad_admin_key');
}

const clean = (v: unknown, max: number) =>
  toWesternDigits(typeof v === 'string' ? v : '')
    .trim()
    .replace(/\s+/g, ' ')
    .slice(0, max);

const cleanList = (v: unknown, maxItems: number, maxLen: number) =>
  (Array.isArray(v) ? v : []).map((x) => clean(x, maxLen)).filter(Boolean).slice(0, maxItems);

/**
 * Turns an admin form into a valid [Question] or throws a GameError whose code
 * the app shows. [id] is the question being edited, or null for a new one.
 */
export function buildQuestion(raw: unknown, id: string): Question {
  const r = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  const category = r.category as Category;
  if (!CATEGORIES.includes(category)) throw new GameError('bad_category');
  const level: Difficulty = r.level === 'hard' ? 'hard' : 'normal';
  const text = clean(r.text, 300);
  const answer = clean(r.answer, 60);
  if (!text) throw new GameError('question_text_empty');
  if (!answer) throw new GameError('question_answer_empty');
  const aliases = cleanList(r.aliases, 6, 60);
  const decoys = cleanList(r.decoys, 8, 60);
  if (decoys.length < 3) throw new GameError('question_needs_decoys');
  // Players can only type Arabic, so the real answer and decoys must be Arabic too.
  if ([answer, ...aliases, ...decoys].some(hasLatinLetters)) throw new GameError('question_not_arabic');

  const q: Question = { id, category, text, answer, decoys };
  if (level === 'hard') q.level = 'hard';
  if (aliases.length) q.aliases = aliases;
  const imageUrl = clean(r.imageUrl, 500);
  if (imageUrl) {
    if (!/^https:\/\/\S+$/.test(imageUrl)) throw new GameError('bad_image_url');
    q.imageUrl = imageUrl;
  }
  if (decoys.some((d) => matchesQuestion(q, d))) throw new GameError('decoy_is_answer');
  return q;
}

export function newQuestionId(): string {
  return `c_${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`;
}
