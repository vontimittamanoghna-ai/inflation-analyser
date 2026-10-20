import { test } from 'node:test';
import assert from 'node:assert/strict';
import { projectCost } from './src/calculations.js';

test('annual compounding includes quantity and year zero', () => {
  const result = projectCost('100', '2', '10', '2');
  assert.ok(Math.abs(result.future - 242) < 1e-9);
  assert.equal(result.current, 200);
  assert.equal(result.schedule[0].cost, 200);
  assert.equal(result.schedule.length, 3);
});
test('zero rate keeps the cost unchanged', () => {
  assert.equal(projectCost(100, 2, 0, 30).future, 200);
});
test('negative assumed rates lower future cost', () => {
  assert.ok(Math.abs(projectCost(100, 2, -5, 2).future - 180.5) < 1e-9);
});
test('invalid, blank and out-of-bounds inputs never show a result', () => {
  for (const args of [['',1,6,1],[0,1,6,1],[10,0,6,1],[10,1,-100,1],[10,1,101,1],
    [10,1,6,0],[10,1,6,1.5],[10,1,6,31],[Infinity,1,6,1],[10,1,'invalid',1],
    [1e10,1,6,1],[10,1e7,6,1]]) assert.equal(projectCost(...args), null);
});
