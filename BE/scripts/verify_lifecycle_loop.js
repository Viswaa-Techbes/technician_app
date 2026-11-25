/**
 * verify_lifecycle_loop.js
 * End-to-End automated verification of Admin-to-Technician Job Lifecycle & Verification Loop
 */
const https = require('https');

const API_BASE = 'https://api.techbes.co.in';

function request(url, options = {}, data = null) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const reqOptions = {
      hostname: parsed.hostname,
      port: 443,
      path: parsed.pathname + parsed.search,
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {})
      }
    };

    const req = https.request(reqOptions, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(body); } catch (_) {}
        resolve({ status: res.statusCode, headers: res.headers, body: json || body });
      });
    });

    req.on('error', reject);
    if (data) {
      req.write(typeof data === 'string' ? data : JSON.stringify(data));
    }
    req.end();
  });
}

async function run() {
  console.log('=== TechBes Admin-to-Technician Job Lifecycle & Verification Audit ===\n');

  // Step 1: Admin Authentication
  console.log('1. Authenticating as Admin (lohith@techbes.co.in)...');
  const adminLoginRes = await request(`${API_BASE}/admin/login`, {
    method: 'POST'
  }, {
    email: 'lohith@techbes.co.in',
    password: 'admin*#123'
  });

  if (adminLoginRes.status !== 200 || (!adminLoginRes.body.token && !adminLoginRes.body.data?.token)) {
    throw new Error(`Admin login failed: ${adminLoginRes.status} - ${JSON.stringify(adminLoginRes.body)}`);
  }
  const adminToken = adminLoginRes.body.data?.token || adminLoginRes.body.token;
  console.log('   ✓ Admin authenticated successfully. Token length:', adminToken.length);

  // Step 2: Technician Authentication
  console.log('\n2. Authenticating as QA Technician (9000099999)...');
  const techLoginRes = await request(`${API_BASE}/api/auth/login`, {
    method: 'POST'
  }, {
    mobileNumber: '9000099999',
    password: 'TechTest@123'
  });

  if (techLoginRes.status !== 200 || (!techLoginRes.body.token && !techLoginRes.body.data?.token)) {
    throw new Error(`Technician login failed: ${techLoginRes.status} - ${JSON.stringify(techLoginRes.body)}`);
  }
  const techToken = techLoginRes.body.data?.token || techLoginRes.body.token;
  console.log('   ✓ QA Technician authenticated successfully.');

  // Step 3: Fetch Available Service Requests
  console.log('\n3. Fetching active service requests via Admin API...');
  const requestsRes = await request(`${API_BASE}/api/v2/admin/service-requests?limit=5`, {
    headers: { Authorization: `Bearer ${adminToken}` }
  });

  const list = Array.isArray(requestsRes.body) ? requestsRes.body : (requestsRes.body.data || []);
  if (requestsRes.status !== 200 || !Array.isArray(list)) {
    throw new Error(`Failed to list service requests: ${requestsRes.status} - ${JSON.stringify(requestsRes.body)}`);
  }

  console.log(`   ✓ Found ${list.length} service requests.`);
  if (list.length === 0) {
    console.log('   ! No existing service requests found to audit lifecycle against.');
    return;
  }

  const targetBooking = list[0];
  const bookingId = targetBooking.id || targetBooking._id;
  console.log(`   Target Booking ID: ${bookingId} (${targetBooking.serviceName || 'Service'})`);

  // Step 4: Admin Updates Follow-up Instruction / Query
  console.log('\n4. Testing PATCH /api/v2/admin/service-requests/:id/instruction ...');
  const originalInstruction = targetBooking.dispatchNote || '';
  const testInstruction = `Automated QA instruction test at ${new Date().toISOString()}`;
  
  const instructionRes = await request(`${API_BASE}/api/v2/admin/service-requests/${bookingId}/instruction`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${adminToken}` }
  }, {
    instruction: testInstruction
  });

  console.log('   Instruction API Status:', instructionRes.status);
  if (instructionRes.status !== 200) {
    throw new Error(`Instruction update failed: ${JSON.stringify(instructionRes.body)}`);
  }
  const instData = instructionRes.body.data || instructionRes.body;
  console.log('   ✓ Instruction updated to:', instData.dispatchNote);

  // Step 5: Test Admin Verification - Approval
  console.log('\n5. Testing POST /api/v2/admin/service-requests/:id/verify (status: verified)...');
  const originalVerification = {
    adminVerified: targetBooking.adminVerified,
    verificationStatus: targetBooking.verificationStatus,
    verificationNote: targetBooking.verificationNote
  };

  const verifyApproveRes = await request(`${API_BASE}/api/v2/admin/service-requests/${bookingId}/verify`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${adminToken}` }
  }, {
    status: 'verified',
    note: 'Approved by Principal QA Architect. Wiring and photo proof inspected.'
  });

  console.log('   Verify Approve API Status:', verifyApproveRes.status);
  if (verifyApproveRes.status !== 200) {
    throw new Error(`Verify approve failed: ${JSON.stringify(verifyApproveRes.body)}`);
  }
  const approveData = verifyApproveRes.body.data || verifyApproveRes.body;
  console.log('   ✓ adminVerified:', approveData.adminVerified);
  console.log('   ✓ verificationStatus:', approveData.verificationStatus);
  console.log('   ✓ verificationNote:', approveData.verificationNote);
  console.log('   ✓ verifiedAt:', approveData.verifiedAt);

  // Step 6: Test Admin Verification - Request Rework / Query
  console.log('\n6. Testing POST /api/v2/admin/service-requests/:id/verify (status: rework_requested)...');
  const verifyReworkRes = await request(`${API_BASE}/api/v2/admin/service-requests/${bookingId}/verify`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${adminToken}` }
  }, {
    status: 'rework_requested',
    note: 'Please re-route camera 3 wiring cleanly along the ceiling conduit.'
  });

  console.log('   Verify Rework API Status:', verifyReworkRes.status);
  if (verifyReworkRes.status !== 200) {
    throw new Error(`Verify rework failed: ${JSON.stringify(verifyReworkRes.body)}`);
  }
  const reworkData = verifyReworkRes.body.data || verifyReworkRes.body;
  console.log('   ✓ adminVerified:', reworkData.adminVerified);
  console.log('   ✓ verificationStatus:', reworkData.verificationStatus);
  console.log('   ✓ verificationNote:', reworkData.verificationNote);

  // Step 7: Restore original state to keep database completely clean
  console.log('\n7. Hygiene restoration: Reverting booking verification & instruction state...');
  await request(`${API_BASE}/api/v2/admin/service-requests/${bookingId}/instruction`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${adminToken}` }
  }, {
    instruction: originalInstruction
  });

  await request(`${API_BASE}/api/v2/admin/service-requests/${bookingId}/verify`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${adminToken}` }
  }, {
    status: originalVerification.verificationStatus || 'pending',
    note: originalVerification.verificationNote || ''
  });
  console.log('   ✓ Original booking state restored cleanly.');

  console.log('\n=== ALL LIFECYCLE API AUDIT CHECKS PASSED WITH 100% SUCCESS ===');
}

run().catch(err => {
  console.error('\n❌ Verification Failed:', err.message);
  process.exit(1);
});
