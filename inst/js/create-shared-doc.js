#!/usr/bin/env node

/**
 * Example 1: Create a document in JavaScript for loading in R
 *
 * Usage: node create-shared-doc.js [output-path]
 * Default output: shared_doc.automerge
 */

const Automerge = require('@automerge/automerge');
const fs = require('fs');

// Get output path from command line or use default
const outputPath = process.argv[2] || 'shared_doc.automerge';

// Create a document
let doc = Automerge.init();

// Add some data
doc = Automerge.change(doc, 'Initial data', doc => {
  doc.title = 'Collaborative Analysis';
  doc.datasets = [];
  doc.datasets.push({ name: 'sales_2024', rows: 1000 });
  doc.datasets.push({ name: 'customers', rows: 5000 });
  doc.metadata = {
    created_by: 'javascript',
    created_at: new Date().toISOString(),
    version: '1.0'
  };
});

// Save to binary format
const bytes = Automerge.save(doc);

// Write to file
fs.writeFileSync(outputPath, bytes);

console.log('Document created and saved to:', outputPath);
console.log('Actor ID:', Automerge.getActorId(doc));
console.log('Document size:', bytes.length, 'bytes');
console.log('Keys:', Object.keys(doc).join(', '));
