#!/usr/bin/env node

const VERSION = '1.0.0';

function slugify(title) {
  // Rule 1: Lowercase
  let result = title.toLowerCase();

  // Rule 2: Strip leading/trailing whitespace
  result = result.trim();

  // Rule 3: Replace any run of whitespace with a single -
  result = result.replace(/\s+/g, '-');

  // Rule 4: Remove characters that are not [a-z0-9-]
  result = result.replace(/[^a-z0-9-]/g, '');

  // Rule 5: Collapse multiple consecutive - into a single -
  result = result.replace(/-+/g, '-');

  // Rule 6: Strip leading and trailing -
  result = result.replace(/^-|-$/g, '');

  // Rule 7: If result exceeds 60 characters: truncate to 60 characters then strip a trailing - if any
  if (result.length > 60) {
    result = result.substring(0, 60);
    result = result.replace(/-$/g, '');
  }

  return result;
}

function printVersion() {
  console.log(`slugify v${VERSION}`);
}

function printHelp() {
  console.log('Usage: node slugify.mjs "<title>"');
  console.log('Options:');
  console.log('  --help       Show this help message');
  console.log('  --version    Show version information');
}

function main() {
  const args = process.argv.slice(2);

  // Check for --help
  if (args.includes('--help')) {
    printHelp();
    process.exit(0);
  }

  // Check for --version
  if (args.includes('--version')) {
    printVersion();
    process.exit(0);
  }

  // No argument provided
  if (args.length === 0) {
    console.error('Error: No input title provided');
    process.exit(2);
  }

  const title = args[0];
  const slug = slugify(title);

  // Empty result after processing
  if (slug === '') {
    console.error('Error: Empty result after processing');
    process.exit(3);
  }

  // Output without trailing newline
  process.stdout.write(slug);
}

main();
