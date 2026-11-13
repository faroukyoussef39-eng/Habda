const ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩';
const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';

/** ٠-٩ / ۰-۹ → 0-9, so every number in the game uses English digits. */
export function toWesternDigits(input: string): string {
  let s = input;
  for (let i = 0; i < 10; i++) {
    s = s.replaceAll(ARABIC_DIGITS[i], String(i)).replaceAll(PERSIAN_DIGITS[i], String(i));
  }
  return s;
}

/** Latin letters would give a bluff away next to the Arabic real answers. */
export function hasLatinLetters(input: string): boolean {
  return /[A-Za-z]/.test(input);
}

/**
 * Canonical form used to compare answers: lowercase, Arabic letter variants
 * unified, diacritics/punctuation stripped, leading "ال" / "the" dropped.
 */
export function normalizeAnswer(input: string): string {
  let s = toWesternDigits(input.toLowerCase());
  s = s
    .replace(/[ً-ٰٟـ]/g, '') // tashkeel + tatweel
    .replace(/[أإآٱ]/g, 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
  return s
    .split(' ')
    .map(stripArticle)
    .filter((w) => w.length > 0)
    .join(' ');
}

function stripArticle(w: string): string {
  if (w === 'the') return '';
  if (w.length > 3 && w.startsWith('ال')) return w.slice(2);
  return w;
}

/**
 * True when `guess` is close enough to `truth` to count as the real answer.
 * Allows small typos on longer answers, but numbers must match exactly.
 */
export function answersMatch(guess: string, truth: string): boolean {
  const a = normalizeAnswer(guess);
  const b = normalizeAnswer(truth);
  if (!a || !b) return false;
  if (a === b || a.replaceAll(' ', '') === b.replaceAll(' ', '')) return true;
  if (/^\d+$/.test(b)) return false;
  const tolerance = b.length >= 10 ? 2 : b.length >= 5 ? 1 : 0;
  return tolerance > 0 && levenshtein(a, b) <= tolerance;
}

function levenshtein(a: string, b: string): number {
  let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      cur[j] = Math.min(cur[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost);
    }
    prev = cur;
  }
  return prev[b.length];
}
