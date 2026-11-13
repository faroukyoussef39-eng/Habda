import assert from 'node:assert/strict';
import { test } from 'node:test';

import { handle } from '../_lib/service';
import { MemoryStore } from '../_lib/store';

process.env.ADMIN_KEY = 'sesame';

const store = new MemoryStore();
const call = async (msg: Record<string, unknown>) => (await handle(msg, store)).body as any;
const admin = (msg: Record<string, unknown>) => call({ adminKey: 'sesame', ...msg });

const good = {
  category: 'history',
  text: 'سؤال تجريبي؟',
  answer: 'الجواب',
  decoys: ['أ', 'ب', 'ج'],
};

test('admin calls need the right key', async () => {
  assert.equal((await call({ type: 'admin_list' })).error, 'bad_admin_key');
  assert.equal((await call({ type: 'admin_list', adminKey: 'nope' })).error, 'bad_admin_key');
  assert.ok((await admin({ type: 'admin_list' })).questions.length > 80);
});

test('admin can add, edit and delete a question', async () => {
  const before = (await admin({ type: 'admin_list' })).questions.length;
  const added = await admin({ type: 'admin_save', question: good });
  assert.equal(added.questions.length, before + 1);
  const q = added.questions.find((x: any) => x.text === good.text);
  assert.equal(q.source, 'custom');
  assert.match(q.id, /^c_/);

  const edited = await admin({ type: 'admin_save', id: q.id, question: { ...good, level: 'hard', answer: 'تعديل' } });
  const e = edited.questions.find((x: any) => x.id === q.id);
  assert.equal(e.answer, 'تعديل');
  assert.equal(e.level, 'hard');
  assert.equal(edited.questions.length, before + 1);

  const gone = await admin({ type: 'admin_delete', id: q.id });
  assert.equal(gone.questions.length, before);
});

test('editing a built-in overrides it and deleting restores it', async () => {
  const orig = (await admin({ type: 'admin_list' })).questions.find((x: any) => x.id === 'hh1');
  const over = await admin({ type: 'admin_save', id: 'hh1', question: { ...good, text: 'معدّل؟' } });
  const o = over.questions.find((x: any) => x.id === 'hh1');
  assert.equal(o.source, 'edited');
  assert.equal(o.text, 'معدّل؟');
  const back = await admin({ type: 'admin_delete', id: 'hh1' });
  assert.equal(back.questions.find((x: any) => x.id === 'hh1').text, orig.text);
});

test('bad questions are rejected', async () => {
  const bad = (question: unknown) => admin({ type: 'admin_save', question });
  assert.equal((await bad({ ...good, category: 'x' })).error, 'bad_category');
  assert.equal((await bad({ ...good, text: ' ' })).error, 'question_text_empty');
  assert.equal((await bad({ ...good, decoys: ['أ'] })).error, 'question_needs_decoys');
  assert.equal((await bad({ ...good, decoys: ['a', 'ب', 'ج'] })).error, 'question_not_arabic');
  assert.equal((await bad({ ...good, decoys: ['الجواب', 'ب', 'ج'] })).error, 'decoy_is_answer');
  assert.equal((await bad({ ...good, imageUrl: 'http://x.com/a.png' })).error, 'bad_image_url');
  assert.equal((await admin({ type: 'admin_save', id: 'zzz', question: good })).error, 'unknown_question');
});
