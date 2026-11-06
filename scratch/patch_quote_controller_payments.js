const fs = require('fs');
const path = require('path');

const targetFile = path.join(__dirname, '../BE/controllers/v2/quoteControllerV2.js');
let code = fs.readFileSync(targetFile, 'utf8');

// Replace priceQuotation
const oldPriceQuotation = `async function priceQuotation(req, res, next) {
  try {
    const { id } = req.params;
    const { items, gstRate = 18, validityDays = 15, adminNotes, terms, saveAsDraft } = req.body;
    const mongoose = require('mongoose');

    let quote = null;
    if (mongoose.Types.ObjectId.isValid(id)) {
      quote = await QuoteRequest.findById(id);
    }
    if (!quote) {
      quote = await QuoteRequest.findOne({ requestId: id });
    }
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quote Request not found' });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Items array with unit prices is required' });
    }

    let calculatedSubtotal = 0;
    const updatedItems = items.map((item) => {
      const quantity = Math.max(1, parseInt(item.quantity, 10) || 1);
      const unitPrice = Math.max(0, parseFloat(item.unitPrice) || 0);
      const lineTotal = Math.round(quantity * unitPrice * 100) / 100;
      calculatedSubtotal += lineTotal;

      return {
        productName: String(item.productName || item.name || 'Item').trim(),
        quantity,
        unitPrice,
        lineTotal,
      };
    });

    const parsedGstRate = Math.max(0, parseFloat(gstRate) || 18);
    const calculatedGst = Math.round(((calculatedSubtotal * parsedGstRate) / 100) * 100) / 100;
    const calculatedFinal = Math.round((calculatedSubtotal + calculatedGst) * 100) / 100;

    quote.items = updatedItems;
    quote.subtotal = calculatedSubtotal;
    quote.gstRate = parsedGstRate;
    quote.gstAmount = calculatedGst;
    quote.finalAmount = calculatedFinal;
    quote.validityDays = Number(validityDays) || 15;

    if (adminNotes !== undefined) {
      quote.adminNotes = adminNotes;
    }
    if (terms !== undefined) {
      quote.terms = terms;
    }

    quote.status = saveAsDraft ? 'quotation_draft' : 'quotation_draft';
    await quote.save();

    return res.json({
      success: true,
      message: 'Quotation calculated and saved successfully',
      data: quote,
    });
  } catch (err) {
    next(err);
  }
}`;

const newPriceQuotation = `async function priceQuotation(req, res, next) {
  try {
    const { id } = req.params;
    const {
      items,
      pricingBreakdown = {},
      advancePercentage = 50,
      gstRate = 18,
      validityDays = 15,
      adminNotes,
      terms,
      saveAsDraft = true,
    } = req.body;
    const mongoose = require('mongoose');

    let quote = null;
    if (mongoose.Types.ObjectId.isValid(id)) {
      quote = await QuoteRequest.findById(id);
    }
    if (!quote) {
      quote = await QuoteRequest.findOne({ requestId: id });
    }
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quote Request not found' });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Items array with unit prices is required' });
    }

    let calculatedItemsTotal = 0;
    const updatedItems = items.map((item) => {
      const quantity = Math.max(1, parseInt(item.quantity, 10) || 1);
      const unitPrice = Math.max(0, parseFloat(item.unitPrice) || 0);
      const lineTotal = Math.round(quantity * unitPrice * 100) / 100;
      calculatedItemsTotal += lineTotal;

      return {
        productId: item.productId || null,
        brand: item.brand || '',
        sku: item.sku || '',
        variant: item.variant || '',
        productName: String(item.productName || item.name || 'Item').trim(),
        quantity,
        unitPrice,
        lineTotal,
      };
    });

    const labourCharge = Math.max(0, parseFloat(pricingBreakdown?.labourCharge ?? req.body.labourCharge) || 0);
    const serviceCharge = Math.max(0, parseFloat(pricingBreakdown?.serviceCharge ?? req.body.serviceCharge) || 0);
    const accessoriesCharge = Math.max(0, parseFloat(pricingBreakdown?.accessoriesCharge ?? req.body.accessoriesCharge) || 0);
    const miscCharge = Math.max(0, parseFloat(pricingBreakdown?.miscCharge ?? req.body.miscCharge) || 0);

    const extraCharges = labourCharge + serviceCharge + accessoriesCharge + miscCharge;
    const calculatedSubtotal = Math.round((calculatedItemsTotal + extraCharges) * 100) / 100;

    const parsedGstRate = Math.max(0, parseFloat(gstRate) || 18);
    const calculatedGst = Math.round(((calculatedSubtotal * parsedGstRate) / 100) * 100) / 100;
    const calculatedFinal = Math.round((calculatedSubtotal + calculatedGst) * 100) / 100;

    const parsedAdvancePercentage = Math.min(100, Math.max(0, parseFloat(advancePercentage !== undefined ? advancePercentage : (quote.advancePercentage || 50))));
    const calculatedAdvance = Math.round(((calculatedFinal * parsedAdvancePercentage) / 100) * 100) / 100;
    const currentAdvancePaid = quote.advancePaidAmount || 0;
    const calculatedBalance = Math.max(0, Math.round((calculatedFinal - currentAdvancePaid) * 100) / 100);

    // Snapshot version history before updating if there was already pricing
    if (!Array.isArray(quote.quoteVersions)) {
      quote.quoteVersions = [];
    }
    if (quote.finalAmount && quote.finalAmount > 0) {
      quote.quoteVersions.push({
        version: quote.quoteVersions.length + 1,
        savedAt: new Date(),
        savedBy: req.user?.id || null,
        items: quote.items,
        pricingBreakdown: quote.pricingBreakdown,
        subtotal: quote.subtotal,
        gstRate: quote.gstRate,
        gstAmount: quote.gstAmount,
        finalAmount: quote.finalAmount,
        advancePercentage: quote.advancePercentage,
        advanceAmount: quote.advanceAmount,
        balanceAmount: quote.balanceAmount,
        terms: quote.terms,
        adminNotes: quote.adminNotes,
        status: quote.status,
      });
    }

    quote.items = updatedItems;
    quote.pricingBreakdown = {
      labourCharge,
      serviceCharge,
      accessoriesCharge,
      miscCharge,
    };
    quote.subtotal = calculatedSubtotal;
    quote.gstRate = parsedGstRate;
    quote.gstAmount = calculatedGst;
    quote.finalAmount = calculatedFinal;
    quote.advancePercentage = parsedAdvancePercentage;
    quote.advanceAmount = calculatedAdvance;
    quote.balanceAmount = calculatedBalance;
    quote.validityDays = Number(validityDays) || 15;

    if (adminNotes !== undefined) quote.adminNotes = adminNotes;
    if (terms !== undefined) quote.terms = terms;

    if (saveAsDraft) {
      quote.status = 'quotation_draft';
    }

    await quote.save();

    // Real-time Socket.IO emission to both admin and customer rooms
    const io = req.app.get('io') || global._socketIo;
    if (io) {
      io.to('admin_room').emit('quoteUpdated', quote);
      if (quote.customerId) {
        io.to(quote.customerId.toString()).emit('quoteUpdated', sanitizeQuoteForCustomer(quote));
      }
    }

    return res.json({
      success: true,
      message: 'Quotation calculated and saved successfully',
      data: quote,
    });
  } catch (err) {
    next(err);
  }
}`;

