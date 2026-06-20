// pluralize.js — has a bug; see pluralize.test.js for the failing case.
const IRREGULAR = {
  knife: "knives",
  child: "children",
  goose: "geese",
  mouse: "mice",
};

export function pluralize(count, word) {
  if (count === 1) return word;
  if (IRREGULAR[word]) return IRREGULAR[word];
  if (word.endsWith("s") || word.endsWith("x") || word.endsWith("z")) return word + "es";
  return word + "s";
}
