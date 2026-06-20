#!/usr/bin/env node

function slugify(input) {
  // Rule 1: Lowercase
  let result = input.toLowerCase();

  // Rule 2: Strip leading/trailing whitespace
  result = result.trim();

  // Rule 3: Replace any run of whitespace with a single `-`
  result = result.replace(/\s+/g, '-');

  // Rule 4: Remove characters that are not `[a-z0-9-]`
  result = result.replace(/[^a-z0-9-]/g, '');

  // Rule 5: Collapse multiple consecutive `-` into a single `-`
  result = result.replace(/-+/g, '-');

  // Rule 6: Strip leading and trailing `-`
  result = result.replace(/^-+|-+$/g, '');

  // Rule 7: If result exceeds 60 characters: truncate to 60 characters then strip a trailing `-` if any
  if (result.length > 60) {
    result = result.substring(0, 60);
    result = result.replace(/-+$/g, '');
  }

  return result;
}

// CLI handling
const args = process.argv.slice(2);

if (args[0] === '--help') {
  console.log('Usage: node slugify.mjs "<title>"');
  console.log('Turns a title into a URL slug.');
  process.exit(0);
}

if (args[0] === '--version') {
  console.log('slugify v1.0.0');
  process.exit(0);
}

if (args.length === 0) {
  console.error('Error: No input provided.');
  process.exit(2);
}

const input = args[0];
const output = slugify(input);

if (output === '') {
  console.error('Error: Empty result after processing.');
  process.exit(3);
}

process.stdout.write(output);
