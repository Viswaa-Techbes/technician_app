const CctvCategory = require('../models/CctvCategory');
const CctvSubcategory = require('../models/CctvSubcategory');
const CctvCameraType = require('../models/CctvCameraType');
const CctvAddon = require('../models/CctvAddon');
const CctvPricingConfig = require('../models/CctvPricingConfig');

function roundAmount(value) {
  return Math.max(Math.round((Number(value) || 0) * 100) / 100, 0);
}

function adjustmentAmount(adjustment, subtotal) {
  if (!adjustment || adjustment.status !== 'active') return 0;
  if (adjustment.type === 'percentage') return roundAmount((subtotal * (Number(adjustment.value) || 0)) / 100);
  if (adjustment.type === 'flat') return roundAmount(adjustment.value);
  return 0;
}

async function getActivePricingConfig() {
  let config = await CctvPricingConfig.findOne({ status: 'active' }).sort({ updatedAt: -1 }).lean();
  if (!config) {
    config = await CctvPricingConfig.create({
      baseCharge: 499,
      indoorCharge: 0,
      outdoorCharge: 350,
      wirePricePerMeter: 35,
      tax: { label: 'GST', percentage: 18, status: 'active' },
    });
    config = config.toObject();
  }
  return config;
}

async function calculateCctvPrice(input = {}) {
  const [config, category, subcategory, cameraType] = await Promise.all([
    getActivePricingConfig(),
    input.categoryId ? CctvCategory.findById(input.categoryId).lean() : null,
    input.subcategoryId ? CctvSubcategory.findById(input.subcategoryId).lean() : null,
    input.cameraTypeId ? CctvCameraType.findById(input.cameraTypeId).lean() : null,
  ]);

  if (!cameraType || cameraType.status !== 'active') {
    const error = new Error('Active camera type is required');
    error.statusCode = 400;
    throw error;
  }

  const cameraCount = Math.max(Number(input.cameraCount) || 1, 1);
  const wireLength = Math.max(Number(input.wireLength) || 0, 0);
  const installationArea = input.installationArea === 'outdoor' ? 'outdoor' : 'indoor';
  const addonIds = Array.isArray(input.addonIds) ? input.addonIds : [];
  const addons = addonIds.length
    ? await CctvAddon.find({ _id: { $in: addonIds }, status: 'active' }).lean()
    : [];

  const baseCharge = roundAmount(config.baseCharge);
  const cameraUnitPrice = roundAmount(cameraType.installationPrice);
  const cameraTotal = roundAmount(cameraCount * cameraUnitPrice);
  const indoorCharge = roundAmount(config.indoorCharge);
  const outdoorCharge = roundAmount(config.outdoorCharge);
  const areaCharge = installationArea === 'outdoor' ? outdoorCharge : indoorCharge;
  const wirePricePerMeter = roundAmount(config.wirePricePerMeter);
  const wireTotal = roundAmount(wireLength * wirePricePerMeter);
  const selectedAddons = addons.map((addon) => ({
    id: addon._id,
    name: addon.name,
    slug: addon.slug,
    price: roundAmount(addon.price),
    quantity: 1,
    total: roundAmount(addon.price),
  }));
  const addonsTotal = roundAmount(selectedAddons.reduce((sum, addon) => sum + addon.total, 0));
  const subtotal = roundAmount(baseCharge + cameraTotal + areaCharge + wireTotal + addonsTotal);
  const discountTotal = Math.min(adjustmentAmount(config.discount, subtotal), subtotal);
  const afterDiscount = roundAmount(subtotal - discountTotal);
  const couponTotal = input.couponCode && config.coupon?.code === String(input.couponCode).toUpperCase()
    ? Math.min(adjustmentAmount(config.coupon, afterDiscount), afterDiscount)
    : 0;
  const afterCoupon = roundAmount(afterDiscount - couponTotal);
  const offerAdjustment = config.offer?.status === 'active' && Number(config.offer.offerPrice) > 0 && Number(config.offer.offerPrice) < afterCoupon
    ? roundAmount(afterCoupon - Number(config.offer.offerPrice))
    : 0;
  const taxableAmount = roundAmount(afterCoupon - offerAdjustment);
  const taxTotal = config.tax?.status === 'active'
    ? roundAmount((taxableAmount * (Number(config.tax.percentage) || 0)) / 100)
    : 0;
  const grandTotal = roundAmount(taxableAmount + taxTotal);

  return {
    category: category ? { id: category._id, name: category.name, slug: category.slug } : undefined,
    subcategory: subcategory ? { id: subcategory._id, name: subcategory.name, slug: subcategory.slug } : undefined,
    cameraType: {
      id: cameraType._id,
      name: cameraType.name,
      slug: cameraType.slug,
      unitPrice: cameraUnitPrice,
    },
    cameraCount,
    installationArea,
    wireLength,
    addons: selectedAddons,
    priceBreakdown: {
      baseCharge,
      cameraUnitPrice,
      cameraCount,
      cameraTotal,
      indoorCharge,
      outdoorCharge,
      areaCharge,
      wireLength,
      wirePricePerMeter,
      wireTotal,
      addonsTotal,
      discountTotal,
      couponTotal,
      offerAdjustment,
      taxableAmount,
      taxTotal,
      grandTotal,
    },
  };
}

module.exports = {
  calculateCctvPrice,
  getActivePricingConfig,
};