if (!code.includes('function priceQuotation(req, res, next)')) {
  console.error('Could not find priceQuotation');
  process.exit(1);
}

code = code.replace(oldPriceQuotation, newPriceQuotation);

// Update sendQuotation to include advance/balance breakdown in WhatsApp and real-time socket events
const oldSendQuotationPart = `    const validity = quote.validityDays || 15;
    const validUntil = new Date(Date.now() + validity * 24 * 60 * 60 * 1000);

    quote.status = 'quotation_sent';
    quote.sentAt = new Date();
    quote.validUntil = validUntil;
    await quote.save();

    // Prepare WhatsApp Notification content per Part 12
    const customerPhone = cleanPhone.slice(-10);
    const formattedAmount = \`₹\${quote.finalAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}\`;
    const portalUrl = \`\${process.env.FRONTEND_URL || 'https://techbes.co.in'}/dashboard/quotes\`;

    const whatsappMessage =
      \`*TechBes Quotation Ready* 📄\\n\\n\` +
      \`Dear \${quote.fullName || 'Customer'},\\n\` +
      \`Your itemized quotation for *\${quote.serviceCategory || 'CCTV Installation'}* has been prepared.\\n\\n\` +
      \`• *Quotation No:* \${quote.requestId}\\n\` +
      \`• *Grand Total:* \${formattedAmount} (incl. GST)\\n\` +
      \`• *Validity:* \${validity} days\\n\\n\` +
      \`Please review your quotation details and proceed with online booking:\\n\` +
      \`\${portalUrl}\\n\\n\` +
      \`TechBes Services | Support: +91 91080 34888\`;

    // Server-side WhatsApp delivery via channelNotificationService (Twilio)
    let waResult = { success: false };
    try {
      waResult = await sendWhatsApp({
        to: \`+91\${customerPhone}\`,
        body: whatsappMessage,
      });
    } catch (waErr) {
      console.error('[WhatsApp Error]', waErr.message);
      waResult = { success: false, reason: waErr.message };
    }

    // Generate click-to-chat fallback URL
    const clickToChatUrl = \`https://wa.me/91\${customerPhone}?text=\${encodeURIComponent(whatsappMessage)}\`;

    // In-app notification if customerId exists
    if (quote.customerId) {
      try {
        await notificationService.createNotification(
          quote.customerId,
          'Quotation Ready – TechBes',
          \`Your quotation \${quote.requestId} for \${quote.serviceCategory} is ready. Total: \${formattedAmount}. Login to review and pay now to book.\`,
          'quotation_sent',
          null,
          { quoteId: quote._id, requestId: quote.requestId }
        );
      } catch (notifErr) {
        console.error('Failed to send in-app notification:', notifErr.message);
      }
    }`;

