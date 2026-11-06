const fs = require('fs');
let code = fs.readFileSync('admin/src/components/QuoteRequestsPage.jsx', 'utf8');

// 1. Add state for labour, service, accessories, misc, advance %
const oldStates = `  const [pricingItems, setPricingItems] = useState([]);
  const [gstRate, setGstRate] = useState(18);
  const [validityDays, setValidityDays] = useState(15);
  const [quoteTerms, setQuoteTerms] = useState("");
  const [whatsappResult, setWhatsappResult] = useState(null);`;

const newStates = `  const [pricingItems, setPricingItems] = useState([]);
  const [gstRate, setGstRate] = useState(18);
  const [validityDays, setValidityDays] = useState(15);
  const [quoteTerms, setQuoteTerms] = useState("");
  const [whatsappResult, setWhatsappResult] = useState(null);
  const [labourCharge, setLabourCharge] = useState(0);
  const [serviceCharge, setServiceCharge] = useState(0);
  const [accessoriesCharge, setAccessoriesCharge] = useState(0);
  const [miscCharge, setMiscCharge] = useState(0);
  const [advancePercentage, setAdvancePercentage] = useState(50);`;

code = code.replace(oldStates, newStates);

// 2. Initialize state in useEffect
const oldInit = `      setQuoteTerms(
        selectedQuote.terms || 
        "1. 50% advance on order confirmation, balance on completion.\\n2. 1-Year manufacturer warranty on cameras & active equipment.\\n3. Physical damage and electrical surges excluded from warranty.\\n4. Quote valid for 15 days from date of issue."
      );
      setWhatsappResult(null);`;

const newInit = `      setQuoteTerms(
        selectedQuote.terms || 
        "1. 50% advance on order confirmation, balance on completion.\\n2. 1-Year manufacturer warranty on cameras & active equipment.\\n3. Physical damage and electrical surges excluded from warranty.\\n4. Quote valid for 15 days from date of issue."
      );
      setWhatsappResult(null);
      setLabourCharge(selectedQuote.pricingBreakdown?.labourCharge || 0);
      setServiceCharge(selectedQuote.pricingBreakdown?.serviceCharge || 0);
      setAccessoriesCharge(selectedQuote.pricingBreakdown?.accessoriesCharge || 0);
      setMiscCharge(selectedQuote.pricingBreakdown?.miscCharge || 0);
      setAdvancePercentage(selectedQuote.advancePercentage !== undefined ? selectedQuote.advancePercentage : 50);`;

code = code.replace(oldInit, newInit);

// 3. Update calculatedPricing
const oldCalc = `  // Automatic calculation of Subtotal, GST, and Final Amount
  const calculatedPricing = useMemo(() => {
    let subtotal = 0;
    const computedItems = pricingItems.map(item => {
      const qty = parseFloat(item.quantity) || 0;
      const price = parseFloat(item.unitPrice) || 0;
      const lineTotal = Math.round(qty * price * 100) / 100;
      subtotal += lineTotal;
      return { ...item, quantity: item.quantity, unitPrice: item.unitPrice, lineTotal };
    });

    const parsedGstRate = parseFloat(gstRate) || 0;
    const gstAmount = Math.round(((subtotal * parsedGstRate) / 100) * 100) / 100;
    const finalAmount = Math.round((subtotal + gstAmount) * 100) / 100;

    return {
      items: computedItems,
      subtotal: Math.round(subtotal * 100) / 100,
      gstAmount,
      finalAmount,
    };
  }, [pricingItems, gstRate]);`;

