const fs = require('fs');
let c = fs.readFileSync('BE/routes/v2/adminRoutesV2.js', 'utf8');
c = c.replace(
  `router.post('/quotes/:id/convert', quoteControllerV2.convertToBooking);`,
  `router.post('/quotes/:id/convert', quoteControllerV2.convertToBooking);\nrouter.get('/quotes/:id/invoice', quoteControllerV2.getQuotationInvoice);\nrouter.get('/quotes/:id/invoice/:paymentType', quoteControllerV2.getQuotationInvoice);`
);
fs.writeFileSync('BE/routes/v2/adminRoutesV2.js', c, 'utf8');
console.log('adminRoutesV2 updated');
