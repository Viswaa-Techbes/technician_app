const mongoose = require('mongoose');

const faqSchema = new mongoose.Schema(
  {
    question: { type: String, required: true, trim: true },
    answer: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const cctvSubcategorySchema = new mongoose.Schema(
  {
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'CctvCategory', required: true },
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, trim: true, lowercase: true },
    shortDescription: { type: String, default: '', trim: true },
    overview: { type: String, default: '', trim: true },
    suitableFor: { type: [String], default: [] },
    includedServices: { type: [String], default: [] },
    excludedServices: { type: [String], default: [] },
    cameraTypes: { type: [String], default: [] },
    cableTypes: { type: [String], default: [] },
    installationProcess: { type: [String], default: [] },
    installationTime: { type: String, default: '', trim: true },
    warranty: { type: String, default: '', trim: true },
    faqs: { type: [faqSchema], default: [] },
    pricingStartsFrom: { type: Number, default: 0, min: 0 },
    image: { type: String, default: '', trim: true },
    supportedProducts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CctvProduct' }],
    supportedAddons: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CctvAddon' }],
    supportedSpareParts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CctvProduct' }],
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

cctvSubcategorySchema.index({ categoryId: 1, status: 1, sortOrder: 1 });

module.exports = mongoose.model('CctvSubcategory', cctvSubcategorySchema);