const newCalc = `  // Automatic calculation of Subtotal, GST, Final Amount, Advance, and Balance
  const calculatedPricing = useMemo(() => {
    let itemsTotal = 0;
    const computedItems = pricingItems.map(item => {
      const qty = parseFloat(item.quantity) || 0;
      const price = parseFloat(item.unitPrice) || 0;
      const lineTotal = Math.round(qty * price * 100) / 100;
      itemsTotal += lineTotal;
      return { ...item, quantity: item.quantity, unitPrice: item.unitPrice, lineTotal };
    });

    const labour = Math.max(0, parseFloat(labourCharge) || 0);
    const service = Math.max(0, parseFloat(serviceCharge) || 0);
    const accessories = Math.max(0, parseFloat(accessoriesCharge) || 0);
    const misc = Math.max(0, parseFloat(miscCharge) || 0);
    const subtotal = Math.round((itemsTotal + labour + service + accessories + misc) * 100) / 100;

    const parsedGstRate = parseFloat(gstRate) || 0;
    const gstAmount = Math.round(((subtotal * parsedGstRate) / 100) * 100) / 100;
    const finalAmount = Math.round((subtotal + gstAmount) * 100) / 100;

    const advPct = Math.min(100, Math.max(0, parseFloat(advancePercentage) || 50));
    const advanceAmount = Math.round(((finalAmount * advPct) / 100) * 100) / 100;
    const balanceAmount = Math.max(0, Math.round((finalAmount - (selectedQuote?.advancePaidAmount || 0)) * 100) / 100);

    return {
      items: computedItems,
      itemsTotal: Math.round(itemsTotal * 100) / 100,
      labourCharge: labour,
      serviceCharge: service,
      accessoriesCharge: accessories,
      miscCharge: misc,
      subtotal,
      gstAmount,
      finalAmount,
      advancePercentage: advPct,
      advanceAmount,
      balanceAmount,
    };
  }, [pricingItems, gstRate, labourCharge, serviceCharge, accessoriesCharge, miscCharge, advancePercentage, selectedQuote]);`;

code = code.replace(oldCalc, newCalc);

// 4. Update handleSavePricing payload
const oldSavePayload = `        body: {
          items: itemsPayload,
          gstRate: parseFloat(gstRate) || 0,
          validityDays: parseInt(validityDays, 10) || 15,
          adminNotes,
          terms: quoteTerms,
          saveAsDraft: asDraft,
        },`;

const newSavePayload = `        body: {
          items: itemsPayload,
          pricingBreakdown: {
            labourCharge: parseFloat(labourCharge) || 0,
            serviceCharge: parseFloat(serviceCharge) || 0,
            accessoriesCharge: parseFloat(accessoriesCharge) || 0,
            miscCharge: parseFloat(miscCharge) || 0,
          },
          advancePercentage: parseFloat(advancePercentage) || 50,
          gstRate: parseFloat(gstRate) || 0,
          validityDays: parseInt(validityDays, 10) || 15,
          adminNotes,
          terms: quoteTerms,
          saveAsDraft: asDraft,
        },`;

code = code.replace(oldSavePayload, newSavePayload);

// 5. Update handleSendQuotation payload
const oldSendPricePayload = `        body: {
          items: itemsPayload,
          gstRate: parseFloat(gstRate) || 0,
          validityDays: parseInt(validityDays, 10) || 15,
          adminNotes,
          terms: quoteTerms,
        },`;

const newSendPricePayload = `        body: {
          items: itemsPayload,
          pricingBreakdown: {
            labourCharge: parseFloat(labourCharge) || 0,
            serviceCharge: parseFloat(serviceCharge) || 0,
            accessoriesCharge: parseFloat(accessoriesCharge) || 0,
            miscCharge: parseFloat(miscCharge) || 0,
          },
          advancePercentage: parseFloat(advancePercentage) || 50,
          gstRate: parseFloat(gstRate) || 0,
          validityDays: parseInt(validityDays, 10) || 15,
          adminNotes,
          terms: quoteTerms,
          saveAsDraft: false,
        },`;

code = code.replace(oldSendPricePayload, newSendPricePayload);

// 6. Update UI in Pricing Box to display additional charge inputs and advance/balance terms
const oldSummaryBox = `                  {/* Calculations breakdown */}
                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: "#475569" }}>
                    <span>Items Taxable Subtotal:</span>
                    <span style={{ fontWeight: 700, color: "#1e293b" }}>
                      ₹{calculatedPricing.subtotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>

                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: "#475569" }}>
                    <span>GST ({gstRate}%):</span>
                    <span style={{ fontWeight: 700, color: "#d97706" }}>
                      + ₹{calculatedPricing.gstAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>

                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15, fontWeight: 800, color: "#0f172a", paddingTop: 4, borderTop: "1px dashed #cbd5e1" }}>
                    <span>Grand Total:</span>
                    <span style={{ color: "#2563eb", fontSize: 17 }}>
                      ₹{calculatedPricing.finalAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>`;