const newSendQuotationPart = `    const validity = quote.validityDays || 15;
    const validUntil = new Date(Date.now() + validity * 24 * 60 * 60 * 1000);

    // Ensure advance/balance amounts are configured
    if (!quote.advanceAmount || quote.advanceAmount <= 0) {
      quote.advancePercentage = quote.advancePercentage || 50;
      quote.advanceAmount = Math.round(((quote.finalAmount * quote.advancePercentage) / 100) * 100) / 100;
      quote.balanceAmount = Math.max(0, Math.round((quote.finalAmount - (quote.advancePaidAmount || 0)) * 100) / 100);
    }

    quote.status = 'quotation_sent';
    quote.sentAt = new Date();
    quote.validUntil = validUntil;
    await quote.save();

    // Prepare WhatsApp Notification content per Part 12
    const customerPhone = cleanPhone.slice(-10);
    const formattedAmount = \`₹\${quote.finalAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}\`;
    const formattedAdvance = \`₹\${(quote.advanceAmount || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}\`;
    const formattedBalance = \`₹\${(quote.balanceAmount || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}\`;
    const portalUrl = \`\${process.env.FRONTEND_URL || 'https://techbes.co.in'}/dashboard/quotes\`;

    const whatsappMessage =
      \`*TechBes Quotation Ready* 📄\\n\\n\` +
      \`Dear \${quote.fullName || 'Customer'},\\n\` +
      \`Your itemized quotation for *\${quote.serviceCategory || 'CCTV Installation'}* has been prepared.\\n\\n\` +
      \`• *Quotation No:* \${quote.requestId}\\n\` +
      \`• *Grand Total:* \${formattedAmount} (incl. GST)\\n\` +
      \`• *Advance (\${quote.advancePercentage}%):* \${formattedAdvance}\\n\` +
      \`• *Balance on Completion:* \${formattedBalance}\\n\` +
      \`• *Validity:* \${validity} days\\n\\n\` +
      \`Please review your quotation details and proceed with online booking:\\n\` +
      \`\${portalUrl}\\n\\n\` +
      \`TechBes Services | Support: +91 91080 34888\`;

    // Server-side WhatsApp delivery via channelNotificationService (Twilio)
    let waResult = { success: false };
    try {
      waResult = await sendWhatsApp({
        to: \`+91\${customerPhone}\`,
        body: whatsappMessage,
      });
    } catch (waErr) {
      console.error('[WhatsApp Error]', waErr.message);
      waResult = { success: false, reason: waErr.message };
    }

    // Generate click-to-chat fallback URL
    const clickToChatUrl = \`https://wa.me/91\${customerPhone}?text=\${encodeURIComponent(whatsappMessage)}\`;

    // Real-time socket broadcast to both Admin and Customer rooms
    const io = req.app.get('io') || global._socketIo;
    if (io) {
      io.to('admin_room').emit('quoteStatusUpdated', {
        quoteId: quote._id,
        requestId: quote.requestId,
        status: quote.status,
        finalAmount: quote.finalAmount,
        advanceAmount: quote.advanceAmount,
        balanceAmount: quote.balanceAmount,
      });
      if (quote.customerId) {
        io.to(quote.customerId.toString()).emit('quoteStatusUpdated', sanitizeQuoteForCustomer(quote));
        io.to(quote.customerId.toString()).emit('quoteUpdated', sanitizeQuoteForCustomer(quote));
      }
    }

    // In-app notification if customerId exists
    if (quote.customerId) {
      try {
        await notificationService.createNotification(
          quote.customerId,
          'Quotation Ready – TechBes',
          \`Your quotation \${quote.requestId} for \${quote.serviceCategory} is ready. Total: \${formattedAmount} (Advance: \${formattedAdvance}). Login to review and approve.\`,
          'quotation_sent',
          io,
          { quoteId: quote._id, requestId: quote.requestId, finalAmount: quote.finalAmount, advanceAmount: quote.advanceAmount }
        );
      } catch (notifErr) {
        console.error('Failed to send in-app notification:', notifErr.message);
      }
    }`;

code = code.replace(oldSendQuotationPart, newSendQuotationPart);

// Replace createPaymentOrder & verifyQuotePayment
const oldCreatePaymentOrder = `async function createPaymentOrder(req, res, next) {
  try {
    const { id } = req.params;
    const quote = await QuoteRequest.findById(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quotation not found' });
    }

    // Validate quotation status
    const payableStatuses = ['quotation_sent', 'quotation_accepted', 'payment_pending', 'Quote Sent', 'Quotation Sent'];
    if (!payableStatuses.includes(quote.status)) {
      return res.status(400).json({
        success: false,
        message: \`Quotation is in '\${quote.status}' status and cannot be paid. Must be sent by Admin first.\`,
      });
    }

    // Check validity date
    if (quote.validUntil && new Date() > new Date(quote.validUntil)) {
      quote.status = 'expired';
      await quote.save();
      return res.status(400).json({ success: false, message: 'This quotation has expired. Please request a new quote.' });
    }

    // Authoritative amount in paise
    const finalAmount = quote.finalAmount;
    if (!finalAmount || finalAmount <= 0) {
      return res.status(400).json({ success: false, message: 'Quotation amount is invalid' });
    }
    const amountInPaise = Math.round(finalAmount * 100);

    const description = \`TechBes Quotation Booking: \${quote.requestId}\`;
    const receipt = \`RCP_\${quote.requestId}_\${Date.now().toString().slice(-4)}\`;

    let orderData = null;
    const isTestMode =
      process.env.CCTV_TEST_PAYMENT === 'true' ||
      !process.env.RAZORPAY_KEY_ID ||
      !process.env.RAZORPAY_KEY_SECRET;

    if (isTestMode) {
      const mockOrderId = \`order_qt_\${Date.now()}_\${Math.random().toString(36).substring(7)}\`;
      orderData = {
        orderId: mockOrderId,
        amount: amountInPaise,
        currency: 'INR',
        receipt,
        description,
        keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_mock_techbes',
        isMock: true,
      };
    } else {
      orderData = await paymentService.createRazorpayOrder(amountInPaise, description, receipt, req.user?.id);
    }

    quote.status = 'payment_pending';
    quote.paymentDetails = quote.paymentDetails || {};
    quote.paymentDetails.razorpayOrderId = orderData.orderId;
    await quote.save();

    return res.json({
      success: true,
      message: 'Payment order created successfully',
      data: {
        orderId: orderData.orderId,
        amount: amountInPaise,
        displayAmount: finalAmount,
        currency: 'INR',
        keyId: orderData.keyId,
        quotationId: quote._id,
        requestId: quote.requestId,
        customerName: quote.fullName,
        customerEmail: quote.email,
        customerMobile: quote.mobile,
        isMock: Boolean(orderData.isMock),
      },
    });
  } catch (err) {
    next(err);
  }
}`;

