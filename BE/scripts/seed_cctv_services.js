require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/db');
const CctvCategory = require('../models/CctvCategory');
const CctvSubcategory = require('../models/CctvSubcategory');
const CctvCameraType = require('../models/CctvCameraType');
const CctvAddon = require('../models/CctvAddon');
const CctvPricingConfig = require('../models/CctvPricingConfig');

function slugify(value) {
  return String(value).trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

const names = [
  'Home CCTV Installation',
  'Office CCTV Installation',
  'Apartment CCTV Installation',
  'Shop CCTV Installation',
  'Warehouse CCTV Installation',
  'Factory CCTV Installation',
  'Indoor Camera Installation',
  'Outdoor Camera Installation',
  'Wireless CCTV Installation',
  'IP Camera Installation',
  'Dome Camera Installation',
  'Bullet Camera Installation',
  'PTZ Camera Installation',
  'DVR Installation',
  'NVR Installation',
  'CCTV Repair',
  'CCTV Maintenance',
  'AMC Service',
  'Mobile Monitoring Setup',
  'CCTV Cabling',
];

const cameraTypes = [
  ['Dome Camera', 650, 'Compact ceiling camera for indoor rooms, shops, and offices.'],
  ['Bullet Camera', 750, 'Directional camera suited for gates, parking, and perimeters.'],
  ['PTZ Camera', 1800, 'Pan-tilt-zoom camera for larger spaces and active monitoring.'],
  ['IP Camera', 900, 'Network camera for NVR systems and high-quality remote viewing.'],
  ['Wireless Camera', 850, 'Wi-Fi camera for locations where cabling is limited.'],
];

const addons = [
  ['PVC Casing', 180],
  ['Junction Box', 220],
  ['Power Supply', 450],
  ['SMPS', 650],
  ['PoE Switch', 2200],
  ['Network Rack', 3200],
  ['Hard Disk', 3800],
  ['Connector Set', 150],
];

async function upsertBySlug(Model, payload) {
  return Model.findOneAndUpdate(
    { slug: payload.slug },
    { $set: payload },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
}

async function run() {
  await connectDB();

  const category = await upsertBySlug(CctvCategory, {
    name: 'CCTV Installation',
    slug: 'cctv-installation',
    description: 'Professional CCTV installation, repair, monitoring, cabling, and AMC services.',
    status: 'active',
    sortOrder: 1,
  });

  await Promise.all(cameraTypes.map(([name, price, description], index) => upsertBySlug(CctvCameraType, {
    name,
    slug: slugify(name),
    description,
    installationPrice: price,
    status: 'active',
    sortOrder: index + 1,
  })));

  await Promise.all(addons.map(([name, price], index) => upsertBySlug(CctvAddon, {
    name,
    slug: slugify(name),
    price,
    status: 'active',
    sortOrder: index + 1,
  })));

  const commonIncluded = [
    'Site inspection and camera placement guidance',
    'Camera installation and alignment',
    'Basic recorder or mobile viewing setup',
    'Final testing and customer handover',
  ];
  const commonExcluded = [
    'Camera hardware unless separately purchased',
    'Civil work, drilling through reinforced structures, and concealed conduit work',
    'Internet plan, router replacement, or electrical rewiring',
  ];

  await Promise.all(names.map((name, index) => upsertBySlug(CctvSubcategory, {
    categoryId: category._id,
    name,
    slug: slugify(name),
    shortDescription: `${name} with transparent pricing and trained technician support.`,
    overview: `${name} covers planning, installation, cabling checks, recorder or app configuration, and handover for reliable surveillance coverage.`,
    suitableFor: ['Homes', 'Offices', 'Retail shops', 'Apartments', 'Warehouses'],
    includedServices: commonIncluded,
    excludedServices: commonExcluded,
    cameraTypes: ['Dome Camera', 'Bullet Camera', 'PTZ Camera', 'IP Camera', 'Wireless Camera'],
    cableTypes: ['Cat6 cable', 'Coaxial cable', 'Power cable', 'PVC casing'],
    installationProcess: [
      'Confirm site type, camera count, and coverage areas',
      'Mark camera positions and cable route',
      'Install cameras, accessories, and required cabling',
      'Configure DVR/NVR/mobile viewing where applicable',
      'Test recording, viewing angle, and customer handover',
    ],
    installationTime: index < 6 ? '2-6 hours depending on camera count' : '1-3 hours depending on scope',
    warranty: '30-day workmanship warranty. Product warranty depends on device brand and invoice.',
    faqs: [
      { question: 'Can I choose indoor or outdoor installation?', answer: 'Yes. Outdoor installation may include additional labor and weatherproofing charges.' },
      { question: 'Is wire charged separately?', answer: 'Yes. Wire is calculated by required meter length using the admin-configured per-meter rate.' },
      { question: 'Can I add accessories?', answer: 'Yes. Add-ons such as PVC casing, junction box, PoE switch, hard disk, and connector sets can be selected before checkout.' },
    ],
    pricingStartsFrom: 499,
    image: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=1200&h=900&fit=crop',
    status: 'active',
    sortOrder: index + 1,
  })));

  await CctvPricingConfig.findOneAndUpdate(
    { name: 'Default CCTV Pricing' },
    {
      $set: {
        name: 'Default CCTV Pricing',
        baseCharge: 499,
        indoorCharge: 0,
        outdoorCharge: 350,
        wirePricePerMeter: 35,
        discount: { type: 'none', value: 0, status: 'inactive' },
        coupon: { code: '', type: 'none', value: 0, status: 'inactive' },
        offer: { offerPrice: 0, status: 'inactive' },
        tax: { label: 'GST', percentage: 18, status: 'active' },
        status: 'active',
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  console.log('CCTV services seeded successfully.');
  await mongoose.connection.close();
}

run().catch(async (err) => {
  console.error(err);
  await mongoose.connection.close().catch(() => {});
  process.exit(1);
});
