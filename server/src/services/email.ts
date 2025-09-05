import nodemailer from 'nodemailer';
import crypto from 'crypto';
import db from '../database/sqlite-db.js';

function createTransporter() {
    return nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.ethereal.email',
        port: parseInt(process.env.SMTP_PORT || '587'),
        secure: false,
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        },
        tls: {
            rejectUnauthorized: false
        }
    });
}

export async function sendMagicLink(email: string): Promise<void> {
    console.log('🔍 Debug SMTP Config:');
    console.log('  SMTP_HOST:', process.env.SMTP_HOST);
    console.log('  SMTP_USER:', process.env.SMTP_USER);
    console.log('  SMTP_PASS:', process.env.SMTP_PASS ? '***' : 'undefined');
    
    const transporter = createTransporter();
    
    // Generate secure token
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    
    // Store token in database
    await db.query(
        'INSERT INTO login_tokens (token, email, expires_at) VALUES ($1, $2, $3)',
        [token, email, expiresAt]
    );
    
    // Create magic link
    const magicLink = `${process.env.APP_BASE_URL}/auth/email/callback?token=${token}`;
    
    // Send email with magic link
    const mailOptions = {
        from: process.env.FROM_EMAIL || 'noreply@printmyride.app',
        to: email,
        subject: 'Sign in to PrintMyRide',
        html: `
            <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
                <h1 style="color: #333; text-align: center;">Sign in to PrintMyRide</h1>
                <p>Click the button below to sign in to your PrintMyRide account:</p>
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${magicLink}" style="background: #007AFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
                        Sign In
                    </a>
                </div>
                <p style="color: #666; font-size: 14px;">
                    This link will expire in 15 minutes. If you didn't request this, you can safely ignore this email.
                </p>
                <p style="color: #666; font-size: 14px;">
                    Or copy and paste this URL: <br>
                    <a href="${magicLink}">${magicLink}</a>
                </p>
            </div>
        `
    };
    
    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`✅ Magic link sent to ${email}`);
        console.log(`📧 Preview: https://ethereal.email/message/${info.messageId}`);
    } catch (error) {
        console.error('❌ Failed to send magic link:', error);
        throw new Error('Failed to send login email');
    }
}

export async function validateToken(token: string): Promise<string | null> {
    const result = await db.query(
        'SELECT email, expires_at, used FROM login_tokens WHERE token = $1',
        [token]
    );
    
    if (!result.rows[0]) {
        return null; // Token not found
    }
    
    const { email, expires_at, used } = result.rows[0];
    
    if (used) {
        return null; // Token already used
    }
    
    if (new Date() > new Date(expires_at)) {
        return null; // Token expired
    }
    
    // Mark token as used
    await db.query(
        'UPDATE login_tokens SET used = true WHERE token = $1',
        [token]
    );
    
    return email;
}