const newCreatePaymentOrder = `async function createPaymentOrder(req, res, next) {
  try {
    const { id } = req.params;
    const { paymentType = 'advance' } = req.body;
    const quote = await QuoteRequest.findById(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quotation not found' });
    }

    // Validate quotation status
    const payableStatuses = [
      'quotation_sent',
      'quotation_accepted',
      'advance_paid',
      'payment_pending',
      'balance_pending',
      'Quote Sent',
      'Quotation Sent',
      'Accepted',
    ];
    if (!payableStatuses.includes(quote.status)) {
      return res.status(400).json({
        success: false,
        message: \`Quotation is in '\${quote.status}' status and cannot be paid. Must be sent by Admin first.\`,
      });
    }

    // Check validity date
    if (quote.validUntil && new Date() > new Date(quote.validUntil)) {
      quote.status = 'expired';
      await quote.save();
      return res.status(400).json({ success: false, message: 'This quotation has expired. Please request a new quote.' });
    }

    // Backend-authoritative amount calculation
    let payableAmount = 0;
    if (paymentType === 'advance') {
      if (quote.advancePaidAmount >= quote.advanceAmount && quote.advanceAmount > 0) {
        return res.status(400).json({
          success: false,
          message: 'Advance payment has already been completed for this quotation.',
        });
      }
      payableAmount = quote.advanceAmount > 0
        ? quote.advanceAmount
        : Math.round(((quote.finalAmount * (quote.advancePercentage || 50)) / 100) * 100) / 100;
    } else if (paymentType === 'balance') {
      if ((quote.advancePaidAmount || 0) <= 0 && quote.advanceAmount > 0) {
        return res.status(400).json({
          success: false,
          message: 'Advance payment must be paid before making balance payment.',
        });
      }

      // Check job completion status
      let job = null;
      if (quote.orderId) {
        job = await Job.findById(quote.orderId);
      }
      if (!job) {
        job = await Job.findOne({ quoteRequestId: quote.requestId });
      }
      if (!job || job.status !== 'completed') {
        return res.status(400).json({
          success: false,
          message: 'Balance payment is only available after job completion by technician (job status must be completed).',
        });
      }

      if (quote.balanceAmount <= 0 || (quote.balancePaidAmount >= quote.balanceAmount && quote.balancePaidAmount > 0)) {
        return res.status(400).json({
          success: false,
          message: 'Balance has already been paid in full.',
        });
      }
      payableAmount = quote.balanceAmount;
    } else {
      payableAmount = quote.finalAmount;
    }

    if (!payableAmount || payableAmount <= 0) {
      return res.status(400).json({ success: false, message: 'Calculated payable amount is zero or invalid' });
    }

    const amountInPaise = Math.round(payableAmount * 100);
    const description = \`TechBes \${paymentType === 'advance' ? 'Advance' : 'Balance'} Payment: \${quote.requestId}\`;
    const receipt = \`RCP_\${paymentType.toUpperCase()}_\${quote.requestId}_\${Date.now().toString().slice(-4)}\`;

    let orderData = null;
    const isTestMode =
      process.env.CCTV_TEST_PAYMENT === 'true' ||
      !process.env.RAZORPAY_KEY_ID ||
      !process.env.RAZORPAY_KEY_SECRET;

    if (isTestMode) {
      const mockOrderId = \`order_\${paymentType}_\${Date.now()}_\${Math.random().toString(36).substring(7)}\`;
      orderData = {
        orderId: mockOrderId,
        amount: amountInPaise,
        currency: 'INR',
        receipt,
        description,
        keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_mock_techbes',
        isMock: true,
      };
    } else {
      orderData = await paymentService.createRazorpayOrder(amountInPaise, description, receipt, req.user?.id);
    }

    if (paymentType === 'advance') {
      quote.advancePaymentDetails = quote.advancePaymentDetails || {};
      quote.advancePaymentDetails.razorpayOrderId = orderData.orderId;
      quote.status = 'payment_pending';
    } else {
      quote.balancePaymentDetails = quote.balancePaymentDetails || {};
      quote.balancePaymentDetails.razorpayOrderId = orderData.orderId;
      quote.status = 'balance_pending';
    }
    await quote.save();

    // Create Payment record in pending state
    await Payment.create({
      userId: req.user?.id || quote.customerId,
      quoteId: quote._id,
      jobId: quote.orderId || null,
      razorpayOrderId: orderData.orderId,
      amount: amountInPaise,
      currency: 'INR',
      status: 'pending',
      paymentType,
      meta: {
        quotationId: quote._id,
        requestId: quote.requestId,
        paymentType,
      },
    });

    return res.json({
      success: true,
      message: \`\${paymentType === 'advance' ? 'Advance' : 'Balance'} payment order created successfully\`,
      data: {
        orderId: orderData.orderId,
        amount: amountInPaise,
        displayAmount: payableAmount,
        currency: 'INR',
        keyId: orderData.keyId,
        quotationId: quote._id,
        requestId: quote.requestId,
        paymentType,
        customerName: quote.fullName,
        customerEmail: quote.email,
        customerMobile: quote.mobile,
        isMock: Boolean(orderData.isMock),
      },
    });
  } catch (err) {
    next(err);
  }
}`;

