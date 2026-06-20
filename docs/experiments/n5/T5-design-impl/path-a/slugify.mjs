#!/usr/bin/env node
// slugify.mjs — turn a title into a URL slug

const VERSION = '1.0.0';
const HELP = `Usage: node slugify.mjs "<title>"
       node slugify.mjs --help
       node slugify.mjs --version

Turns a title into a URL-safe slug.

Rules (applied in order):
  1. Lowercase
  2. Strip leading/trailing whitespace
  3. Replace any run of whitespace with a single '-'
  4. Remove characters not in [a-z0-9-]
  5. Collapse multiple '-' into one
  6. Strip leading/trailing '-'
  7. Truncate to 60 chars (then strip trailing '-' if any)

Exit codes:
  0  success / --help / --version
  2  no argument
  3  empty result after processing`;

function slugify(input) {
  let s = String(input);
  // 1. Lowercase
  s = s.toLowerCase();
  // 2. Strip leading/trailing whitespace
  s = s.replace(/^\s+|\s+$/g, '');
  // 3. Replace runs of whitespace with single '-'
  s = s.replace(/\s+/g, '-');
  // 4. Remove characters not [a-z0-9-]
  s = s.replace(/[^a-z0-9-]/g, '');
  // 5. Collapse multiple '-' into one
  s = s.replace(/-+/g, '-');
  // 6. Strip leading/trailing '-'
  s = s.replace(/^-+|-+$/g, '');
  // 7. Truncate to 60 chars + strip trailing '-'
  if (s.length > 60) {
    s = s.slice(0, 60);
    s = s.replace(/-+$/, '');
  }
  return s;
}

const args = process.argv.slice(2);

if (args.length === 0) {
  process.stderr.write('Error: missing argument. Usage: node slugify.mjs "<title>"\n');
  process.exit(2);
}

if (args[0] === '--help' || args[0] === '-h') {
  process.stdout.write(HELP + '\n');
  process.exit(0);
}

if (args[0] === '--version' || args[0] === '-v') {
  process.stdout.write(VERSION + '\n');
  process.exit(0);
}

const result = slugify(args[0]);

if (result.length === 0) {
  process.stderr.write('Error: empty result after processing\n');
  process.exit(3);
}

process.stdout.write(result + '\n');
process.exit(0);
