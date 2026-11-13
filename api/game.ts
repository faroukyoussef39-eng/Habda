import type { VercelRequest, VercelResponse } from '@vercel/node';

import { handle, type Message } from './_lib/service';
import { defaultStore } from './_lib/store';

/** POST /api/game — single endpoint for every client message (actions and polls). */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }
  const msg: unknown = typeof req.body === 'string' ? safeParse(req.body) : req.body;
  if (!msg || typeof msg !== 'object') {
    res.status(400).json({ error: 'bad_message' });
    return;
  }
  try {
    const reply = await handle(msg as Message, defaultStore());
    res.status(reply.status).json(reply.body);
  } catch (e) {
    const code = e instanceof Error && e.message === 'storage_not_configured' ? e.message : 'server_error';
    console.error(e);
    res.status(500).json({ error: code });
  }
}

function safeParse(s: string): unknown {
  try {
    return JSON.parse(s);
  } catch {
    return null;
  }
}
