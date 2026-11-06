/**
 * TechBes – Admin Quotation Sync + Balance Payment E2E Test Suite
 * Tests 9 required scenarios with real MongoDB operations and assertions.
 */
require('../BE/node_modules/dotenv').config({ path: 'BE/.env' });
const mongoose = require('../BE/node_modules/mongoose');
const assert = require('assert');

// Models
const QuoteRequest = require('../BE/models/QuoteRequest');
const Job = require('../BE/models/Job');
const Payment = require('../BE/models/Payment');
const User = require('../BE/models/User');
const Notification = require('../BE/models/Notification');

// Controllers & Services
const quoteControllerV2 = require('../BE/controllers/v2/quoteControllerV2');
const paymentControllerV2 = require('../BE/controllers/v2/paymentControllerV2');

// Mock req / res helpers
function createMockReq(params = {}, body = {}, user = null, query = {}) {
  const req = {
    params,
    body,
    query,
    user: user || { id: new mongoose.Types.ObjectId().toString(), role: 'client' },
    headers: { host: 'localhost:5000' },
    app: {
      get: (k) => {
        if (k === 'io') {
          return {
            to: () => ({ emit: () => {} }),
            emit: () => {},
          };
        }
        return null;
      },
    },
  };
  return req;
}

function createMockRes() {
  const res = {
    statusCode: 200,
    jsonData: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.jsonData = data;
      return this;
    },
    send(text) {
      this.textData = text;
      return this;
    },
  };
  return res;
}