code = code.replace(oldCreatePaymentOrder, newCreatePaymentOrder);

// Replace verifyQuotePayment
const oldVerifyQuotePayment = `async function verifyQuotePayment(req, res, next) {
  try {
    const { id } = req.params;
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, mockSuccess } = req.body;

    const quote = await QuoteRequest.findById(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quotation not found' });
    }

    const isTestMode =
      process.env.CCTV_TEST_PAYMENT === 'true' ||
      !process.env.RAZORPAY_KEY_ID ||
      !process.env.RAZORPAY_KEY_SECRET;

    if (isTestMode && mockSuccess) {
      console.log(\`[Quote Payment] Verified via mock test payment for \${quote.requestId}\`);
    } else {
      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        return res.status(400).json({ success: false, message: 'Payment verification details missing' });
      }

      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keySecret) {
        throw new Error('Razorpay secret key not configured');
      }

      const expectedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(\`\${razorpay_order_id}|\${razorpay_payment_id}\`)
        .digest('hex');

      if (expectedSignature !== razorpay_signature) {
        return res.status(400).json({ success: false, message: 'Payment signature verification failed' });
      }
    }

    // 1. Generate unique sequential Order Number ORD-YYYY-XXXXX
    const year = new Date().getFullYear();
    const Counter = require('../../models/Counter');
    let orderSeq = 1;
    try {
      const counter = await Counter.findOneAndUpdate(
        { id: \`order_number_\${year}\` },
        { $inc: { seq: 1 } },
        { upsert: true, new: true }
      );
      orderSeq = counter.seq;
    } catch {
      orderSeq = Math.floor(Math.random() * 90000) + 10000;
    }
    const orderNumber = \`ORD-\${year}-\${String(orderSeq).padStart(5, '0')}\`;

    // 2. Find or create Client User
    let clientUser = null;
    if (req.user && req.user.id) {
      clientUser = await User.findById(req.user.id);
    } else if (quote.customerId) {
      clientUser = await User.findById(quote.customerId);
    }
    if (!clientUser) {
      clientUser = await User.findOne({ mobileNumber: quote.mobile });
    }
    if (!clientUser) {
      const randomPassword = Math.random().toString(36).substring(2, 10);
      clientUser = await User.create({
        name: quote.fullName,
        mobileNumber: quote.mobile,
        email: quote.email || undefined,
        password: randomPassword,
        role: 'client',
        userType: 'web_user',
      });
    }

    // 3. Find or create Address
    let addr = await Address.findOne({ userId: clientUser._id });
    if (!addr) {
      addr = await Address.create({
        userId: clientUser._id,
        address: quote.address,
        pincode: quote.pincode || '',
      });
    }

    // 4. Create Payment Record
    const payment = await Payment.create({
      userId: clientUser._id,
      razorpayOrderId: razorpay_order_id || \`order_mock_\${Date.now()}\`,
      razorpayPaymentId: razorpay_payment_id || \`pay_mock_\${Date.now()}\`,
      razorpaySignature: razorpay_signature || 'mock_sig',
      amount: Math.round(quote.finalAmount * 100),
      currency: 'INR',
      status: 'paid',
      orderNumber,
      meta: {
        quotationId: quote._id,
        requestId: quote.requestId,
        itemsCount: quote.items.length,
      },
    });

    // 5. Create Job / Order linked to Customer, Quotation, Payment, Items, Location
    const itemsDescription = quote.items
      .map((it) => \`• \${it.productName} (Qty: \${it.quantity}, Rate: ₹\${it.unitPrice})\`)
      .join('\\n');

    const job = await Job.create({
      title: \`\${quote.serviceCategory} Order - \${orderNumber}\`,
      description: \`Quotation: \${quote.requestId}\\nOrder No: \${orderNumber}\\n\\nOrdered Items:\\n\${itemsDescription}\\n\\nAdditional Requirements:\\n\${quote.additionalRequirements || 'None'}\`,
      location: quote.address,
      client: clientUser._id,
      customerName: quote.fullName,
      customerPhone: quote.mobile,
      scheduledTime: quote.preferredVisitDate
        ? \`\${new Date(quote.preferredVisitDate).toISOString().split('T')[0]} \${quote.preferredVisitTime || 'ASAP'}\`
        : 'ASAP',
      status: 'pending',
      useNewFlow: true,
      bookingDate: quote.preferredVisitDate ? new Date(quote.preferredVisitDate).toISOString().split('T')[0] : '',
      timeSlot: quote.preferredVisitTime || '',
      addressId: addr ? addr._id : undefined,
      latitude: quote.latitude,
      longitude: quote.longitude,
      googleMapsLink:
        quote.googleMapsUrl ||
        (quote.latitude && quote.longitude ? \`https://www.google.com/maps?q=\${quote.latitude},\${quote.longitude}\` : ''),
      addressDetails: {
        area: quote.locality || '',
        pincode: quote.pincode || '',
        formattedAddress: quote.address || '',
      },
      quoteRequestId: quote.requestId,
      paymentId: payment._id,
      paymentStatus: 'paid',
    });

    // 6. Update QuoteRequest record
    quote.status = 'paid';
    quote.paidAt = new Date();
    quote.orderNumber = orderNumber;
    quote.orderId = job._id;
    quote.paymentDetails = {
      razorpayOrderId: razorpay_order_id || '',
      razorpayPaymentId: razorpay_payment_id || '',
      razorpaySignature: razorpay_signature || '',
      paymentId: payment._id,
      amountPaid: quote.finalAmount,
    };
    await quote.save();

    // 7. Dispatch notifications
    try {
      await notificationService.createNotification(
        clientUser._id,
        'Order Confirmed Successfully!',
        \`Your payment of ₹\${quote.finalAmount} was verified. Order #\${orderNumber} is being prepared.\`,
        'order_confirmed',
        null,
        { orderNumber, jobId: job._id }
      );
    } catch (e) {
      console.error('Order notification error:', e.message);
    }

    return res.status(200).json({
      success: true,
      message: 'Order Confirmed Successfully',
      data: {
        orderNumber,
        orderId: job._id,
        orderDate: new Date(),
        amountPaid: quote.finalAmount,
        quotationId: quote._id,
        requestId: quote.requestId,
        serviceCategory: quote.serviceCategory,
        items: quote.items,
        address: quote.address,
      },
    });
  } catch (err) {
    next(err);
  }
}`;

