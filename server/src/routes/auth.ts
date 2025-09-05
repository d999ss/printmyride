import { Router } from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import db from '../database/sqlite-db.js';
import { sendMagicLink, validateToken } from '../services/email.js';
import { requireSession, getAthleteId } from '../middleware/auth.js';

const router = Router();

// 1. Passwordless login - Start
router.post('/email/start', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email || !email.includes('@')) {
            return res.status(400).json({ error: 'Valid email required' });
        }
        
        // Create user if doesn't exist
        await db.query(
            'INSERT INTO users (email) VALUES ($1) ON CONFLICT (email) DO NOTHING',
            [email.toLowerCase()]
        );
        
        // Send magic link
        await sendMagicLink(email.toLowerCase());
        
        res.json({ message: 'Login link sent to your email' });
    } catch (error) {
        console.error('❌ Email start error:', error);
        res.status(500).json({ error: 'Failed to send login email' });
    }
});

// 2. Passwordless login - Callback
router.get('/email/callback', async (req, res) => {
    try {
        const { token } = req.query;
        
        if (!token || typeof token !== 'string') {
            return res.redirect(`${process.env.APP_BASE_URL}?error=invalid_token`);
        }
        
        const email = await validateToken(token);
        if (!email) {
            return res.redirect(`${process.env.APP_BASE_URL}?error=token_expired`);
        }
        
        // Get user
        const userResult = await db.query('SELECT id FROM users WHERE email = $1', [email]);
        if (!userResult.rows[0]) {
            return res.redirect(`${process.env.APP_BASE_URL}?error=user_not_found`);
        }
        
        const user_id = userResult.rows[0].id;
        
        // Issue JWT session
        const sessionToken = jwt.sign({ user_id }, process.env.JWT_SECRET!, { expiresIn: '30d' });
        
        // Set HTTP-only cookie
        res.cookie('pmr_session', sessionToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 30 * 24 * 60 * 60 * 1000 // 30 days
        });
        
        res.redirect(`${process.env.APP_BASE_URL}/app`);
    } catch (error) {
        console.error('❌ Email callback error:', error);
        res.redirect(`${process.env.APP_BASE_URL}?error=login_failed`);
    }
});

// 3. Strava OAuth - Start
router.get('/strava', requireSession, async (req, res) => {
    try {
        // Generate CSRF state
        const state = crypto.randomBytes(32).toString('hex');
        res.cookie('strava_state', state, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 10 * 60 * 1000 // 10 minutes
        });
        
        const params = new URLSearchParams({
            client_id: process.env.STRAVA_CLIENT_ID!,
            redirect_uri: `${process.env.SERVER_BASE_URL}/auth/strava/callback`,
            response_type: 'code',
            approval_prompt: 'auto',
            scope: 'read,activity:read,activity:read_all',
            state
        });
        
        const authUrl = `https://www.strava.com/oauth/authorize?${params}`;
        res.redirect(authUrl);
    } catch (error) {
        console.error('❌ Strava auth start error:', error);
        res.status(500).json({ error: 'Failed to start Strava authentication' });
    }
});

// 4. Strava OAuth - Callback
router.get('/strava/callback', requireSession, async (req, res) => {
    try {
        const { code, state } = req.query;
        const storedState = req.cookies.strava_state;
        
        if (!code || !state || state !== storedState) {
            return res.redirect(`${process.env.APP_BASE_URL}/app?error=strava_auth_failed`);
        }
        
        // Clear state cookie
        res.clearCookie('strava_state');
        
        // Exchange code for tokens
        const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                client_id: process.env.STRAVA_CLIENT_ID,
                client_secret: process.env.STRAVA_CLIENT_SECRET,
                code,
                grant_type: 'authorization_code'
            })
        });
        
        if (!tokenResponse.ok) {
            const error = await tokenResponse.text();
            console.error('❌ Strava token exchange failed:', error);
            return res.redirect(`${process.env.APP_BASE_URL}/app?error=token_exchange_failed`);
        }
        
        const tokens = await tokenResponse.json();
        const athleteId = tokens.athlete.id;
        
        // Store tokens
        await db.query(
            `INSERT INTO strava_tokens (athlete_id, access_token, refresh_token, expires_at, scope) 
             VALUES ($1, $2, $3, $4, $5) 
             ON CONFLICT (athlete_id) DO UPDATE SET 
                access_token = $2, refresh_token = $3, expires_at = $4, scope = $5, updated_at = NOW()`,
            [athleteId, tokens.access_token, tokens.refresh_token, tokens.expires_at, tokens.scope]
        );
        
        // Link user to athlete
        await db.query(
            `INSERT INTO user_identities (user_id, provider, provider_user_id) 
             VALUES ($1, 'strava', $2) 
             ON CONFLICT (provider, provider_user_id) DO UPDATE SET user_id = $1`,
            [req.user_id, athleteId]
        );
        
        console.log(`✅ User ${req.user_id} connected to Strava athlete ${athleteId}`);
        res.redirect(`${process.env.APP_BASE_URL}/app?connected=strava`);
    } catch (error) {
        console.error('❌ Strava callback error:', error);
        res.redirect(`${process.env.APP_BASE_URL}/app?error=strava_connection_failed`);
    }
});

// 5. Check authentication status
router.get('/status', async (req, res) => {
    const token = req.cookies.pmr_session;
    
    if (!token) {
        return res.json({ authenticated: false });
    }
    
    try {
        const payload = jwt.verify(token, process.env.JWT_SECRET!) as { user_id: number };
        const athleteId = await getAthleteId(payload.user_id);
        
        res.json({
            authenticated: true,
            user_id: payload.user_id,
            strava_connected: !!athleteId,
            athlete_id: athleteId
        });
    } catch (error) {
        res.json({ authenticated: false });
    }
});

// 6. Logout
router.post('/logout', (req, res) => {
    res.clearCookie('pmr_session');
    res.json({ message: 'Logged out successfully' });
});

export default router;