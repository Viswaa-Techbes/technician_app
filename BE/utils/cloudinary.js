const cloudinary = require('cloudinary').v2;
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

dotenv.config();

const requiredEnv = [
  'CLOUDINARY_CLOUD_NAME',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET',
];

const isPlaceholder = (val) => !val || /^(x+|your_|demo|test|placeholder)/i.test(String(val).trim());
const hasCloudinaryConfig = requiredEnv.every((key) => !isPlaceholder(process.env[key]));

if (hasCloudinaryConfig) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
}

function saveToLocalUploads(fileBuffer, fileName) {
  const ext = path.extname(fileName || '').toLowerCase() || '.jpg';
  const safeBase = (fileName || 'upload')
    .replace(/\.[^/.]+$/, '')
    .replace(/[^a-zA-Z0-9_-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '') || 'file';
  const finalName = `${Date.now()}-${safeBase}${ext}`;
  const uploadsDir = path.join(__dirname, '../uploads/work_proofs');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }
  const targetPath = path.join(uploadsDir, finalName);
  fs.writeFileSync(targetPath, fileBuffer);
  const publicBase = (process.env.API_PUBLIC_URL || 'https://api.techbes.co.in').replace(/\/+$/, '');
  return {
    secure_url: `${publicBase}/uploads/work_proofs/${finalName}`,
    public_id: `local/${finalName}`,
    bytes: fileBuffer.length,
    format: ext.replace('.', ''),
  };
}

const uploadToCloudinary = async (fileBuffer, fileName, options = {}) => {
  if (!hasCloudinaryConfig) {
    return saveToLocalUploads(fileBuffer, fileName);
  }

  const safeName = fileName
    .replace(/\.[^/.]+$/, '')
    .replace(/[^a-zA-Z0-9_-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

  const folder = options.folder || 'technician_app/work_proofs';
  const public_id = options.publicId || `${Date.now()}-${safeName || 'work-proof'}`;
  const resource_type = options.resource_type || 'auto';

  const uploadOptions = {
    folder,
    public_id,
    resource_type,
  };

  if (resource_type !== 'raw' && !options.isRaw) {
    uploadOptions.fetch_format = 'webp';
    uploadOptions.format = 'webp';
    uploadOptions.transformation = [
      { width: 1280, crop: 'limit' },
      { quality: 75 }
    ];
  }

  try {
    return await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        uploadOptions,
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        }
      );
      uploadStream.end(fileBuffer);
    });
  } catch (err) {
    console.warn('[Upload] Cloudinary failed, falling back to local HTTPS /uploads:', err.message);
    return saveToLocalUploads(fileBuffer, fileName);
  }
};

module.exports = {
  cloudinary,
  uploadToCloudinary,
};
