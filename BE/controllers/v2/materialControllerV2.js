const Material = require('../../models/Material');
const { Types } = require('mongoose');

function listMaterials(req, res, next) {
  const query = req.user?.role === 'admin' ? {} : { status: 'active' };
  Material.find(query).sort({ sortOrder: 1, name: 1 }).lean()
    .then((data) => res.json({ success: true, data }))
    .catch(next);
}

async function getMaterial(req, res, next) {
  try {
    const m = await Material.findById(req.params.id).lean();
    if (!m) return res.status(404).json({ success: false, message: 'Material not found' });
    res.json({ success: true, data: m });
  } catch (err) { next(err); }
}

function crud() {
  return {
    async create(req, res, next) {
      try {
        const data = await Material.create(req.body);
        res.status(201).json({ success: true, data });
      } catch (err) { next(err); }
    },
    async update(req, res, next) {
      try {
        const data = await Material.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
        if (!data) return res.status(404).json({ success: false, message: 'Material not found' });
        res.json({ success: true, data });
      } catch (err) { next(err); }
    },
    async remove(req, res, next) {
      try {
        const data = await Material.findByIdAndUpdate(req.params.id, { status: 'inactive' }, { new: true });
        if (!data) return res.status(404).json({ success: false, message: 'Material not found' });
        res.json({ success: true, data });
      } catch (err) { next(err); }
    },
  };
}

module.exports = {
  listMaterials,
  getMaterial,
  admin: crud(),
};
