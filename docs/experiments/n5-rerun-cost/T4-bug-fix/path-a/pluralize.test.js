import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pluralize } from './pluralize.js';

test('singular irregular: 1 knife stays knife', () => {
  assert.equal(pluralize(1, "knife"), "knife");
});
test('plural irregular: 2 knives', () => {
  assert.equal(pluralize(2, "knife"), "knives");
});
test('plural irregular: 5 children', () => {
  assert.equal(pluralize(5, "child"), "children");
});
test('regular: 1 dog stays dog', () => {
  assert.equal(pluralize(1, "dog"), "dog");
});
test('regular: 3 dogs', () => {
  assert.equal(pluralize(3, "dog"), "dogs");
});
test('regular sibilant: 2 boxes', () => {
  assert.equal(pluralize(2, "box"), "boxes");
});