async function runTests() {
  console.log('================================================================');
  console.log('TECHBES – ADMIN QUOTATION SYNC + BALANCE PAYMENT VALIDATION SUITE');
  console.log('================================================================\n');

  const testReport = [];
  const testMobile = '9876543210';
  const testCustomerEmail = 'quote_customer_test@techbes.co.in';

  try {
    // 0. Connect to MongoDB
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB Atlas successfully.\n');

    // Setup Test Customer and Admin Users
    let customerUser = await User.findOne({ mobileNumber: testMobile });
    if (!customerUser) {
      customerUser = await User.create({
        name: 'Test Quotation Customer',
        mobileNumber: testMobile,
        email: testCustomerEmail,
        password: 'password123',
        role: 'client',
        userType: 'web_user',
      });
    }

    let adminUser = await User.findOne({ role: 'admin' });
    if (!adminUser) {
      adminUser = await User.create({
        name: 'Test Admin',
        mobileNumber: '9999988888',
        email: 'test_admin@techbes.co.in',
        password: 'adminpassword',
        role: 'admin',
      });
    }

    // Create a base quotation request
    const year = new Date().getFullYear();
    const testReqId = `QT-${year}-${Math.floor(Math.random() * 90000) + 10000}`;
    const initialQuote = await QuoteRequest.create({
      requestId: testReqId,
      customerId: customerUser._id,
      fullName: 'Test Quotation Customer',
      mobile: testMobile,
      email: testCustomerEmail,
      serviceCategory: 'CCTV',
      subcategory: 'Install New CCTV',
      locality: 'Koramangala, Bangalore',
      address: 'Plot 123, 5th Block, Koramangala, Bangalore 560095',
      propertyType: 'Residential',
      cameraCount: 4,
      status: 'quotation_requested',
      items: [
        {
          productName: '4MP IP Dome Camera',
          quantity: 4,
          unitPrice: null,
          lineTotal: null,
        },
        {
          productName: '8-Channel 4K NVR',
          quantity: 1,
          unitPrice: null,
          lineTotal: null,
        },
        {
          productName: '2TB Surveillance Hard Disk',
          quantity: 1,
          unitPrice: null,
          lineTotal: null,
        },
      ],
    });
    console.log(`Created Initial Quote Request: ${initialQuote.requestId} (ID: ${initialQuote._id})\n`);

    // -------------------------------------------------------------
    // TEST 1: Admin edits quotation -> Save Draft -> Customer sees updated quotation
    // -------------------------------------------------------------
    console.log('--- TEST 1: Admin edits quotation -> Save Draft -> Customer sees updated quotation ---');
    try {
      const editItems = [
        { productName: '4MP IP Dome Camera', quantity: 4, unitPrice: 2500 }, // 10,000
        { productName: '8-Channel 4K NVR', quantity: 1, unitPrice: 6000 },   // 6,000
        { productName: '2TB Surveillance Hard Disk', quantity: 1, unitPrice: 4000 }, // 4,000
      ];
      const pricingBreakdown = {
        labourCharge: 2000,
        serviceCharge: 1000,
        accessoriesCharge: 1500,
        miscCharge: 500,
      }; // Extra charges: 5,000. Total items: 20,000. Subtotal: 25,000.
      // GST 18% of 25,000 = 4,500. Grand Total = 29,500.
      // 50% Advance = 14,750. Balance = 14,750.

      const req1 = createMockReq(
        { id: initialQuote._id.toString() },
        {
          items: editItems,
          pricingBreakdown,
          advancePercentage: 50,
          gstRate: 18,
          validityDays: 15,
          adminNotes: 'Includes installation, Cat6 cabling and 1-year on-site support.',
          terms: '1. 50% advance on confirmation, 50% on completion.\n2. 1-Year hardware warranty.',
          saveAsDraft: true,
        },
        adminUser
      );
      const res1 = createMockRes();

      await quoteControllerV2.priceQuotation(req1, res1, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(res1.statusCode, 200, 'Expected 200 OK');
      const savedQuote = res1.jsonData?.data;
      assert.strictEqual(savedQuote.status, 'quotation_draft', 'Expected status to be quotation_draft');
      assert.strictEqual(savedQuote.subtotal, 25000, 'Expected subtotal = 25000');
      assert.strictEqual(savedQuote.gstAmount, 4500, 'Expected GST = 4500');
      assert.strictEqual(savedQuote.finalAmount, 29500, 'Expected finalAmount = 29500');
      assert.strictEqual(savedQuote.advancePercentage, 50, 'Expected advancePercentage = 50');
      assert.strictEqual(savedQuote.advanceAmount, 14750, 'Expected advanceAmount = 14750');
      assert.strictEqual(savedQuote.balanceAmount, 14750, 'Expected balanceAmount = 14750');
      assert.strictEqual(savedQuote.pricingBreakdown?.labourCharge, 2000, 'Expected labourCharge = 2000');

      // Verify customer view fetches updated quotation
      const reqCust = createMockReq({ id: initialQuote._id.toString() }, {}, customerUser);
      const resCust = createMockRes();
      await quoteControllerV2.getQuoteDetailsForCustomer(reqCust, resCust, (err) => {
        if (err) throw err;
      });
      assert.strictEqual(resCust.statusCode, 200, 'Customer view should return 200 OK');
      // For draft, customer does not see prices yet (sanitized)
      assert.strictEqual(resCust.jsonData?.data?.pricingStatus, 'Pricing Under Review by TechBes Admin');

      console.log('✅ TEST 1 PASS: Draft saved with subtotal ₹25,000, GST ₹4,500, Total ₹29,500, Advance ₹14,750, Balance ₹14,750.');
      testReport.push({ id: 1, name: 'Admin edits quotation -> Save Draft', status: 'PASS', details: 'MongoDB updated with authoritative breakdown; customer state sanitized while in draft' });
    } catch (e) {
      console.error('❌ TEST 1 FAIL:', e.message);
      testReport.push({ id: 1, name: 'Admin edits quotation -> Save Draft', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 2: Admin sends quotation -> Customer receives notification
    // -------------------------------------------------------------
    console.log('\n--- TEST 2: Admin sends quotation -> Customer receives notification ---');
    try {
      const req2 = createMockReq({ id: initialQuote._id.toString() }, {}, adminUser);
      const res2 = createMockRes();

      await quoteControllerV2.sendQuotation(req2, res2, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(res2.statusCode, 200, 'Expected 200 OK');
      const sentQuote = res2.jsonData?.data?.quote;
      assert.strictEqual(sentQuote.status, 'quotation_sent', 'Expected status to be quotation_sent');
      assert.ok(sentQuote.sentAt, 'Expected sentAt date to be populated');
      assert.ok(sentQuote.validUntil, 'Expected validUntil date to be populated');
      assert.ok(res2.jsonData?.data?.pdfUrl, 'Expected authoritative PDF URL');

      // Verify notification created for customer
      const customerNotif = await Notification.findOne({
        userId: customerUser._id,
        type: 'quotation_sent',
      }).sort({ createdAt: -1 });

      assert.ok(customerNotif, 'Customer should receive in-app notification for sent quotation');
      assert.ok(customerNotif.message.includes('₹29,500'), 'Notification should include formatted total amount');

      // Verify customer can now see full price breakdown
      const reqCust2 = createMockReq({ id: initialQuote._id.toString() }, {}, customerUser);
      const resCust2 = createMockRes();
      await quoteControllerV2.getQuoteDetailsForCustomer(reqCust2, resCust2, (err) => {
        if (err) throw err;
      });
      assert.strictEqual(resCust2.jsonData?.data?.finalAmount, 29500, 'Customer view now displays ₹29,500');
      assert.strictEqual(resCust2.jsonData?.data?.advanceAmount, 14750, 'Customer view displays ₹14,750 advance');
      assert.strictEqual(resCust2.jsonData?.data?.balanceAmount, 14750, 'Customer view displays ₹14,750 balance');

      console.log('✅ TEST 2 PASS: Quotation marked quotation_sent; customer notification generated with ₹29,500 total and ₹14,750 advance.');
      testReport.push({ id: 2, name: 'Admin sends quotation -> Customer notified', status: 'PASS', details: 'Status=quotation_sent, customer in-app notification verified, pricing unlocked' });
    } catch (e) {
      console.error('❌ TEST 2 FAIL:', e.message);
      testReport.push({ id: 2, name: 'Admin sends quotation -> Customer notified', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 3: Customer accepts quotation -> Advance payment becomes available
    // -------------------------------------------------------------
    console.log('\n--- TEST 3: Customer accepts quotation -> Advance payment becomes available ---');
    try {
      const req3 = createMockReq({ id: initialQuote._id.toString() }, { notes: 'Approved for installation this week' }, customerUser);
      const res3 = createMockRes();

      await quoteControllerV2.acceptQuote(req3, res3, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(res3.statusCode, 200, 'Expected 200 OK');
      assert.strictEqual(res3.jsonData?.data?.status, 'quotation_accepted', 'Expected status to be quotation_accepted');

      // Create Payment Order for Advance
      const reqOrder = createMockReq({ id: initialQuote._id.toString() }, { paymentType: 'advance' }, customerUser);
      const resOrder = createMockRes();

      await quoteControllerV2.createPaymentOrder(reqOrder, resOrder, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resOrder.statusCode, 200, 'Expected 200 OK for payment order creation');
      const orderData = resOrder.jsonData?.data;
      assert.strictEqual(orderData.amount, 1475000, 'Expected order amount in paise to be 1,475,000 (₹14,750.00)');
      assert.strictEqual(orderData.displayAmount, 14750, 'Expected displayAmount = ₹14,750');
      assert.strictEqual(orderData.paymentType, 'advance', 'Expected paymentType = advance');
      assert.ok(orderData.orderId, 'Expected razorpay orderId');

      console.log(`✅ TEST 3 PASS: Quotation accepted; Razorpay order created for 50% advance: ${orderData.orderId} (₹14,750).`);
      testReport.push({ id: 3, name: 'Customer accepts quotation -> Advance payment available', status: 'PASS', details: `Order created for advance = ₹14,750 (1,475,000 paise)` });
    } catch (e) {
      console.error('❌ TEST 3 FAIL:', e.message);
      testReport.push({ id: 3, name: 'Customer accepts quotation -> Advance payment available', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 4: Customer pays advance -> Dashboard reflects paid amount and balance
    // -------------------------------------------------------------
    console.log('\n--- TEST 4: Customer pays advance -> Dashboard reflects paid amount and balance ---');
    try {
      // Find the pending payment order
      const updatedQuote = await QuoteRequest.findById(initialQuote._id);
      const razorpayOrderId = updatedQuote.advancePaymentDetails?.razorpayOrderId || `order_adv_${Date.now()}`;
      const razorpayPaymentId = `pay_adv_${Date.now()}`;

      const reqVerifyAdv = createMockReq(
        { id: initialQuote._id.toString() },
        {
          razorpay_order_id: razorpayOrderId,
          razorpay_payment_id: razorpayPaymentId,
          razorpay_signature: 'test_advance_sig',
          paymentType: 'advance',
          mockSuccess: true,
        },
        customerUser
      );
      const resVerifyAdv = createMockRes();

      await quoteControllerV2.verifyQuotePayment(reqVerifyAdv, resVerifyAdv, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resVerifyAdv.statusCode, 200, 'Expected 200 OK for advance verification');
      const verifyData = resVerifyAdv.jsonData?.data;
      assert.strictEqual(verifyData.amountPaid, 14750, 'Expected amountPaid = ₹14,750');
      assert.strictEqual(verifyData.advancePaidAmount, 14750, 'Expected advancePaidAmount = ₹14,750');
      assert.strictEqual(verifyData.balanceAmount, 14750, 'Expected balanceAmount = ₹14,750');
      assert.ok(verifyData.invoiceNumber, 'Expected invoiceNumber to be generated');
      assert.ok(verifyData.orderNumber, 'Expected sequential orderNumber to be generated');
      assert.ok(verifyData.orderId, 'Expected Job to be automatically created');

      // Check linked Job
      const linkedJob = await Job.findById(verifyData.orderId);
      assert.ok(linkedJob, 'Job record must exist in DB');
      assert.strictEqual(linkedJob.advancePaid, true, 'Job.advancePaid must be true');
      assert.strictEqual(linkedJob.advanceAmount, 14750, 'Job.advanceAmount must be 14750');
      assert.strictEqual(linkedJob.remainingAmount, 14750, 'Job.remainingAmount must be 14750');
      assert.strictEqual(linkedJob.paymentStatus, 'advance_paid', 'Job.paymentStatus must be advance_paid');

      // Verify Payment record
      const advPayment = await Payment.findOne({
        quoteId: initialQuote._id,
        paymentType: 'advance',
        status: 'paid',
      });
      assert.ok(advPayment, 'Advance Payment record must exist with paymentType=advance');
      assert.strictEqual(advPayment.amount, 1475000, 'Payment amount must be 1,475,000 paise');

      console.log(`✅ TEST 4 PASS: Advance payment verified; Order #${verifyData.orderNumber} created; Job linked with advancePaid=true, remainingAmount=₹14,750.`);
      testReport.push({ id: 4, name: 'Customer pays advance -> Dashboard reflects paid & balance', status: 'PASS', details: `Advance paid: ₹14,750, Balance remaining: ₹14,750, Invoice: ${verifyData.invoiceNumber}` });
    } catch (e) {
      console.error('❌ TEST 4 FAIL:', e.message);
      testReport.push({ id: 4, name: 'Customer pays advance -> Dashboard reflects paid & balance', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 5: Technician completes job -> Balance payment becomes available
    // -------------------------------------------------------------
    console.log('\n--- TEST 5: Technician completes job -> Balance payment becomes available ---');
    try {
      const currentQuote = await QuoteRequest.findById(initialQuote._id);
      const linkedJob = await Job.findById(currentQuote.orderId);

      // Attempt balance payment while job is still pending -> Must be rejected!
      const reqEarlyBal = createMockReq({ id: initialQuote._id.toString() }, { paymentType: 'balance' }, customerUser);
      const resEarlyBal = createMockRes();

      await quoteControllerV2.createPaymentOrder(reqEarlyBal, resEarlyBal, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resEarlyBal.statusCode, 400, 'Balance payment should be rejected before job completion');
      assert.ok(resEarlyBal.jsonData?.message?.includes('after job completion'), 'Error message should indicate job not completed');

      // Now technician completes the job
      linkedJob.status = 'completed';
      linkedJob.completedAt = new Date();
      await linkedJob.save();

      // Now create balance payment order -> Must succeed!
      const reqBalOrder = createMockReq({ id: initialQuote._id.toString() }, { paymentType: 'balance' }, customerUser);
      const resBalOrder = createMockRes();

      await quoteControllerV2.createPaymentOrder(reqBalOrder, resBalOrder, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resBalOrder.statusCode, 200, 'Balance payment order should succeed once job is completed');
      const balOrderData = resBalOrder.jsonData?.data;
      assert.strictEqual(balOrderData.amount, 1475000, 'Expected balance order amount = 1,475,000 paise');
      assert.strictEqual(balOrderData.displayAmount, 14750, 'Expected balance displayAmount = ₹14,750');
      assert.strictEqual(balOrderData.paymentType, 'balance', 'Expected paymentType = balance');

      console.log(`✅ TEST 5 PASS: Balance payment correctly blocked while job pending (400), unlocked upon completion (200, Order: ${balOrderData.orderId}).`);
      testReport.push({ id: 5, name: 'Technician completes job -> Balance payment available', status: 'PASS', details: 'Blocked while pending (400), unlocked when completed (200, ₹14,750)' });
    } catch (e) {
      console.error('❌ TEST 5 FAIL:', e.message);
      testReport.push({ id: 5, name: 'Technician completes job -> Balance payment available', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 6: Customer pays balance -> Outstanding balance becomes ₹0
    // -------------------------------------------------------------
    console.log('\n--- TEST 6: Customer pays balance -> Outstanding balance becomes ₹0 ---');
    try {
      const currentQuote = await QuoteRequest.findById(initialQuote._id);
      const balOrderId = currentQuote.balancePaymentDetails?.razorpayOrderId || `order_bal_${Date.now()}`;
      const balPaymentId = `pay_bal_${Date.now()}`;

      const reqVerifyBal = createMockReq(
        { id: initialQuote._id.toString() },
        {
          razorpay_order_id: balOrderId,
          razorpay_payment_id: balPaymentId,
          razorpay_signature: 'test_balance_sig',
          paymentType: 'balance',
          mockSuccess: true,
        },
        customerUser
      );
      const resVerifyBal = createMockRes();

      await quoteControllerV2.verifyQuotePayment(reqVerifyBal, resVerifyBal, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resVerifyBal.statusCode, 200, 'Expected 200 OK for balance verification');
      const balData = resVerifyBal.jsonData?.data;
      assert.strictEqual(balData.balanceAmount, 0, 'Expected balanceAmount = 0');
      assert.strictEqual(balData.paymentStatus, 'fully_paid', 'Expected paymentStatus = fully_paid');

      // Verify DB Quote state
      const finalizedQuote = await QuoteRequest.findById(initialQuote._id);
      assert.strictEqual(finalizedQuote.status, 'paid', 'Quote.status must be paid');
      assert.strictEqual(finalizedQuote.quotePaymentStatus, 'fully_paid', 'Quote.quotePaymentStatus must be fully_paid');
      assert.strictEqual(finalizedQuote.balanceAmount, 0, 'Quote.balanceAmount must be 0');
      assert.strictEqual(finalizedQuote.balancePaidAmount, 14750, 'Quote.balancePaidAmount must be 14750');
      assert.ok(finalizedQuote.paidAt, 'paidAt date must be recorded');

      // Verify DB Job state
      const finalizedJob = await Job.findById(finalizedQuote.orderId);
      assert.strictEqual(finalizedJob.paymentStatus, 'paid', 'Job.paymentStatus must be paid');
      assert.strictEqual(finalizedJob.remainingAmount, 0, 'Job.remainingAmount must be 0');

      console.log('✅ TEST 6 PASS: Balance payment of ₹14,750 verified; outstanding balance = ₹0; status = fully_paid / paid.');
      testReport.push({ id: 6, name: 'Customer pays balance -> Outstanding balance becomes ₹0', status: 'PASS', details: 'Balance paid: ₹14,750, Outstanding balance: ₹0, Status: fully_paid' });
    } catch (e) {
      console.error('❌ TEST 6 FAIL:', e.message);
      testReport.push({ id: 6, name: 'Customer pays balance -> Outstanding balance becomes ₹0', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 7: Duplicate Razorpay webhook -> No duplicate payment
    // -------------------------------------------------------------
    console.log('\n--- TEST 7: Duplicate Razorpay webhook -> No duplicate payment ---');
    try {
      const advPayment = await Payment.findOne({ quoteId: initialQuote._id, paymentType: 'advance' });
      assert.ok(advPayment, 'Advance payment record must exist');

      const initialPaymentCount = await Payment.countDocuments({ quoteId: initialQuote._id });

      // Simulate webhook payload for payment.captured on existing order
      const webhookPayload = {
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: advPayment.razorpayPaymentId,
              order_id: advPayment.razorpayOrderId,
              amount: advPayment.amount,
              currency: 'INR',
              status: 'captured',
            },
          },
        },
      };

      const crypto = require('crypto');
      const { keySecret } = require('../BE/config/razorpay').getRazorpayCredentials();
      const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || keySecret;
      const signature = crypto.createHmac('sha256', webhookSecret).update(Buffer.from(JSON.stringify(webhookPayload))).digest('hex');

      const reqWebhook = {
        headers: { 'x-razorpay-signature': signature },
        body: webhookPayload,
        rawBody: Buffer.from(JSON.stringify(webhookPayload)),
      };
      const resWebhook = createMockRes();

      await paymentControllerV2.webhookHandler(reqWebhook, resWebhook, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resWebhook.statusCode, 200, 'Expected 200 OK from webhook handler');
      assert.strictEqual(resWebhook.jsonData?.idempotent, true, 'Expected idempotent: true for duplicate webhook');

      const finalPaymentCount = await Payment.countDocuments({ quoteId: initialQuote._id });
      assert.strictEqual(finalPaymentCount, initialPaymentCount, 'Payment count must not increase on duplicate webhook callback');

      console.log('✅ TEST 7 PASS: Duplicate webhook safely ignored (idempotent: true); payment count remained strictly constant.');
      testReport.push({ id: 7, name: 'Duplicate Razorpay webhook -> Idempotent handling', status: 'PASS', details: 'Duplicate callback caught; no duplicate payments recorded; idempotent: true' });
    } catch (e) {
      console.error('❌ TEST 7 FAIL:', e.message);
      testReport.push({ id: 7, name: 'Duplicate Razorpay webhook -> Idempotent handling', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 8: Failed payment -> Balance and payment status remain correct
    // -------------------------------------------------------------
    console.log('\n--- TEST 8: Failed payment -> Balance and payment status remain correct ---');
    try {
      // Create a test quote to simulate failed payment
      const failedQuote = await QuoteRequest.create({
        requestId: `QT-${year}-${Math.floor(Math.random() * 90000) + 10000}`,
        customerId: customerUser._id,
        fullName: 'Test Failed Customer',
        mobile: testMobile,
        email: testCustomerEmail,
        serviceCategory: 'Networking',
        subcategory: 'Office LAN Setup',
        locality: 'Whitefield, Bangalore',
        address: 'ITPB Tech Park, Whitefield, Bangalore',
        status: 'quotation_sent',
        finalAmount: 10000,
        advancePercentage: 50,
        advanceAmount: 5000,
        advancePaidAmount: 0,
        balanceAmount: 5000,
        balancePaidAmount: 0,
        quotePaymentStatus: 'unpaid',
      });

      // Initiate order
      const reqOrder = createMockReq({ id: failedQuote._id.toString() }, { paymentType: 'advance' }, customerUser);
      const resOrder = createMockRes();
      await quoteControllerV2.createPaymentOrder(reqOrder, resOrder, (err) => {
        if (err) throw err;
      });

      const failedOrderId = resOrder.jsonData?.data?.orderId;

      // Simulate payment.failed webhook
      const failedWebhookPayload = {
        event: 'payment.failed',
        payload: {
          payment: {
            entity: {
              id: `pay_failed_${Date.now()}`,
              order_id: failedOrderId,
              amount: 500000,
              currency: 'INR',
              status: 'failed',
              error_code: 'BAD_REQUEST_ERROR',
              error_description: 'Payment failed due to insufficient funds',
            },
          },
        },
      };

      const crypto = require('crypto');
      const { keySecret } = require('../BE/config/razorpay').getRazorpayCredentials();
      const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || keySecret;
      const signature = crypto.createHmac('sha256', webhookSecret).update(Buffer.from(JSON.stringify(failedWebhookPayload))).digest('hex');

      const reqFailWebhook = {
        headers: { 'x-razorpay-signature': signature },
        body: failedWebhookPayload,
        rawBody: Buffer.from(JSON.stringify(failedWebhookPayload)),
      };
      const resFailWebhook = createMockRes();

      await paymentControllerV2.webhookHandler(reqFailWebhook, resFailWebhook, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resFailWebhook.statusCode, 200, 'Webhook returns 200');

      // Verify that the Payment was marked failed
      const payRecord = await Payment.findOne({ razorpayOrderId: failedOrderId });
      assert.strictEqual(payRecord?.status, 'failed', 'Payment status should be failed');

      // Verify quote amounts remain intact and not marked paid
      const refreshedQuote = await QuoteRequest.findById(failedQuote._id);
      assert.strictEqual(refreshedQuote.advancePaidAmount, 0, 'advancePaidAmount must remain 0');
      assert.strictEqual(refreshedQuote.balanceAmount, 5000, 'balanceAmount must remain 5000');
      assert.strictEqual(refreshedQuote.quotePaymentStatus, 'unpaid', 'quotePaymentStatus must remain unpaid');

      console.log('✅ TEST 8 PASS: Payment failure correctly recorded as status: failed; quotation balance and unpaid status preserved.');
      testReport.push({ id: 8, name: 'Failed payment -> Balance and status preserved', status: 'PASS', details: 'Payment marked failed; advancePaidAmount remained 0; balance preserved' });
    } catch (e) {
      console.error('❌ TEST 8 FAIL:', e.message);
      testReport.push({ id: 8, name: 'Failed payment -> Balance and status preserved', status: 'FAIL', error: e.message });
    }

    // -------------------------------------------------------------
    // TEST 9: Admin payment records show advance and balance separately
    // -------------------------------------------------------------
    console.log('\n--- TEST 9: Admin payment records show advance and balance separately ---');
    try {
      // Query advance payments
      const reqAdvQuery = createMockReq({}, {}, adminUser, { paymentType: 'advance' });
      const resAdvQuery = createMockRes();
      await paymentControllerV2.getAllPayments(reqAdvQuery, resAdvQuery, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resAdvQuery.statusCode, 200, 'Expected 200 OK');
      const advancePayments = resAdvQuery.jsonData?.data || [];
      assert.ok(advancePayments.length > 0, 'Must return advance payments');
      assert.ok(advancePayments.every((p) => p.paymentType === 'advance'), 'All items must have paymentType=advance');

      // Query balance payments
      const reqBalQuery = createMockReq({}, {}, adminUser, { paymentType: 'balance' });
      const resBalQuery = createMockRes();
      await paymentControllerV2.getAllPayments(reqBalQuery, resBalQuery, (err) => {
        if (err) throw err;
      });

      assert.strictEqual(resBalQuery.statusCode, 200, 'Expected 200 OK');
      const balancePayments = resBalQuery.jsonData?.data || [];
      assert.ok(balancePayments.length > 0, 'Must return balance payments');
      assert.ok(balancePayments.every((p) => p.paymentType === 'balance'), 'All items must have paymentType=balance');

      // Check invoice retrieval endpoint
      const reqInv = createMockReq({ id: initialQuote._id.toString(), paymentType: 'advance' }, {}, customerUser);
      const resInv = createMockRes();
      await quoteControllerV2.getQuotationInvoice(reqInv, resInv, (err) => {
        if (err) throw err;
      });
      assert.strictEqual(resInv.statusCode, 200, 'Invoice endpoint should return 200 OK');
      const invData = resInv.jsonData?.data;
      assert.strictEqual(invData.amountPaid, 14750, 'Invoice amountPaid = 14750');
      assert.ok(invData.invoiceNumber.startsWith('INV-ADV-'), 'Invoice number should start with INV-ADV-');

      console.log(`✅ TEST 9 PASS: Admin payment query clearly filters advance (${advancePayments.length}) and balance (${balancePayments.length}) separately.`);
      testReport.push({ id: 9, name: 'Admin payment records show advance and balance separately', status: 'PASS', details: `Advance records: ${advancePayments.length}, Balance records: ${balancePayments.length}, Invoices distinct` });
    } catch (e) {
      console.error('❌ TEST 9 FAIL:', e.message);
      testReport.push({ id: 9, name: 'Admin payment records show advance and balance separately', status: 'FAIL', error: e.message });
    }

    // Summary
    console.log('\n================================================================');
    console.log('TEST SUITE EXECUTION SUMMARY');
    console.log('================================================================');
    let passed = 0;
    testReport.forEach((r) => {
      console.log(`Scenario ${r.id}: [${r.status}] ${r.name} - ${r.details || r.error}`);
      if (r.status === 'PASS') passed++;
    });
    console.log(`\nTOTAL: ${passed}/${testReport.length} PASSED.`);

    await mongoose.disconnect();
    process.exit(passed === testReport.length ? 0 : 1);
  } catch (fatal) {
    console.error('Fatal execution error:', fatal);
    process.exit(1);
  }
}

runTests();
