const mongoose = require('mongoose');

const cctvCategorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, trim: true, lowercase: true },
    description: { type: String, default: '', trim: true },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

cctvCategorySchema.index({ status: 1, sortOrder: 1 });

module.exports = mongoose.model('CctvCategory', cctvCategorySchema);