const newVerifyQuotePayment = `async function verifyQuotePayment(req, res, next) {
  try {
    const { id } = req.params;
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      mockSuccess,
      paymentType = 'advance',
    } = req.body;

    const quote = await QuoteRequest.findById(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quotation not found' });
    }

    const isTestMode =
      process.env.CCTV_TEST_PAYMENT === 'true' ||
      !process.env.RAZORPAY_KEY_ID ||
      !process.env.RAZORPAY_KEY_SECRET;

    if (isTestMode && mockSuccess) {
      console.log(\`[Quote Payment] Verified via mock test payment for \${quote.requestId} (\${paymentType})\`);
    } else {
      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        return res.status(400).json({ success: false, message: 'Payment verification details missing' });
      }

      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keySecret) {
        throw new Error('Razorpay secret key not configured');
      }

      const expectedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(\`\${razorpay_order_id}|\${razorpay_payment_id}\`)
        .digest('hex');

      if (expectedSignature !== razorpay_signature) {
        return res.status(400).json({ success: false, message: 'Payment signature verification failed' });
      }
    }

    // 1. Generate unique sequential Order Number & Invoice Number
    const year = new Date().getFullYear();
    const Counter = require('../../models/Counter');
    let orderSeq = 1;
    try {
      const counter = await Counter.findOneAndUpdate(
        { id: \`order_number_\${year}\` },
        { $inc: { seq: 1 } },
        { upsert: true, new: true }
      );
      orderSeq = counter.seq;
    } catch {
      orderSeq = Math.floor(Math.random() * 90000) + 10000;
    }
    const orderNumber = quote.orderNumber || \`ORD-\${year}-\${String(orderSeq).padStart(5, '0')}\`;
    const invoicePrefix = paymentType === 'balance' ? 'INV-BAL' : 'INV-ADV';
    const invoiceNumber = \`\${invoicePrefix}-\${year}-\${String(orderSeq).padStart(5, '0')}\`;

    // 2. Find or create Client User
    let clientUser = null;
    if (req.user && req.user.id) {
      clientUser = await User.findById(req.user.id);
    } else if (quote.customerId) {
      clientUser = await User.findById(quote.customerId);
    }
    if (!clientUser) {
      clientUser = await User.findOne({ mobileNumber: quote.mobile });
    }
    if (!clientUser) {
      const randomPassword = Math.random().toString(36).substring(2, 10);
      clientUser = await User.create({
        name: quote.fullName,
        mobileNumber: quote.mobile,
        email: quote.email || undefined,
        password: randomPassword,
        role: 'client',
        userType: 'web_user',
      });
    }

    // 3. Find or create Address
    let addr = await Address.findOne({ userId: clientUser._id });
    if (!addr) {
      addr = await Address.create({
        userId: clientUser._id,
        address: quote.address,
        pincode: quote.pincode || '',
      });
    }

    // 4. Calculate Authoritative Amounts
    const advanceAmt = quote.advanceAmount > 0
      ? quote.advanceAmount
      : Math.round(((quote.finalAmount * (quote.advancePercentage || 50)) / 100) * 100) / 100;
    const paidAmount = paymentType === 'balance' ? quote.balanceAmount : advanceAmt;
    const amountInPaise = Math.round(paidAmount * 100);

    // 5. Idempotent Payment Record
    let payment = await Payment.findOne({ razorpayOrderId: razorpay_order_id });
    if (payment) {
      payment.razorpayPaymentId = razorpay_payment_id || \`pay_\${Date.now()}\`;
      payment.razorpaySignature = razorpay_signature || 'verified_sig';
      payment.status = 'paid';
      payment.paymentType = paymentType;
      payment.invoiceNumber = payment.invoiceNumber || invoiceNumber;
      await payment.save();
    } else {
      payment = await Payment.create({
        userId: clientUser._id,
        quoteId: quote._id,
        jobId: quote.orderId || null,
        razorpayOrderId: razorpay_order_id || \`order_mock_\${Date.now()}\`,
        razorpayPaymentId: razorpay_payment_id || \`pay_mock_\${Date.now()}\`,
        razorpaySignature: razorpay_signature || 'mock_sig',
        amount: amountInPaise,
        currency: 'INR',
        status: 'paid',
        paymentType,
        orderNumber,
        invoiceNumber,
        meta: {
          quotationId: quote._id,
          requestId: quote.requestId,
          paymentType,
        },
      });
    }

    // 6. Find or Create Job
    let job = quote.orderId ? await Job.findById(quote.orderId) : await Job.findOne({ quoteRequestId: quote.requestId });

    if (paymentType === 'advance') {
      quote.advancePaidAmount = advanceAmt;
      quote.balanceAmount = Math.max(0, Math.round((quote.finalAmount - quote.advancePaidAmount) * 100) / 100);
      quote.status = quote.balanceAmount === 0 ? 'paid' : 'advance_paid';
      quote.quotePaymentStatus = quote.balanceAmount === 0 ? 'fully_paid' : 'advance_paid';
      quote.orderNumber = orderNumber;
      quote.advancePaymentDetails = {
        razorpayOrderId: razorpay_order_id || '',
        razorpayPaymentId: razorpay_payment_id || '',
        razorpaySignature: razorpay_signature || '',
        paymentId: payment._id,
        amountPaid: advanceAmt,
        paidAt: new Date(),
      };

      if (!job) {
        const itemsDescription = quote.items
          .map((it) => \`• \${it.productName} (Qty: \${it.quantity}, Rate: ₹\${it.unitPrice})\`)
          .join('\\n');

        job = await Job.create({
          title: \`\${quote.serviceCategory} Order - \${orderNumber}\`,
          description: \`Quotation: \${quote.requestId}\\nOrder No: \${orderNumber}\\n\\nOrdered Items:\\n\${itemsDescription}\\n\\nAdditional Requirements:\\n\${quote.additionalRequirements || 'None'}\`,
          location: quote.address,
          client: clientUser._id,
          customerName: quote.fullName,
          customerPhone: quote.mobile,
          scheduledTime: quote.preferredVisitDate
            ? \`\${new Date(quote.preferredVisitDate).toISOString().split('T')[0]} \${quote.preferredVisitTime || 'ASAP'}\`
            : 'ASAP',
          status: 'pending',
          useNewFlow: true,
          bookingDate: quote.preferredVisitDate ? new Date(quote.preferredVisitDate).toISOString().split('T')[0] : '',
          timeSlot: quote.preferredVisitTime || '',
          addressId: addr ? addr._id : undefined,
          latitude: quote.latitude,
          longitude: quote.longitude,
          googleMapsLink:
            quote.googleMapsUrl ||
            (quote.latitude && quote.longitude ? \`https://www.google.com/maps?q=\${quote.latitude},\${quote.longitude}\` : ''),
          addressDetails: {
            area: quote.locality || '',
            pincode: quote.pincode || '',
            formattedAddress: quote.address || '',
          },
          quoteRequestId: quote.requestId,
          paymentId: payment._id,
          paymentStatus: 'advance_paid',
          advancePaid: true,
          advancePaymentId: razorpay_payment_id || '',
          advanceAmount: advanceAmt,
          remainingAmount: quote.balanceAmount,
          price: quote.finalAmount,
          amount: quote.finalAmount,
        });
      } else {
        job.paymentStatus = 'advance_paid';
        job.advancePaid = true;
        job.advancePaymentId = razorpay_payment_id || '';
        job.advanceAmount = advanceAmt;
        job.remainingAmount = quote.balanceAmount;
        await job.save();
      }

      quote.orderId = job._id;
      payment.jobId = job._id;
      await payment.save();
    } else if (paymentType === 'balance') {
      quote.balancePaidAmount = quote.balanceAmount;
      quote.balanceAmount = 0;
      quote.status = 'paid';
      quote.quotePaymentStatus = 'fully_paid';
      quote.paidAt = new Date();
      quote.balancePaymentDetails = {
        razorpayOrderId: razorpay_order_id || '',
        razorpayPaymentId: razorpay_payment_id || '',
        razorpaySignature: razorpay_signature || '',
        paymentId: payment._id,
        amountPaid: paidAmount,
        paidAt: new Date(),
      };

      if (job) {
        job.paymentStatus = 'paid';
        job.remainingAmount = 0;
        await job.save();
      }
    }

    await quote.save();

    // 7. Socket.IO Real-time updates
    const io = req.app.get('io') || global._socketIo;
    if (io) {
      io.to('admin_room').emit('quoteStatusUpdated', {
        quoteId: quote._id,
        requestId: quote.requestId,
        status: quote.status,
        quotePaymentStatus: quote.quotePaymentStatus,
        paymentType,
        amountPaid: paidAmount,
        balanceAmount: quote.balanceAmount,
      });
      io.to('admin_room').emit('quoteUpdated', quote);
      if (clientUser) {
        io.to(clientUser._id.toString()).emit('quoteUpdated', sanitizeQuoteForCustomer(quote));
        io.to(clientUser._id.toString()).emit('quoteStatusUpdated', sanitizeQuoteForCustomer(quote));
        if (paymentType === 'advance') {
          io.to(clientUser._id.toString()).emit('bookingConfirmed', job);
        }
      }
    }

    // 8. Dispatch notifications
    try {
      const notifTitle = paymentType === 'balance' ? 'Quotation Balance Paid Successfully' : 'Order Confirmed! Advance Payment Received';
      const notifMsg = paymentType === 'balance'
        ? \`Your balance payment of ₹\${paidAmount} for Quotation #\${quote.requestId} was verified. Quotation is fully settled.\`
        : \`Your advance payment of ₹\${paidAmount} was verified. Order #\${orderNumber} is confirmed and assigned to engineering.\`;

      await notificationService.createNotification(
        clientUser._id,
        notifTitle,
        notifMsg,
        paymentType === 'balance' ? 'payment_received' : 'order_confirmed',
        io,
        { orderNumber, jobId: job?._id, quoteId: quote._id, paymentType, invoiceNumber }
      );
    } catch (e) {
      console.error('Order notification error:', e.message);
    }

    return res.status(200).json({
      success: true,
      message: paymentType === 'balance' ? 'Balance Payment Verified Successfully' : 'Advance Payment Verified & Order Confirmed',
      data: {
        orderNumber,
        invoiceNumber,
        orderId: job?._id,
        orderDate: new Date(),
        paymentType,
        amountPaid: paidAmount,
        advancePaidAmount: quote.advancePaidAmount,
        balanceAmount: quote.balanceAmount,
        paymentStatus: quote.quotePaymentStatus,
        quotationId: quote._id,
        requestId: quote.requestId,
        serviceCategory: quote.serviceCategory,
        items: quote.items,
        address: quote.address,
      },
    });
  } catch (err) {
    next(err);
  }
}`;

