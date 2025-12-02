#!/usr/bin/env node

/**
 * Example 2: Load a document modified by R and verify changes
 *
 * Usage: node verify-r-changes.js [input-path]
 * Default input: shared_doc.automerge
 */

const Automerge = require('@automerge/automerge');
const fs = require('fs');

// Get input path from command line or use default
const inputPath = process.argv[2] || 'shared_doc.automerge';

if (!fs.existsSync(inputPath)) {
  console.error('Error: File not found:', inputPath);
  process.exit(1);
}

// Load the updated document
const updatedBytes = fs.readFileSync(inputPath);
let updatedDoc = Automerge.load(updatedBytes);

console.log('Document loaded from:', inputPath);
console.log('Title:', updatedDoc.title);

// Check for R analysis
if (updatedDoc.r_analysis) {
  console.log('\n✓ R analysis found!');
  console.log('  Performed by:', updatedDoc.r_analysis.performed_by);
  console.log('  R version:', updatedDoc.r_analysis.R_version);

  if (updatedDoc.r_analysis.summary_stats) {
    console.log('\n  Summary statistics:');
    console.log('    Mean sales:', updatedDoc.r_analysis.summary_stats.mean_sales);
    console.log('    Median sales:', updatedDoc.r_analysis.summary_stats.median_sales);
    console.log('    Total customers:', updatedDoc.r_analysis.summary_stats.total_customers);
  }
} else {
  console.log('\n✗ No R analysis found');
}

// View change history
const changes = Automerge.getAllChanges(updatedDoc);
console.log('\nTotal changes:', changes.length);

// Make additional changes in JavaScript
updatedDoc = Automerge.change(updatedDoc, 'Add JS visualization', doc => {
  doc.visualizations = [];
  doc.visualizations.push({
    type: 'bar_chart',
    data_source: 'r_analysis.summary_stats',
    created_in: 'javascript'
  });
});

// Save back
fs.writeFileSync(inputPath, Automerge.save(updatedDoc));
console.log('\n✓ Added JavaScript visualization and saved');
