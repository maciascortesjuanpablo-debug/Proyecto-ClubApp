import multer from 'multer';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import cloudinary from '../config/cloudinary.js';

export function crearUploader(folder, size = [500, 500]) {
  const storage = new CloudinaryStorage({
    cloudinary,
    params: {
      folder,
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
      transformation: [{ width: size[0], height: size[1], crop: 'limit' }],
    },
  });

  return multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
      if (!file.mimetype.startsWith('image/')) {
        return cb(new Error('Solo se permiten archivos de imagen'), false);
      }
      cb(null, true);
    },
  });
}

export const uploadFotoPerfil = crearUploader('clubapp/perfiles', [500, 500]);
export const uploadLogoEquipo = crearUploader('clubapp/equipos', [800, 800]);
export const uploadImagenTorneo = crearUploader('clubapp/torneos', [1200, 630]);