import cloudinary from '../config/cloudinary.js';

export function obtenerPublicId(url) {
  if (!url) return null;
  const partes = url.split('/upload/')[1];
  if (!partes) return null;
  const sinVersion = partes.replace(/^v\d+\//, '');
  return sinVersion.replace(/\.[^/.]+$/, '');
}

export async function eliminarImagen(url) {
  const publicId = obtenerPublicId(url);
  if (!publicId) return null;
  return cloudinary.uploader.destroy(publicId);
}