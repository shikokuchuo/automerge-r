#!/usr/bin/env node

/**
 * Verify merged document contains both R and JavaScript changes
 *
 * This script loads a merged document and verifies that it contains
 * changes from both R and JavaScript, demonstrating CRDT merge.
 *
 * Usage: node verify-merge.js <merged-doc-path>
 */

const Automerge = require('@automerge/automerge');
const fs = require('fs');

// Get path from command line
const mergedPath = process.argv[2];

if (!mergedPath) {
  console.error('Usage: node verify-merge.js <merged-doc-path>');
  process.exit(1);
}

if (!fs.existsSync(mergedPath)) {
  console.error('Error: Merged document not found:', mergedPath);
  process.exit(1);
}

// Load the merged document
const mergedBytes = fs.readFileSync(mergedPath);
const doc = Automerge.load(mergedBytes);

console.log('Verifying merged document from:', mergedPath);
console.log('Document keys:', Object.keys(doc).join(', '));

// Verify sections
if (!doc.sections || !Array.isArray(doc.sections)) {
  console.error('\n✗ No sections array found');
  process.exit(1);
}

console.log('\n✓ Sections found:', doc.sections.length);

// Look for R section
const rSection = doc.sections.find(s => s.author === 'R Team');
if (rSection) {
  console.log('\n✓ R section found:');
  console.log('  Title:', rSection.title);
  console.log('  Content:', rSection.content);
  console.log('  Author:', rSection.author);
} else {
  console.error('\n✗ R section not found');
  process.exit(1);
}

// Look for JS section
const jsSection = doc.sections.find(s => s.author === 'JS Team');
if (jsSection) {
  console.log('\n✓ JavaScript section found:');
  console.log('  Title:', jsSection.title);
  console.log('  Content:', jsSection.content);
  console.log('  Author:', jsSection.author);
} else {
  console.error('\n✗ JavaScript section not found');
  process.exit(1);
}

// Verify timestamps
if (doc.r_edit_time) {
  console.log('\n✓ R edit timestamp found:', doc.r_edit_time);
} else {
  console.warn('\n⚠ R edit timestamp not found');
}

if (doc.js_edit_time) {
  console.log('✓ JS edit timestamp found:', new Date(doc.js_edit_time).toISOString());
} else {
  console.error('✗ JavaScript edit timestamp not found');
  process.exit(1);
}

// Show change history
const changes = Automerge.getAllChanges(doc);
console.log('\n✓ Total changes in merged document:', changes.length);

// Verify CRDT merge (both changes present)
if (rSection && jsSection) {
  console.log('\n✓✓✓ MERGE VERIFICATION SUCCESSFUL ✓✓✓');
  console.log('Both R and JavaScript changes are present in merged document');
  console.log('CRDT conflict-free merge worked correctly!');
  process.exit(0);
} else {
  console.error('\n✗ Merge verification failed');
  process.exit(1);
}