const newSummaryBox = `                  {/* Additional Pricing Components */}
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "6px 12px", background: "#fff", padding: "8px 10px", borderRadius: 8, border: "1px solid #e2e8f0" }}>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", fontSize: 11 }}>
                      <span style={{ color: "#64748b" }}>Labour / Install (₹):</span>
                      <input 
                        type="number" 
                        min="0" 
                        value={labourCharge} 
                        onChange={e => setLabourCharge(parseFloat(e.target.value) || 0)} 
                        style={{ width: 70, height: 22, padding: "0 4px", border: "1px solid #cbd5e1", borderRadius: 4, fontSize: 11, textAlign: "right", fontWeight: 600 }}
                      />
                    </div>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", fontSize: 11 }}>
                      <span style={{ color: "#64748b" }}>Service Charge (₹):</span>
                      <input 
                        type="number" 
                        min="0" 
                        value={serviceCharge} 
                        onChange={e => setServiceCharge(parseFloat(e.target.value) || 0)} 
                        style={{ width: 70, height: 22, padding: "0 4px", border: "1px solid #cbd5e1", borderRadius: 4, fontSize: 11, textAlign: "right", fontWeight: 600 }}
                      />
                    </div>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", fontSize: 11 }}>
                      <span style={{ color: "#64748b" }}>Accessories (₹):</span>
                      <input 
                        type="number" 
                        min="0" 
                        value={accessoriesCharge} 
                        onChange={e => setAccessoriesCharge(parseFloat(e.target.value) || 0)} 
                        style={{ width: 70, height: 22, padding: "0 4px", border: "1px solid #cbd5e1", borderRadius: 4, fontSize: 11, textAlign: "right", fontWeight: 600 }}
                      />
                    </div>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", fontSize: 11 }}>
                      <span style={{ color: "#64748b" }}>Misc / Travel (₹):</span>
                      <input 
                        type="number" 
                        min="0" 
                        value={miscCharge} 
                        onChange={e => setMiscCharge(parseFloat(e.target.value) || 0)} 
                        style={{ width: 70, height: 22, padding: "0 4px", border: "1px solid #cbd5e1", borderRadius: 4, fontSize: 11, textAlign: "right", fontWeight: 600 }}
                      />
                    </div>
                  </div>

                  {/* Calculations breakdown */}
                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: "#475569" }}>
                    <span>Taxable Subtotal (Items + Charges):</span>
                    <span style={{ fontWeight: 700, color: "#1e293b" }}>
                      ₹{calculatedPricing.subtotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>

                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: "#475569" }}>
                    <span>GST ({gstRate}%):</span>
                    <span style={{ fontWeight: 700, color: "#d97706" }}>
                      + ₹{calculatedPricing.gstAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>

                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: 15, fontWeight: 800, color: "#0f172a", paddingTop: 4, borderTop: "1px dashed #cbd5e1" }}>
                    <span>Grand Total:</span>
                    <span style={{ color: "#2563eb", fontSize: 17 }}>
                      ₹{calculatedPricing.finalAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>

                  {/* Advance & Balance Breakdown */}
                  <div style={{ background: "#f0fdf4", border: "1px solid #bbf7d0", borderRadius: 8, padding: "6px 10px", marginTop: 4, display: "flex", flexDirection: "column", gap: 3 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 11 }}>
                      <span style={{ color: "#166534", fontWeight: 600 }}>Advance Policy:</span>
                      <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
                        <input 
                          type="number" 
                          min="0" 
                          max="100" 
                          value={advancePercentage} 
                          onChange={e => setAdvancePercentage(parseFloat(e.target.value) || 0)} 
                          style={{ width: 44, height: 20, padding: "0 2px", border: "1px solid #86efac", borderRadius: 4, fontSize: 11, textAlign: "center", fontWeight: 700 }}
                        />
                        <span style={{ fontSize: 11, color: "#166534" }}>%</span>
                      </div>
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11, color: "#15803d" }}>
                      <span>Advance Payable: <strong>₹{calculatedPricing.advanceAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong></span>
                      <span>Balance on Completion: <strong>₹{calculatedPricing.balanceAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong></span>
                    </div>
                  </div>
                </div>`;

code = code.replace(oldSummaryBox, newSummaryBox);

fs.writeFileSync('admin/src/components/QuoteRequestsPage.jsx', code, 'utf8');
console.log('QuoteRequestsPage.jsx updated successfully');
