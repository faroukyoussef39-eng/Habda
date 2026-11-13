// Local API for development: `npm run dev:api` serves POST /api/game on :3000
// with in-memory storage (state resets on restart). Admin key defaults to "admin".
import { createServer } from 'node:http';

import { handle } from './api/_lib/service';
import { MemoryStore } from './api/_lib/store';

process.env.ADMIN_KEY ??= 'admin';
const store = new MemoryStore();

createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'content-type');
  if (req.method === 'OPTIONS') return void res.writeHead(204).end();
  if (req.method !== 'POST' || req.url !== '/api/game') return void res.writeHead(404).end();
  let raw = '';
  for await (const chunk of req) raw += chunk;
  try {
    const reply = await handle(JSON.parse(raw), store);
    res.writeHead(reply.status, { 'content-type': 'application/json' }).end(JSON.stringify(reply.body));
  } catch (e) {
    console.error(e);
    res.writeHead(500, { 'content-type': 'application/json' }).end('{"error":"server_error"}');
  }
}).listen(3000, () => console.log('API on http://localhost:3000/api/game (admin key: ' + process.env.ADMIN_KEY + ')'));
