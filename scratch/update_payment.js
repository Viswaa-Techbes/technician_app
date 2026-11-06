const fs = require('fs');
let c = fs.readFileSync('BE/models/Payment.js', 'utf8');
c = c.replace(
  /customerId:\s*\{\s*type:\s*String,\s*default:\s*''\s*\},/,
  `customerId: { type: String, default: '' },\n    paymentType: { type: String, enum: ['advance', 'balance', 'full', 'other'], default: 'full' },\n    quoteId: { type: mongoose.Schema.Types.ObjectId, ref: 'QuoteRequest', default: null },\n    invoiceNumber: { type: String, default: '' },`
);
fs.writeFileSync('BE/models/Payment.js', c, 'utf8');
console.log('Payment.js updated successfully');
