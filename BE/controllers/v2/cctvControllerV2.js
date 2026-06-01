const CctvCategory = require('../../models/CctvCategory');
const CctvSubcategory = require('../../models/CctvSubcategory');
const CctvCameraType = require('../../models/CctvCameraType');
const CctvAddon = require('../../models/CctvAddon');
const CctvProduct = require('../../models/CctvProduct');
const CctvPricingConfig = require('../../models/CctvPricingConfig');
const { calculateCctvPrice, getActivePricingConfig } = require('../../services/cctvPricingService');

function slugify(value = '') {
  return String(value).trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function withSlug(body) {
  return { ...body, slug: body.slug ? slugify(body.slug) : slugify(body.name) };
}

async function listCategories(req, res, next) {
  try {
    const query = req.user?.role === 'admin' ? {} : { status: 'active' };
    const data = await CctvCategory.find(query).sort({ sortOrder: 1, name: 1 }).lean();
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

async function listSubcategories(req, res, next) {
  try {
    const query = req.user?.role === 'admin' ? {} : { status: 'active' };
    if (req.query.categoryId) query.categoryId = req.query.categoryId;
    const data = await CctvSubcategory.find(query)
      .populate('categoryId', 'name slug')
      .populate('supportedProducts')
      .populate('supportedAddons')
      .populate('supportedSpareParts')
      .sort({ sortOrder: 1, name: 1 })
      .lean();
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

async function getSubcategoryBySlug(req, res, next) {
  try {
    const item = await CctvSubcategory.findOne({ slug: req.params.slug, status: 'active' })
      .populate('categoryId', 'name slug')
      .populate('supportedProducts')
      .populate('supportedAddons')
      .populate('supportedSpareParts')
      .lean();
    if (!item) return res.status(404).json({ success: false, message: 'CCTV service not found' });
    res.json({ success: true, data: item });
  } catch (err) { next(err); }
}

async function listCameraTypes(req, res, next) {
  try {
    const query = req.user?.role === 'admin' ? {} : { status: 'active' };
    const data = await CctvCameraType.find(query).sort({ sortOrder: 1, name: 1 }).lean();
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

async function listAddons(req, res, next) {
  try {
    const query = req.user?.role === 'admin' ? {} : { status: 'active' };
    const data = await CctvAddon.find(query).sort({ sortOrder: 1, name: 1 }).lean();
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

async function listProducts(req, res, next) {
  try {
    const query = req.user?.role === 'admin' ? {} : { status: 'active' };
    const data = await CctvProduct.find(query).sort({ sortOrder: 1, name: 1 }).lean();
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

async function getPricingConfig(req, res, next) {
  try {
    const data = await getActivePricingConfig();
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

async function calculatePrice(req, res, next) {
  try {
    const data = await calculateCctvPrice(req.body);
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

function crud(Model) {
  return {
    async create(req, res, next) {
      try {
        const data = await Model.create(withSlug(req.body));
        res.status(201).json({ success: true, data });
      } catch (err) { next(err); }
    },
    async update(req, res, next) {
      try {
        const body = req.body.name || req.body.slug ? withSlug(req.body) : req.body;
        const data = await Model.findByIdAndUpdate(req.params.id, body, { new: true, runValidators: true });
        if (!data) return res.status(404).json({ success: false, message: 'Item not found' });
        res.json({ success: true, data });
      } catch (err) { next(err); }
    },
    async remove(req, res, next) {
      try {
        const data = await Model.findByIdAndUpdate(req.params.id, { status: 'inactive' }, { new: true });
        if (!data) return res.status(404).json({ success: false, message: 'Item not found' });
        res.json({ success: true, data });
      } catch (err) { next(err); }
    },
  };
}

async function upsertPricingConfig(req, res, next) {
  try {
    const existing = await CctvPricingConfig.findOne().sort({ updatedAt: -1 });
    const data = existing
      ? await CctvPricingConfig.findByIdAndUpdate(existing._id, req.body, { new: true, runValidators: true })
      : await CctvPricingConfig.create(req.body);
    res.json({ success: true, data });
  } catch (err) { next(err); }
}

module.exports = {
  listCategories,
  listSubcategories,
  getSubcategoryBySlug,
  listCameraTypes,
  listAddons,
  getPricingConfig,
  calculatePrice,
  categoryAdmin: crud(CctvCategory),
  subcategoryAdmin: crud(CctvSubcategory),
  cameraTypeAdmin: crud(CctvCameraType),
  addonAdmin: crud(CctvAddon),
  productAdmin: crud(CctvProduct),
  upsertPricingConfig,
};
