import { test } from 'node:test';
import assert from 'node:assert/strict';
import { get } from './src/api.js';

test('encodes filters and forwards abort signal', async () => {
  const controller = new AbortController();
  globalThis.fetch = async (url, options) => {
    assert.equal(new URL(url).searchParams.get('search'), "rice & milk");
    assert.equal(options.signal, controller.signal);
    return { ok: true, json: async () => [] };
  };
  assert.deepEqual(await get('/prices/latest', { search: 'rice & milk' }, controller.signal), []);
});
test('database failure never returns fallback fixtures', async () => {
  globalThis.fetch = async () => ({ ok: false, status: 503 });
  await assert.rejects(get('/categories'), /Database unavailable/);
});
test('aborted requests propagate cancellation', async () => {
  globalThis.fetch = async () => { throw new DOMException('Aborted', 'AbortError'); };
  await assert.rejects(get('/locations'), { name: 'AbortError' });
});
