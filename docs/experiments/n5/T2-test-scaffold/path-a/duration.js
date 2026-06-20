// Parses human-readable duration strings into milliseconds.
const UNITS = { s: 1_000, m: 60_000, h: 3_600_000 };

export function parseDuration(str) {
  if (!str) throw new Error("empty duration");
  const re = /(\d+)([smh])/g;
  let total = 0;
  let matched = 0;
  let lastIdx = 0;
  for (const m of str.matchAll(re)) {
    matched++;
    lastIdx = m.index + m[0].length;
    total += Number(m[1]) * UNITS[m[2]];
  }
  if (matched === 0 || lastIdx !== str.length) {
    const bad = str.match(/[a-zA-Z]/)?.[0] ?? str;
    if (bad && !UNITS[bad]) throw new Error("invalid unit: " + bad);
    throw new Error("empty duration");
  }
  return total;
}
