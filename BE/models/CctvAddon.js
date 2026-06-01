const mongoose = require('mongoose');

const cctvAddonSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, trim: true, lowercase: true },
    price: { type: Number, required: true, min: 0 },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

cctvAddonSchema.index({ status: 1, sortOrder: 1 });

module.exports = mongoose.model('CctvAddon', cctvAddonSchema);
