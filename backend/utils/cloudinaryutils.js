import cloudinary from '../config/cloudinary.js';

// Solo se aceptan imágenes de NUESTRA cuenta de Cloudinary y de las carpetas de la app:
// así una URL manipulada nunca puede hacer borrar otra imagen
export function obtenerPublicId(url) {
  if (typeof url !== 'string' || !url) return null;
  if (!url.startsWith(`https://res.cloudinary.com/${process.env.CLOUDINARY_CLOUD_NAME}/`)) return null;
  const partes = url.split('/upload/')[1];
  if (!partes) return null;
  const sinVersion = partes.replace(/^v\d+\//, '');
  const publicId = sinVersion.replace(/\.[^/.]+$/, '');
  return publicId.startsWith('clubapp/') && !publicId.includes('..') ? publicId : null;
}

export async function eliminarImagen(url) {
  const publicId = obtenerPublicId(url);
  if (!publicId) return null;
  return cloudinary.uploader.destroy(publicId);
}