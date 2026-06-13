const cloudinary = require('cloudinary').v2;
const dotenv = require('dotenv');

dotenv.config();

const requiredEnv = [
  'CLOUDINARY_CLOUD_NAME',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET',
];

const hasCloudinaryConfig = requiredEnv.every((key) => Boolean(process.env[key]));

if (hasCloudinaryConfig) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
}

const uploadToCloudinary = async (fileBuffer, fileName) => {
  if (!hasCloudinaryConfig) {
    throw new Error(`Missing Cloudinary environment variables: ${requiredEnv.join(', ')}`);
  }

  const safeName = fileName
    .replace(/\.[^/.]+$/, '')
    .replace(/[^a-zA-Z0-9_-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: 'technician_app/work_proofs',
        public_id: `${Date.now()}-${safeName || 'work-proof'}`,
        resource_type: 'auto',
        fetch_format: 'webp',
        format: 'webp',
        transformation: [
          { width: 1280, crop: 'limit' },
          { quality: 75 }
        ]
      },
      (error, result) => {
        if (error) return reject(error);
        resolve(result);
      }
    );
    uploadStream.end(fileBuffer);
  });
};

module.exports = {
  cloudinary,
  uploadToCloudinary,
};
