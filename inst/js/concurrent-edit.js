#!/usr/bin/env node

/**
 * Example 3: Make concurrent edits in JavaScript
 *
 * This script loads a base document and makes concurrent edits,
 * simulating what would happen if a JavaScript user edited the
 * document at the same time as an R user.
 *
 * Usage: node concurrent-edit.js <base-doc-path> <output-path>
 */

const Automerge = require('@automerge/automerge');
const fs = require('fs');

// Get paths from command line
const basePath = process.argv[2];
const outputPath = process.argv[3];

if (!basePath || !outputPath) {
  console.error('Usage: node concurrent-edit.js <base-doc-path> <output-path>');
  process.exit(1);
}

if (!fs.existsSync(basePath)) {
  console.error('Error: Base document not found:', basePath);
  process.exit(1);
}

// Load the base document
const baseBytes = fs.readFileSync(basePath);
let doc = Automerge.load(baseBytes);

console.log('Loaded base document from:', basePath);
console.log('Document keys:', Object.keys(doc).join(', '));

// Make concurrent edit in JavaScript
doc = Automerge.change(doc, 'Add JS section', doc => {
  // Add a section to the list
  if (!doc.sections) {
    doc.sections = [];
  }

  doc.sections.push({
    title: 'JavaScript Analysis',
    content: 'Web visualization results',
    author: 'JS Team',
    created_at: new Date().toISOString()
  });

  // Add timestamp for this edit
  doc.js_edit_time = Date.now();
});

console.log('\nJavaScript changes made:');
console.log('  Added section:', doc.sections[doc.sections.length - 1].title);
console.log('  JS edit time:', new Date(doc.js_edit_time).toISOString());
console.log('  Total sections:', doc.sections.length);

// Save the edited document
const outputBytes = Automerge.save(doc);
fs.writeFileSync(outputPath, outputBytes);

console.log('\nDocument saved to:', outputPath);
console.log('Document size:', outputBytes.length, 'bytes');

// Show all changes in this document
const changes = Automerge.getAllChanges(doc);
console.log('Total changes in history:', changes.length);
