import assert from 'node:assert/strict';
import { test } from 'node:test';

import { handle } from '../_lib/service';
import { MemoryStore } from '../_lib/store';

/** Full HTTP-level flow against the in-memory store: create, join, play, kick. */
test('a full round through the request handler', async () => {
  const store = new MemoryStore();
  let t = 5_000_000;
  const call = async (body: Record<string, unknown>) => (await handle(body, store, t)).body as any;

  const host = await call({ type: 'create_room', name: 'Host', rounds: 10 });
  const pin = host.pin as string;
  assert.match(pin, /^\d{6}$/);

  const p2 = await call({ type: 'join_room', pin, name: 'Two' });
  const p3 = await call({ type: 'join_room', pin, name: 'Three' });
  const p4 = await call({ type: 'join_room', pin, name: 'Four' });
  assert.equal((await call({ type: 'join_room', pin: '000000', name: 'x' })).error, 'room_not_found');

  const as = (p: any) => ({ pin, token: p.token });
  assert.equal((await call({ type: 'start_game', ...as(p2) })).error, 'not_host');

  // Host kicks Four; Four's next poll learns about it.
  await call({ type: 'kick', playerId: p4.playerId, ...as(host) });
  assert.equal((await call({ type: 'poll', ...as(p4) })).error, 'kicked');

  let view = (await call({ type: 'start_game', ...as(host) })).room;
  assert.equal(view.phase, 'choosingCategory');

  const players = [host, p2, p3];
  const chooser = players.find((p) => p.playerId === view.chooserId)!;
  view = (await call({ type: 'choose_category', category: 'flags', ...as(chooser) })).room;
  assert.equal(view.phase, 'answering');
  assert.ok(view.questionImage?.startsWith('https://flagcdn.com/'));

  for (const [i, p] of players.entries()) {
    view = (await call({ type: 'submit_answer', text: ['كدبة أولى', 'كدبة تانية', 'كدبة تالتة'][i], ...as(p) })).room;
  }
  assert.equal(view.phase, 'voting');
  assert.equal(view.options.length, 4);

  for (const p of players) {
    const mine = (await call({ type: 'poll', ...as(p) })).room;
    const pick = mine.options.find((o: any) => !o.mine);
    view = (await call({ type: 'vote', optionId: pick.id, ...as(p) })).room;
  }
  assert.equal(view.phase, 'roundResults');
  assert.ok(view.result.answer.length > 0);

  // Nobody presses "next": a poll after the results timer starts round 2.
  t += 16_000;
  for (const p of players) await call({ type: 'poll', ...as(p) });
  const after = (await call({ type: 'poll', ...as(host) })).room;
  assert.equal(after.round, 2);
  assert.equal(after.phase, 'choosingCategory');
  assert.ok(after.version > view.version);
});
