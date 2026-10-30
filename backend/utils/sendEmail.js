import * as brevo from '@getbrevo/brevo';
import crypto from 'crypto';
import { esc } from './helpers.js';

const LOGO_URL = process.env.LOGO_URL ?? 'https://res.cloudinary.com/xkwp03du/image/upload/v1791131589/logo1.png';
export const CODIGO_MINUTOS = 10;

export const generarCodigo = () => crypto.randomInt(100000, 1000000).toString();

// Plantilla base con la identidad visual de ClubApp
const plantillaBase = (contenido) => `
  <div style="background-color: #0b1120; padding: 40px 20px; font-family: 'Segoe UI', Arial, sans-serif;">
    <div style="max-width: 420px; margin: 0 auto; background-color: #111827; border-radius: 16px; overflow: hidden; border: 1px solid #1f2937;">

      <div style="background: linear-gradient(135deg, #0891b2, #0e7490); padding: 28px; text-align: center;">
        <img src="${LOGO_URL}" alt="ClubApp" width="56" height="56" style="display: block; margin: 0 auto 12px; border-radius: 12px;">
        <h1 style="color: white; margin: 0; font-size: 20px; letter-spacing: 1px;">CLUBAPP</h1>
        <p style="color: #cffafe; margin: 4px 0 0; font-size: 13px;">Tu plataforma deportiva</p>
      </div>

      <div style="padding: 32px 28px; color: #e5e7eb;">
        ${contenido}
      </div>

      <div style="padding: 20px 28px; border-top: 1px solid #1f2937; text-align: center;">
        <p style="color: #6b7280; font-size: 12px; margin: 0;">© ${new Date().getFullYear()} ClubApp · Este es un correo automático, no respondas a este mensaje.</p>
      </div>

    </div>
  </div>
`;

// Las variables se leen al enviar (no al importar), así dotenv ya las cargó
const enviar = async (correoDestino, nombre, subject, contenido) => {
  const { BREVO_API_KEY, BREVO_SENDER_EMAIL, BREVO_SENDER_NAME, EMAIL_FROM_NAME } = process.env;
  if (!BREVO_API_KEY || !BREVO_SENDER_EMAIL) throw new Error('Faltan BREVO_API_KEY o BREVO_SENDER_EMAIL en el .env');

  const api = new brevo.TransactionalEmailsApi();
  api.setApiKey(brevo.TransactionalEmailsApiApiKeys.apiKey, BREVO_API_KEY);

  const email = new brevo.SendSmtpEmail();
  email.subject = subject;
  email.htmlContent = plantillaBase(contenido);
  email.sender = { name: BREVO_SENDER_NAME ?? EMAIL_FROM_NAME ?? 'ClubApp', email: BREVO_SENDER_EMAIL };
  email.to = [{ email: correoDestino, name: nombre }];

  try {
    await api.sendTransacEmail(email);
  } catch (e) {
    console.error('Error Brevo:', e.response?.statusCode, e.response?.body ?? e.message);
    throw e;
  }
};

export const enviarCorreoCodigo = (correoDestino, nombre, codigo, motivo = 'recuperar tu contraseña') => enviar(
  correoDestino, nombre, '🔐 Tu código de verificación - ClubApp',
  `
    <h2 style="margin: 0 0 8px; font-size: 18px; color: white;">Hola ${esc(nombre)} 👋</h2>
    <p style="color: #9ca3af; font-size: 14px; margin: 0 0 24px;">Recibimos una solicitud para ${motivo}. Usa este código para continuar:</p>

    <div style="background-color: #0b1120; border: 1px solid #1f2937; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 20px;">
      <span style="font-size: 34px; letter-spacing: 12px; font-weight: bold; color: #22d3ee;">${codigo}</span>
    </div>

    <div style="background-color: rgba(34, 211, 238, 0.08); border-radius: 8px; padding: 12px 16px;">
      <p style="color: #67e8f9; font-size: 13px; margin: 0;">⏱️ Este código expira en <strong>${CODIGO_MINUTOS} minutos</strong> por tu seguridad.</p>
    </div>

    <p style="color: #6b7280; font-size: 12px; margin-top: 24px;">Si tú no solicitaste este código, puedes ignorar este correo con tranquilidad.</p>
  `
);

export const enviarCorreoConfirmacionCambio = (correoDestino, nombre) => enviar(
  correoDestino, nombre, '✅ Tu contraseña fue actualizada - ClubApp',
  `
    <div style="text-align: center; margin-bottom: 20px;">
      <div style="width: 56px; height: 56px; background: rgba(34, 197, 94, 0.15); border-radius: 50%; margin: 0 auto 16px; display: flex; align-items: center; justify-content: center; font-size: 28px;">✅</div>
      <h2 style="margin: 0 0 8px; font-size: 18px; color: white;">¡Contraseña actualizada!</h2>
      <p style="color: #9ca3af; font-size: 14px; margin: 0;">Hola ${esc(nombre)}, tu contraseña se cambió exitosamente.</p>
    </div>

    <div style="background-color: rgba(239, 68, 68, 0.08); border-left: 3px solid #ef4444; border-radius: 8px; padding: 14px 16px; margin-top: 20px;">
      <p style="color: #fca5a5; font-size: 13px; margin: 0;">⚠️ Si no realizaste este cambio, contacta al soporte de inmediato.</p>
    </div>
  `
);