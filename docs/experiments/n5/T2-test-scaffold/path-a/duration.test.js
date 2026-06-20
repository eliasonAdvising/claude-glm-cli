import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseDuration } from './duration.js';

test('test_seconds_only', () => {
  assert.equal(parseDuration('30s'), 30_000);
});

test('test_minutes_only', () => {
  assert.equal(parseDuration('5m'), 300_000);
});

test('test_hours_only', () => {
  assert.equal(parseDuration('2h'), 7_200_000);
});

test('test_combined_hms', () => {
  assert.equal(parseDuration('1h30m45s'), 5_445_000);
});

test('test_empty_string_throws', () => {
  assert.throws(() => parseDuration(''), (err) => err instanceof Error && /empty/i.test(err.message));
});

test('test_invalid_unit_throws', () => {
  assert.throws(() => parseDuration('5x'), (err) => err instanceof Error && /invalid|unit/i.test(err.message));
});

test('test_zero_value', () => {
  assert.equal(parseDuration('0s'), 0);
});
