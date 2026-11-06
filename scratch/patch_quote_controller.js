const fs = require('fs');
const path = require('path');

const targetFile = path.join(__dirname, '../BE/controllers/v2/quoteControllerV2.js');
let code = fs.readFileSync(targetFile, 'utf8');

// 1. Update sanitizeQuoteForCustomer
const oldSanitize = `function sanitizeQuoteForCustomer(quote) {
  const isSentOrPaid = [
    'quotation_sent',
    'quotation_accepted',
    'payment_pending',
    'paid',
    'converted_to_order',
    'Quote Sent',
    'Quotation Sent',
    'Accepted',
    'Converted to Booking',
    'Converted',
  ].includes(quote.status);

  const plain = quote.toObject ? quote.toObject() : { ...quote };

  if (!isSentOrPaid) {
    // Hide prices completely
    plain.items = (plain.items || []).map((item) => ({
      _id: item._id,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: null,
      lineTotal: null,
    }));
    plain.subtotal = null;
    plain.gstAmount = null;
    plain.finalAmount = null;
    plain.pricingStatus = 'Pricing Under Review by TechBes Admin';
  } else {
    plain.pricingStatus = 'Pricing Ready';
  }

  return plain;
}`;

const newSanitize = `function sanitizeQuoteForCustomer(quote) {
  const isSentOrPaid = [
    'quotation_sent',
    'quotation_accepted',
    'advance_paid',
    'payment_pending',
    'balance_pending',
    'paid',
    'converted_to_order',
    'Quote Sent',
    'Quotation Sent',
    'Accepted',
    'Converted to Booking',
    'Converted',
  ].includes(quote.status);

  const plain = quote.toObject ? quote.toObject() : { ...quote };

  if (!isSentOrPaid) {
    // Hide prices completely
    plain.items = (plain.items || []).map((item) => ({
      _id: item._id,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: null,
      lineTotal: null,
    }));
    plain.subtotal = null;
    plain.gstAmount = null;
    plain.finalAmount = null;
    plain.pricingBreakdown = null;
    plain.advancePercentage = null;
    plain.advanceAmount = null;
    plain.advancePaidAmount = null;
    plain.balanceAmount = null;
    plain.balancePaidAmount = null;
    plain.pricingStatus = 'Pricing Under Review by TechBes Admin';
  } else {
    plain.pricingStatus = 'Pricing Ready';
    const finalAmount = Number(plain.finalAmount || 0);
    const advPct = typeof plain.advancePercentage === 'number' ? plain.advancePercentage : 50;
    plain.advancePercentage = advPct;
    if (plain.advanceAmount === undefined || plain.advanceAmount === null || plain.advanceAmount === 0) {
      plain.advanceAmount = Math.round(((finalAmount * advPct) / 100) * 100) / 100;
    }
    const advPaid = Number(plain.advancePaidAmount || 0);
    if (plain.balanceAmount === undefined || plain.balanceAmount === null) {
      plain.balanceAmount = Math.max(0, Math.round((finalAmount - advPaid) * 100) / 100);
    }
    plain.pricingBreakdown = plain.pricingBreakdown || {
      labourCharge: 0,
      serviceCharge: 0,
      accessoriesCharge: 0,
      miscCharge: 0,
    };
  }

  // Include job status if linked
  if (plain.orderId && typeof plain.orderId === 'object' && plain.orderId.status) {
    plain.jobStatus = plain.orderId.status;
  }

  return plain;
}`;

if (!code.includes('function sanitizeQuoteForCustomer(quote)')) {
  console.error('Could not find sanitizeQuoteForCustomer');
  process.exit(1);
}

code = code.replace(oldSanitize, newSanitize);

// Update getCustomerQuotes & getQuoteDetailsForCustomer to populate orderId
code = code.replace(
  `const quotes = await QuoteRequest.find(filter).sort({ createdAt: -1 });`,
  `const quotes = await QuoteRequest.find(filter).populate('orderId', 'status scheduledTime technicianName assignedTechnician').sort({ createdAt: -1 });`
);

code = code.replace(
  `      quote = await QuoteRequest.findOne({ requestId: id });\n    } else {\n      quote = await QuoteRequest.findById(id);\n    }`,
  `      quote = await QuoteRequest.findOne({ requestId: id }).populate('orderId', 'status scheduledTime technicianName assignedTechnician');\n    } else {\n      quote = await QuoteRequest.findById(id).populate('orderId', 'status scheduledTime technicianName assignedTechnician');\n    }`
);

fs.writeFileSync(targetFile, code, 'utf8');
console.log('Sanitize and customer quotes patched successfully');
