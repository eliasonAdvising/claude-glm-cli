import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatAccount } from './formatter.js';

test('formats valid input with default currency', () => {
  assert.equal(formatAccount({ name: "Ada", balance: 100.5 }), "Ada: USD 100.50");
});
test('trims name', () => {
  assert.equal(formatAccount({ name: "  Bob  ", balance: 50 }), "Bob: USD 50.00");
});
test('uppercases currency', () => {
  assert.equal(formatAccount({ name: "Cat", balance: 25, currency: "eur" }), "Cat: EUR 25.00");
});
test('handles negative balance', () => {
  assert.equal(formatAccount({ name: "Dee", balance: -12.345 }), "Dee: -USD 12.35");
});
test('throws on missing name', () => {
  assert.throws(() => formatAccount({ balance: 1 }), /name/);
});
test('throws on non-numeric balance', () => {
  assert.throws(() => formatAccount({ name: "Eve", balance: "ten" }), /balance/);
});
test('throws on null input', () => {
  assert.throws(() => formatAccount(null), /object/);
});
