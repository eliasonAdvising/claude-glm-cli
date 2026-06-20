#!/usr/bin/env node
// slugify.mjs — turn a title into a URL slug

const VERSION = '1.0.0';
const HELP = `Usage: node slugify.mjs "<title>"
       node slugify.mjs --help
       node slugify.mjs --version

Turns a title into a URL-safe slug.`;

function slugify(input) {
  let s = String(input);
  // 1. Lowercase
  s = s.toLowerCase();
  // 2. Strip leading/trailing whitespace
  s = s.replace(/^\s+|\s+$/g, '');
  // 3. Replace any run of whitespace with a single '-'
  s = s.replace(/\s+/g, '-');
  // 4. Remove characters that are not [a-z0-9-]
  s = s.replace(/[^a-z0-9-]/g, '');
  // 5. Collapse multiple consecutive '-' into a single '-'
  s = s.replace(/-+/g, '-');
  // 6. Strip leading and trailing '-'
  s = s.replace(/^-+|-+$/g, '');
  // 7. Truncate to 60, strip trailing '-' if any
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

const first = args[0];

if (first === '--help' || first === '-h') {
  process.stdout.write(HELP + '\n');
  process.exit(0);
}

if (first === '--version' || first === '-v') {
  process.stdout.write(VERSION + '\n');
  process.exit(0);
}

const result = slugify(first);

if (result.length === 0) {
  process.stderr.write('Error: empty result after processing\n');
  process.exit(3);
}

process.stdout.write(result + '\n');
process.exit(0);