code = code.replace(oldVerifyQuotePayment, newVerifyQuotePayment);

// Add getQuotationInvoice
const getQuotationInvoiceFunc = `
/**
 * Get Invoice/Receipt for quotation payment (Advance or Balance)
 */
async function getQuotationInvoice(req, res, next) {
  try {
    const { id, paymentType = 'advance' } = req.params;
    const mongoose = require('mongoose');
    let quote = null;
    if (mongoose.Types.ObjectId.isValid(id)) {
      quote = await QuoteRequest.findById(id);
    }
    if (!quote) {
      quote = await QuoteRequest.findOne({ requestId: id });
    }
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Quotation not found' });
    }

    const paymentDetails = paymentType === 'balance' ? quote.balancePaymentDetails : quote.advancePaymentDetails;
    const payment = await Payment.findOne({
      quoteId: quote._id,
      paymentType,
      status: { $in: ['paid', 'verified'] },
    }).sort({ createdAt: -1 });

    const invoiceData = {
      invoiceNumber: payment?.invoiceNumber || \`\${paymentType === 'balance' ? 'INV-BAL' : 'INV-ADV'}-\${quote.requestId}\`,
      receiptNumber: payment?.paymentReference || \`RCP-\${quote.requestId}\`,
      date: paymentDetails?.paidAt || payment?.createdAt || new Date(),
      customerName: quote.fullName,
      customerEmail: quote.email,
      customerMobile: quote.mobile,
      address: quote.address,
      serviceCategory: quote.serviceCategory,
      subcategory: quote.subcategory,
      quotationNumber: quote.requestId,
      orderNumber: quote.orderNumber,
      paymentType,
      items: quote.items,
      pricingBreakdown: quote.pricingBreakdown,
      subtotal: quote.subtotal,
      gstRate: quote.gstRate,
      gstAmount: quote.gstAmount,
      finalAmount: quote.finalAmount,
      advancePercentage: quote.advancePercentage,
      advanceAmount: quote.advanceAmount,
      amountPaid: paymentDetails?.amountPaid || (payment ? payment.amount / 100 : 0),
      balanceAmount: quote.balanceAmount,
      paymentMethod: 'Razorpay Online',
      transactionId: paymentDetails?.razorpayPaymentId || payment?.razorpayPaymentId || 'N/A',
      status: 'PAID',
    };

    return res.json({ success: true, data: invoiceData });
  } catch (err) {
    next(err);
  }
}
`;

// Insert getQuotationInvoice right before module.exports
code = code.replace(`module.exports = {`, `${getQuotationInvoiceFunc}\nmodule.exports = {`);

// Add to module.exports
code = code.replace(`rejectQuote,`, `rejectQuote,\n  getQuotationInvoice,`);

fs.writeFileSync(targetFile, code, 'utf8');
console.log('Price, Send, Payment Order, Verify & Invoice updated in quoteControllerV2.js');
