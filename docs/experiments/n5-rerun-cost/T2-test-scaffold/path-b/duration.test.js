import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseDuration } from './duration.js';

test('test_seconds_only', () => {
  assert.strictEqual(parseDuration("30s"), 30_000);
});

test('test_minutes_only', () => {
  assert.strictEqual(parseDuration("5m"), 300_000);
});

test('test_hours_only', () => {
  assert.strictEqual(parseDuration("2h"), 7_200_000);
});

test('test_combined_hms', () => {
  assert.strictEqual(parseDuration("1h30m45s"), 5_445_000);
});

test('test_empty_string_throws', () => {
  assert.throws(() => parseDuration(""), /empty/i);
});

test('test_invalid_unit_throws', () => {
  assert.throws(() => parseDuration("5x"), /invalid|unit/i);
});

test('test_zero_value', () => {
  assert.strictEqual(parseDuration("0s"), 0);
});
